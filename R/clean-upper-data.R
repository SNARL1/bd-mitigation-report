# Data checks and fixes

# Load dependencies
source('R/load-deps.R')

# Read in captures data from rds file
captures1 <- read_rds("./data/raw/captures_upper_uncleaned.rds")

# Check for records where pit_tag_ref is NULL
assert_that(noNA(captures1$pit_tag_ref))

# Check for records containing pit tags shorter than 15 characters
captures1 %>% filter(nchar(pit_tag_ref) != 15)

# Check for records containing pit tags that end with ".1" (known to be potentially incorrect) 
captures1 %>% filter(grepl("*\\.1", pit_tag_ref))

# Check records where capture_animal_state is NULL
assert_that(noNA(captures1$capture_animal_state)) 

# Check for records where capture_animal_state == "dead"
assert_that(!any(captures1$capture_animal_state == 'dead'))

# Check for records of subadult frogs
assert_that(!any(captures1$length < 40))

# Check for duplicate capture records on each date
captures1 %>% group_by(basin_name, visit_date, pit_tag_ref) %>% 
  filter(n() > 1)

# Prepare final captures file
captures2 <- captures1 %>%
  mutate(survey_date = visit_date, pit_tag_id = pit_tag_ref) %>%
  select(basin_name, site_id, survey_date, pit_tag_id) %>%
  arrange(survey_date, pit_tag_id)

# Save captures file as csv for use in mrmr
captures2 %>% write.csv(file = "./data/clean/captures_upper.csv", row.names = FALSE)


# Check translocations file to find problem records (read comments too)

# Read in translocations data from rds file
translocations1 <- read_rds("./data/raw/translocations_upper_uncleaned.rds")

# Check for records where pit_tag_ref is NULL
assert_that(noNA(translocations1$pit_tag_ref))

# Check for records containing pit tags shorter than 15 characters
translocations1 %>% filter(nchar(pit_tag_ref) != 15)

# Check for records containing pit tags that end with ".1" (known to be potentially incorrect) 
translocations1 %>% filter(grepl("*\\.1", pit_tag_ref))

# Check whether tags of all tag_new = FALSE frogs captured at recipient site match those of translocated frogs - only works for sites w/o recruitment
tagcheck <- captures1 %>%
  filter(tag_new == FALSE) %>%
  select(site_id, pit_tag_ref) %>% 
  distinct(pit_tag_ref, .keep_all = TRUE) %>%
  left_join(translocations1, by = c("pit_tag_ref")) %>%
  filter(is.na(release_location))

# Create final translocations file
translocations2 <- translocations1 %>%
  mutate(site_id = release_location, pit_tag_id = pit_tag_ref) %>% 
  select(site_id, release_date, pit_tag_id, type) %>% 
  arrange(release_date, pit_tag_id)

# Save translocations file as csv for use in mrmr
translocations2 %>% write.csv(file = "./data/clean/translocations_upper.csv", row.names = FALSE)

# Clean surveys file
# Check surveys file created earlier for aberrant surveys and visual surveys for which no CMR survey exists (for inclusion in file)

# Read in surveys data from rds file
surveys1 <- read_rds("./data/raw/surveys_upper_uncleaned.rds")

# Review surveys data to find abberant surveys

# Select relevant columns and rows
surveys2 <- surveys1 %>%
  add_count(visit_date) %>% 
  select(basin_name, site_id, visit_date, visit_status, survey_type, n, survey_id)

# Create surveys table with only unique surveys (by basin & date, necessary when more than one site_id is included in cmr)
surveys2 <- surveys2 %>%
  filter(n > 1 & site_id == 10277 | n == 1)

# Read in captures data
captures <- read.csv("./data/clean/captures_upper.csv")
captures$survey_date <-  ymd(captures$survey_date)

# Create list of unique capture dates for use in joins
capture.dates <- captures %>%
  distinct(basin_name, survey_date) %>%
  mutate(visit_date = survey_date, basin_capture = basin_name) %>%
  select(-survey_date, -basin_name)

### Do all survey dates have frog captures? If not, do frogless surveys need to be dropped?
surveys2 %>%
  left_join(capture.dates, by = c("visit_date")) %>% View 

# Do all capture dates have associated surveys?
surveys2 %>%
  right_join(capture.dates, by = c("visit_date")) %>% View

# Remove unnecessary columns
surveys2 <- surveys2 %>%
  select(basin_name, site_id, visit_date, survey_type)

# Add survey recorded only as VES
surveys2 <- surveys2 %>% 
  add_row(basin_name = "upper", site_id = 10277, visit_date = ymd("2016-08-14"), survey_type = "cmr")

# Add reintroduction/translocation dates to surveys file

# Read in translocations data
translocations <- read.csv("./data/clean/translocations_upper.csv")
translocations$release_date <- ymd(translocations$release_date)
translocations$type <- as.character(translocations$type)

# Create list of distinct reintro events (by date) from final translocations file
reintro.dates <- translocations %>%
  mutate(visit_date = release_date, survey_type = type) %>% 
  select(site_id, visit_date, survey_type) %>% 
  distinct(visit_date, .keep_all = TRUE) %>%
  add_column(basin_name = as.character('upper'), primary_period = as.integer(1), secondary_period = as.integer (0))  

# add reintro events to survey file
surveyreintro <- surveys2 %>%
  arrange(visit_date) %>%
  add_column(primary_period = as.integer(2:8), secondary_period = as.integer(1)) %>%
  bind_rows(reintro.dates) %>% 
  mutate(survey_date = visit_date) %>%
  select(basin_name, site_id, survey_date, survey_type, primary_period, secondary_period) %>%
  arrange(survey_date)

# Check for cmr & translocation surveys conducted on the same date
surveyreintro %>% 
  group_by(survey_date) %>% 
  filter(n() > 1)

# Save surveys file as csv for use in mrmr
surveyreintro %>%  write.csv(file = "./data/clean/surveys_upper.csv", row.names = FALSE)

