# Load dependencies
source('R/load-deps.R')

# Read in data from PostgreSQL databases

# Connect to PostgreSQL database `amphibians`
con = dbConnect(dbDriver("PostgreSQL"), 
                user = rstudioapi::askForPassword("user name"), 
                password = rstudioapi::askForPassword("password"),
                host = "frogdb.eri.ucsb.edu", 
                port = 5432, 
                dbname = "amphibians")

# Create R objects from the relevant database tables
site.pg <- dbReadTable(con, c("site")) %>% as_tibble()
visit.pg <- dbReadTable(con, c("visit")) %>% as_tibble()
survey.pg <- dbReadTable(con, c("survey")) %>% as_tibble()
capture_survey.pg <- dbReadTable(con, c("capture_survey")) %>% as_tibble()

# Disconnect from database 'amphibians'
dbDisconnect(con) 

# Connect to PostgreSQL database "translocate_reintroduce"
con = dbConnect(dbDriver("PostgreSQL"), 
                user = rstudioapi::askForPassword("user name"), 
                password = rstudioapi::askForPassword("password"),
                host = "frogdb.eri.ucsb.edu", 
                port = 5432, 
                dbname = "translocate_reintroduce")

### Create R object from the relevant database table
transreintro.pg <-dbReadTable(con, c("transreintro")) %>% as_tibble()

# Disconnect from database 'translocate_reintroduce'
dbDisconnect(con) 

# Edit tables to enable joins between parent and child tables
visit <- visit.pg %>% 
  mutate(visit_id = id, comment_visit = comment) %>% 
  select(-id, -comment)
survey <- survey.pg %>% 
  mutate(survey_id = id, comment_survey = comment) %>% 
  select(-id, -comment)
capture_survey <- capture_survey.pg %>% 
  mutate(capture_id = id, comment_capture = comment) %>% 
  select(-id, -comment, -surveyor_id)

# Create table of sites to include in dataset
site_subset <- tibble(site_id = c(10314, 10315, 10316), basin_name = "pinchot") 
site_subset$site_id <- as.integer(site_subset$site_id)

# Create capture-mark-recapture (cmr) dataset
captures <- site_subset %>%
  inner_join(visit, by = c("site_id")) %>%
  select(site_id, basin_name, visit_date, visit_status, visit_id) %>% 
  inner_join(survey, by = c("visit_id")) %>% 
  select(site_id, basin_name, visit_date, visit_status, survey_type, visit_id, survey_id, comment_survey) %>% 
  inner_join(capture_survey, by = c("survey_id")) %>% 
  filter(survey_type == 'cmr') %>%
  select(site_id, basin_name, visit_date, visit_status, survey_type, pit_tag_ref, tag_new, species, 
         capture_life_stage, capture_animal_state, length, sex, swab_id, comment_survey, comment_capture, capture_id, visit_id, survey_id)

# Export tibble as rds file for later data cleaning
saveRDS(captures, "./data/raw/captures_pinchot_uncleaned.rds")

# Create survey dataset
surveys <- site_subset %>%
  inner_join(visit, by = c("site_id")) %>%
  select(basin_name, site_id, visit_date, visit_status, visit_id, comment_visit) %>% 
  inner_join(survey, by = c("visit_id")) %>% 
  filter(survey_type != "swab") %>%
  select(basin_name, site_id, visit_date, visit_status, survey_type, wind, sky, start_time, end_time, duration, description, comment_visit, comment_survey,
         survey_id, visit_id) 

# Export original data as rds file 
saveRDS(surveys, file = "./data/raw/surveys_pinchot_uncleaned.rds")

# Create translocations dataset
translocations <- transreintro.pg %>% 
  filter(release_location %in% c(10315)) %>% 
  select(release_location, release_date, pit_tag_ref, type, comments) %>%
  arrange(release_date)
  
# Export original data as rds file 
saveRDS(translocations, file = "./data/raw/translocations_pinchot_uncleaned.rds")
  
