# See comments on lines 287-294. If you want to skip the lengthy model-fit section,
# read in the saved model-fit object (as described in the comments) and skip 
# lines 295-298. 

library(tidyverse)
library(reshape2)
library(assertthat)
library(ggthemes)
library(patchwork)
library(rstan)
options(mc.cores = parallel::detectCores())
rstan_options(auto_write = TRUE)

surveys <- read_csv("data/leconte-20152018-surveys.csv")
captures <- read_csv("data/leconte-20152018-captures.csv") %>%
  mutate(visit_date = visit_date, 
         pit_tag_id = as.character(pit_tag_ref)) %>%
  filter((trt_period == "pretreat" | is.na(trt_period)) & (trt_died == FALSE | is.na(trt_died)))
length(unique(captures$pit_tag_id))

# how many adults were captured between 2016-2018?
captures %>%
  filter(visit_date > as.Date("2015-12-31")) %>%
  distinct(pit_tag_id)

# if we restrict attention to the lower basin, what was the treatment group
# composition of captured animals? 
captures %>%
  filter(location == "lower", visit_date > as.Date("2015-12-31")) %>%
  distinct(pit_tag_id, category) %>%
  count(category)


# How many individuals are known to have moved
nsite_df <- captures %>%
  group_by(pit_tag_id) %>%
  summarize(nsite = length(unique(location))) %>%
  filter(nsite > 1)

# Which direction did those individuals move
captures %>%
  filter(pit_tag_id %in% nsite_df$pit_tag_id) %>%
  arrange(pit_tag_id, visit_date) %>%
  split(.$pit_tag_id)

grp_df <- distinct(captures, pit_tag_id, location, category)

end_trt_load <- captures %>%
  filter(trt_period == "endtreat")

first_period <- surveys %>%
  group_by(location) %>%
  filter(visit_date == min(visit_date)) %>%
  mutate(primary_period = 1, secondary_period = 1)

lag_df <- surveys %>%
  select(-ends_with("period")) %>%
  left_join(first_period) %>%
  group_by(location) %>%
  mutate(lag_diff = lag(visit_date) - visit_date) %>%
  ungroup

low_lag <- filter(lag_df, location == "lower")
hi_lag <- filter(lag_df, location == "upper")

# assign primary and secondary periods
for (i in 1:nrow(low_lag)) {
  if (is.na(low_lag$primary_period[i])) {
    if (low_lag$lag_diff[i] == -1) {
      # same primary period, increment secondary
      low_lag$primary_period[i] <- low_lag$primary_period[i - 1]
      low_lag$secondary_period[i] <- low_lag$secondary_period[i - 1] + 1
    } else {
      # increment primary period, reset secondary
      pr <- low_lag$primary_period[i - 1] + 1
      se <- 1
      low_lag$primary_period[i] <- pr
      low_lag$secondary_period[i] <- se
    }
  }
}

for (i in 1:nrow(hi_lag)) {
  if (is.na(hi_lag$primary_period[i])) {
    if (hi_lag$lag_diff[i] == -1) {
      # same primary period, increment secondary
      hi_lag$primary_period[i] <- hi_lag$primary_period[i - 1]
      hi_lag$secondary_period[i] <- hi_lag$secondary_period[i - 1] + 1
    } else {
      # increment primary period, reset secondary
      pr <- hi_lag$primary_period[i - 1] + 1
      se <- 1
      hi_lag$primary_period[i] <- pr
      hi_lag$secondary_period[i] <- se
    }
  }
}

survey_df <- full_join(low_lag, hi_lag) %>%
  select(-category) %>%
  # the first primary period is the initial state
  mutate(secondary_period = ifelse(primary_period == 1, NA, secondary_period)) %>%
  select(-lag_diff)

assert_that(nrow(survey_df) == nrow(surveys))

last_swab_date <- tibble(location = c("lower", "upper"), 
                         last_date = as.Date(c("2015-09-01", "2015-09-15")))

loads_2015 <- captures %>%
  filter(trt_period == "pretreat") %>%
  full_join(end_trt_load) %>%
  left_join(last_swab_date) %>%
  filter(visit_date <= last_date) %>%
  group_by(location, category) %>%
  mutate(final_swab_collection_date = max(visit_date)) %>% 
  filter(visit_date == final_swab_collection_date) %>%
  ungroup %>%
  mutate(primary_period = 1)

loads_2015 %>%
  ggplot(aes(visit_date, bd_load, color = category)) + 
  geom_point() + 
  facet_wrap(~location) + 
  scale_y_log10()

assert_that(nrow(loads_2015) == length(unique(loads_2015$pit_tag_id)))
assert_that(!any(is.na(loads_2015$category)))

#pal <- c("darkgrey", "#008a8a", "#8a0082")
pal <- c("forestgreen", "deepskyblue2", "darkgray")


table(captures$category)


# States: 
# 1. alive upper
# 2. alive lower
# 3. not rec
# 3. dead
# State transition matrix Psi is 4x4
#          Upper t+1         Lower t+1          Pseudoind. t+1   Dead t+1
#          [up_t+1 | up_t ]  [low_t+1 | up_t ]  [ps_t+1 | up_t ] [dead_t+1 | up_t ]  Upper_t    
# Psi_t =  [up_t+1 | low_t]  [low_t+1 | low_t]  [ps_t+1 | low_t] [dead_t+1 | low_t]  Lower_t
#          [up_t+1 | ps_t ]  [low_t+1 | ps_t ]  [ps_t+1 | ps_t ] [dead_t+1 | ps_t ]  Psued_t
#          [up_t+1 | dead ]  [low_t+1 | dead ]  [ps_t+1 | dead ] [dead_t+1 | dead_t] Dead_t
#
# Intial probability vector is length 4
# [up_1] [low_1] [ps_1] [dead_1]

# Observations
# 1. Detected upper
# 2. Detected lower
# 3. Not detected
# Observation matrix is 4 x 3
#  Upper         Lower           Not detected
# [up_t | up_t ] [low_t | up_t ] [nd_t | up_t ]
# [up_t | low_t] [low_t | low_t] [nd_t | low_t]
# [up_t | ps_t ] [low_t | ps_t ] [nd_t | ps_t ]
# [up_t | ded_t] [low_t | ded_t] [nd_t | ded_t]


# Create an observation array Y -------------------------------------------
# this is 3-d, with dimensions: 
# 1. Individual (including pseudo-individuals)
# 2. Primary period
# 3. Secondary period
# with entries {1, 2, 3} corresponding to the 3 possible observations
# and 0 as a fill value (Stan cannot handle NAs, so 0 acts as NA for Y)
y_obs <- captures %>%
  left_join(survey_df) %>%
  select(pit_tag_id, location, primary_period, secondary_period) %>%
  mutate(y = case_when(
    location == "upper" ~ 1, 
    location == "lower" ~ 2
  )) %>%
  select(pit_tag_id, primary_period, secondary_period, y)

n_aug <- round(1.0 * length(unique(captures$pit_tag_id)))
M <- length(unique(captures$pit_tag_id)) + n_aug
y_aug <- tibble(pit_tag_id = paste0("aug_", 1:n_aug))

# join observed captures and augmented captures together
y_full <- full_join(y_obs, y_aug)

Y <- y_full %>%
  acast(pit_tag_id ~ primary_period ~ secondary_period, 
        value.var = "y", fill = 3)

# trim off an extra entry for NA primary & secondary periods
Y <- Y[, dimnames(Y)[[2]] != "NA", ]
Y <- Y[, , dimnames(Y)[[3]] != "NA"]

# verify my assumptions about Y
assert_that(dim(Y)[1] == M)
assert_that(dim(Y)[2] == max(survey_df$primary_period))
assert_that(dim(Y)[3] == max(survey_df$secondary_period, na.rm = TRUE))
assert_that(!any(dimnames(Y)[[1]] == "NA"))
assert_that(!any(is.na(Y)))


# Generate a vector for whether initial state is known --------------------
# The initial state z_{t = 1} is known for individuals captured in 2015
# but is unkown for those that are first observed after 2015 or never observed
# 0: acts as NA (unknown)
# 1: upper
# 2: lower
# 3: not yet recruited
# 4: dead (impossible as starting state)
upper_initial_df <- captures %>%
  filter(visit_date < as.Date("2016-01-01"), 
         location == "upper")
lower_initial_df <- captures %>%
  filter(visit_date < as.Date("2016-01-01"), 
         location == "lower")
initial_state <- rep(NA, M)
for (i in 1:M) {
  tag <- dimnames(Y)[[1]][i]
  initial_state[i] <- case_when(
    tag %in% upper_initial_df$pit_tag_id ~ 1,
    tag %in% lower_initial_df$pit_tag_id ~ 2,
    TRUE ~ 0
  )
}
assert_that(!any(is.na(initial_state)))


J <- survey_df %>%
  group_by(primary_period) %>%
  summarize(J = max(secondary_period)) %>%
  mutate(J = ifelse(is.na(J), 0, J)) %>%
  arrange(primary_period) %>%
  select(J) %>%
  unlist

trt_grp <- captures$category[match(dimnames(Y)[[1]], captures$pit_tag_id)]
trt_grp <- ifelse(is.na(trt_grp), "new", trt_grp)
table(trt_grp)


bd_load_df <- captures %>%
  left_join(survey_df) %>%
  full_join(loads_2015) %>% 
  filter(!((visit_date < "2016-01-01") & is.na(final_swab_collection_date))) %>%
  mutate(log_load = log10(1 + bd_load), 
         scaled_load = c(scale(log_load))) %>%
  filter(!is.na(bd_load))

# Verify that the 2015 load data is as expected
assert_that(nrow(filter(bd_load_df, visit_date < "2016-01-01")) == nrow(loads_2015))

all_bd_idx <- expand.grid(primary_period = 1:dim(Y)[2], 
                          pit_tag_id = dimnames(Y)[[1]]) %>%
  as_tibble

obs_bd_idx <- distinct(bd_load_df, primary_period, pit_tag_id)
unk_bd_idx <- all_bd_idx %>%
  anti_join(obs_bd_idx)

assert_that(nrow(unk_bd_idx) == nrow(all_bd_idx)-nrow(obs_bd_idx))

# Format data for rstan ---------------------------------------------------


stan_d <- list(M = M, 
               T = dim(Y)[2], 
               maxJ = max(J), 
               J = J, 
               initial_state = initial_state, 
               Y = Y, 
               trt_grp = as.numeric(factor(trt_grp)), 
               alpha_init = c(1, 2, 3), 
               n_obs = nrow(bd_load_df), 
               obs_load = bd_load_df$scaled_load, 
               obs_t = bd_load_df$primary_period, 
               obs_i = match(bd_load_df$pit_tag_id, dimnames(Y)[[1]]),
               n_unk = nrow(unk_bd_idx), 
               unk_t = unk_bd_idx$primary_period,
               unk_i = match(unk_bd_idx$pit_tag_id, dimnames(Y)[[1]]),
               swab_upper = as.numeric(bd_load_df$location == "upper"))




# Fit models --------------------------------------------------------------
# Note that this will raise Rhat warnings because there are some discrete 
# parameters that have no posterior variance (e.g., states that are known)
# without error.
# Note also that this model will take ~8 hrs to fit on a 4 core i7 workstation.
# To proceed without fitting model, download leconte_m_fit.rds (3.8 GB) from 
# https://drive.google.com/file/d/1azYfehESh1vflHrFOmIFpUFMOhGEL_-Q/view?usp=sharing, 
# save to stan directory, read in using m_fit <- read_rds("stan/leconte_m_fit.rds"), 
# and skip lines 294-297.
m_init <- stan_model("stan/time-varying.stan")
m_fit <- sampling(m_init, data = stan_d,
                  control = list(max_treedepth = 11, adapt_delta = 0.99))
write_rds(m_fit, "stan/leconte_m_fit.rds")

# Check convergence -----------------------------------------------------------
traceplot(m_fit)
traceplot(m_fit, pars = c("beta_srv_bd", 
                          "beta_srv",
                          "initial_state_vec"))
pairs(m_fit, pars = c("beta_srv_bd", "mu_srv"))
pairs(m_fit, pars = c("beta_srv_bd", "initial_state_vec"))
traceplot(m_fit, pars = c("sd_bd", "sd_bd_obs", "bd_grp_adj"))
print(m_fit, pars = c("sd_bd", "sd_bd_obs", "bd_grp_adj"))
pairs(m_fit, pars = c("sd_bd", "sd_bd_obs", "bd_grp_adj"))

traceplot(m_fit, pars = c("pr_move_to_upper", "pr_move_to_lower"))
traceplot(m_fit, pars = c("pr_recruit", "mu_recruit", "sd_recruit", "rec_upper"))
plot(m_fit, pars = c("pr_recruit"))
traceplot(m_fit, pars = "mu_bd")

print(m_fit, pars = "mu_bd")
print(m_fit, pars = "Nsuper")
print(m_fit, pars = "initial_state_vec")

# Bd effects 
# 1: ctrl, 2: new, 3: treated
plot(m_fit, pars = "bd_grp_adj")  # adjustment on expected load
plot(m_fit, pars = "beta_srv_bd") # effect on survival


traceplot(m_fit, pars = "Nsuper") + 
  ylim(0, stan_d$M + 100) + 
  geom_hline(yintercept = stan_d$M, linetype = "dashed")


# Generating final graphics -----------------------------------------------


# Visualize survival estimates

primary_date_df <- survey_df %>%
  mutate(secondary_period = ifelse(is.na(secondary_period), 0, secondary_period)) %>%
  filter(secondary_period < 2) %>%
  rename(t = primary_period) %>%
  group_by(t) %>%
  summarize(visit_date = min(visit_date))

captures %>%
  filter(category == "new") %>%
  distinct(pit_tag_id, location) %>%
  count(location)


# Recruitment
s_post <- rstan::extract(m_fit, pars = "s")$s
n_iter <- dim(s_post)[1]
recruitment_lower <- matrix(NA, nrow = n_iter, ncol = stan_d$T - 1)
recruitment_upper <- matrix(NA, nrow = n_iter, ncol = stan_d$T - 1)
alive_upper <- matrix(NA, nrow = n_iter, ncol = stan_d$T)
alive_lower <- matrix(NA, nrow = n_iter, ncol = stan_d$T)

for (i in 1:n_iter) {
  for (t in 1:(stan_d$T - 1)) {
    recruitment_lower[i, t] <- sum(s_post[i, , t] == 3 & s_post[i, , t+1] == 2)
    recruitment_upper[i, t] <- sum(s_post[i, , t] == 3 & s_post[i, , t+1] == 1)
  }
  for (t in 1:stan_d$T) {
    alive_upper[i, t] <- sum(s_post[i, , t] == 1)
    alive_lower[i, t] <- sum(s_post[i, , t] == 2)
  }
}

rec_low_df <- melt(recruitment_lower, varnames = c("iter", "t")) %>%
  as_tibble %>%
  mutate(location = "lower")
rec_hi_df <- melt(recruitment_upper, varnames = c("iter", "t"))  %>%
  as_tibble %>%
  mutate(location = "upper")


full_join(rec_low_df, rec_hi_df) %>%
  mutate(primary_period = t + 1) %>%
  left_join(survey_df) %>%
  filter(secondary_period < 2) %>%
  ggplot(aes(x = visit_date, y = value, color = location)) + 
  geom_jitter(height = 0, width = 10, size = .5, alpha = .1) + 
  ylab("Number of recruits") + 
  xlab("Date") + 
  scale_y_log10()


# Plot abundance by group -------------------------------------------------
s_df <- s_post %>%
  reshape2::melt(varnames = c("iter", "i", "t")) %>%
  filter(value < 3) %>%
  as_tibble %>%
  mutate(trt = trt_grp[i]) %>%
  count(trt, t, iter)


#pal <- c("darkgrey", "#008a8a", "#8a0082")
pal <- c("forestgreen", "deepskyblue2", "darkgray")

s_plot <- s_df %>%
  arrange(iter, t, n) %>%
  complete(trt, t, iter, fill = list(n = 0)) %>%
  left_join(primary_date_df) %>%
  mutate(trt = case_when(
    trt == "control" ~ "Control", 
    trt == "new" ~ "Non-experimental", 
    trt == "treated" ~ "Treated"
    ), 
    trt = fct_relevel(trt, c("Control", "Treated", "Non-experimental"))) %>%
  ggplot(aes(visit_date, n, color = trt))  + 
  geom_jitter(alpha = .02, size = 0.5, width = 10, height = 0) + 
  facet_wrap(~trt, nrow = 1) + 
  scale_x_date(limits = as.Date(c("2015-01-01", "2018-08-15"))) +
  ylab("Live adults") + 
  theme_classic() + 
  xlab("Date") +   
  scale_color_manual("Group", values = pal) + 
  theme_classic() +
  theme(legend.position = "none", 
        strip.background = element_blank(),
        strip.text.x = element_blank(),
        axis.text = element_text(color = "black")) + 
  scale_y_log10()
s_plot


# Plot Bd loads -----------------------------------------------------------
bd_post <- rstan::extract(m_fit, pars = "load")$load %>%
  reshape2::melt(varnames = c("iter", "i", "t")) %>%
  as_tibble %>%
  group_by(i, t) %>%
  summarize(mean = mean(value), 
            sd = sd(value)) %>%
  ungroup %>%
  mutate(pit_tag_id = dimnames(stan_d$Y)[[1]][i]) %>%
  left_join(bd_load_df %>%
              distinct(pit_tag_id, primary_period, 
                       location, category, scaled_load) %>%
              rename(t = primary_period))

bd_post %>%
  filter(i < 80) %>%
  ggplot(aes(t, mean)) + 
  geom_line() + 
  geom_ribbon(aes(ymin = mean - sd, ymax = mean + sd), alpha = .4) +
  facet_wrap(~i)

bd_post %>%
  ggplot(aes(x = scaled_load, y = mean)) + 
  geom_point(alpha = .3) + 
  geom_linerange(aes(ymin = mean - sd, ymax = mean + sd), alpha = .1) + 
  geom_abline(linetype = "dashed")

swab_counts <- bd_post %>%
  filter(!is.na(scaled_load)) %>%
  count(pit_tag_id)

many_swabs <- swab_counts %>%
  top_n(30, n) 

bd_post %>%
  filter(pit_tag_id %in% many_swabs$pit_tag_id) %>%
  ggplot(aes(t, mean)) + 
  geom_line() + 
  facet_wrap(~pit_tag_id) + 
  geom_point(aes(y = scaled_load)) + 
  geom_ribbon(aes(ymin = mean - sd, ymax = mean + sd), color = NA, alpha = .5)


# Visualize Bd survival effects -------------------------------------------

beta_srv_bd <- rstan::extract(m_fit, "beta_srv_bd")$beta_srv_bd
beta_srv <- rstan::extract(m_fit, "beta_srv")$beta_srv
mu_srv <- rstan::extract(m_fit, "mu_srv")$mu_srv
bd_vector <- seq(min(stan_d$obs_load), max(stan_d$obs_load), length.out = 30)

surv_df <- as_tibble(expand.grid(scaled_load = bd_vector, 
                                 trt = 1:3)) %>%
  group_by(scaled_load, trt) %>%
  summarize(iter = list(1:nrow(beta_srv_bd)), 
            p = list(plogis(mu_srv + 
                              beta_srv[, trt] + 
                              beta_srv_bd[, trt] * scaled_load))) %>%
  ungroup %>%
  unnest(cols = c(iter, p)) %>%
  mutate(trt = c("control", "non-experimental", "treated")[trt])

surv_plot <- surv_df %>%
  mutate(
    trt = case_when(
      trt == "control" ~ "Control", 
      trt == "non-experimental" ~ "Non-experimental", 
      trt == "treated" ~ "Treated"
    ), 
    trt = fct_relevel(trt, c("Control", "Treated", "Non-experimental"))) %>%
  ggplot(aes(scaled_load * sd(bd_load_df$log_load) + mean(bd_load_df$log_load), 
             p,
             group = iter,
             color = trt, 
             fill = trt)) + 
  geom_path(alpha = .02, size=.2) + 
  facet_wrap(~trt) + 
  geom_rug(inherit.aes = FALSE,
           data = bd_load_df %>%
             mutate(trt = case_when(
               category == "control" ~ "Control", 
               category == "new" ~ "Non-experimental", 
               category == "treated" ~ "Treated"
             ), 
             trt = fct_relevel(trt, c("Control", "Treated", "Non-experimental")),
             name = ifelse(location == "lower",
                           "Lower site", "Upper site")),
           aes(x = log10(bd_load + 1), color = trt),
           alpha = .2) +
  xlab("Bd load") +
  ylab("Survival probability") + 
  scale_color_manual("Group", values = pal) + 
  scale_fill_manual("Group", values = pal) + 
  theme_classic() +
  theme(panel.grid.minor = element_blank(), 
        legend.position = "none", 
        axis.text = element_text(color = "black"))
surv_plot

bd_plot_data <- bd_load_df %>%
  arrange(pit_tag_id, visit_date) %>%
  mutate(trt = case_when(
    category == "control" ~ "Control", 
    category == "new" ~ "Non-experimental", 
    category == "treated" ~ "Treated"
  ), 
  trt = fct_relevel(trt, c("Control", "Treated", "Non-experimental")),
  name = ifelse(location == "lower",
                "Lower site", "Upper site"), 
  load = log10(bd_load + 1))

bd_medians <- bd_plot_data %>%
  group_by(primary_period, trt) %>%
  summarize(load = median(load), 
            visit_date = min(visit_date))

bd_ts <- bd_plot_data %>%
  ggplot(aes(visit_date, load, color = trt)) + 
  geom_point(alpha = .7, size = .5) + 
  geom_line(aes(group = pit_tag_id), size = .1) +
  geom_point(data = bd_medians, color = "black", shape = 18) +
  facet_grid( ~ trt) + 
  scale_x_date(limits = as.Date(c("2015-01-01", "2018-08-15"))) +
  xlab("Date") + 
  ylab("Bd load") +
  theme_classic() +
  theme(legend.position = "none", 
        panel.grid.minor = element_blank(),
        axis.text = element_text(color = "black")) + 
  scale_color_manual(values = pal, "Group")
bd_ts

# Save out the final figure
p <- bd_ts + ggtitle("A") + 
  s_plot + ggtitle("B") +
  surv_plot + ggtitle("C") + 
  plot_layout(ncol = 1, heights = c(1, 0.8, 1))

# dir.create("figures", showWarnings = FALSE)
ggsave("out/figures/leconte-multistate-results.png", plot = p, width = 6.5, height = 8)


# Group adjustments on Bd load --------------------------------------------
# 1: control
# 2: new
# 3: treated
bd_grp_adj <- rstan::extract(m_fit, pars = "bd_grp_adj")$bd_grp_adj
mean(bd_grp_adj[, 1] > bd_grp_adj[, 2]) # pr control > new
mean(bd_grp_adj[, 1] > bd_grp_adj[, 3]) # pr control > treated
mean(bd_grp_adj[, 2] > bd_grp_adj[, 3]) # pr new > treated

# Bd load effects on survival
str(beta_srv_bd)
tibble(
  ctrl_lt_trt = mean(beta_srv_bd[, 1] < beta_srv_bd[, 3]), 
  ctrl_lt_new = mean(beta_srv_bd[, 1] < beta_srv_bd[, 2])
) %>%
  mutate_all(~round(., 2)) %>%
  write_csv("stan/survival_diffs.csv")


# Expected Bd load by primary period and group ----------------------------

mu_bd <- rstan::extract(m_fit, pars = "mu_bd")$mu_bd

mu_ctrl <- mu_bd + bd_grp_adj[, 1]
mu_new <- mu_bd + bd_grp_adj[, 2]
mu_trt <- mu_bd + bd_grp_adj[, 3]

avg_load <- mean(bd_load_df$log_load)
sd_load <- sd(bd_load_df$log_load)

z_ctrl <- avg_load + mu_ctrl * sd_load
z_trt <- avg_load + mu_trt * sd_load

# difference between control and treated
l_ctrl <- 10^(z_ctrl) - 1
l_trt <- 10^(z_trt) - 1
diff_ctrl_trt <- l_ctrl / l_trt

# difference in first primary period
primary_date_df$visit_date[1]
quantile(diff_ctrl_trt[, 1], c(0.025, .5, .975)) %>%
  tibble(diff = ., 
         vals = c(0.025, .5, .975)) %>%
  write_csv("stan/load_diffs.csv")


# Abundance in the last primary period ------------------------------------

s_df %>%
  filter(t == max(t)) %>%
  complete(trt, t, iter, fill = list(n = 0)) %>%
  group_by(t, trt) %>%
  summarize(lo = round(quantile(n, 0.025)), 
            med = median(n), 
            hi = round(quantile(n, .975))) %>%
  rename(primary_period = t) %>%
  as.data.frame %>%
  left_join(survey_df %>%
              group_by(primary_period) %>%
              summarize(date = min(visit_date))) %>%
  write_csv("stan/2018_abund.csv")

# abundance of controls on each primary period
s_df %>%
  filter(trt == "control") %>%
  complete(trt, t, iter, fill = list(n = 0)) %>%
  group_by(t, trt) %>%
  summarize(lo = quantile(n, 0.025), 
            med = median(n), 
            hi = quantile(n, .975)) %>%
  rename(primary_period = t) %>%
  as.data.frame %>%
  left_join(survey_df %>%
              group_by(primary_period) %>%
              summarize(date = min(visit_date))) %>%
  write_csv("stan/ctrl_abund.csv")


# Total number of recruits over the experimental period ------------

full_join(rec_low_df, rec_hi_df) %>%
  mutate(primary_period = t + 1) %>%
  left_join(survey_df) %>%
  filter(secondary_period < 2) %>%
  group_by(iter) %>%
  summarize(total_recruitment = sum(value)) %>%
  ungroup() %>%
  summarize(lo = quantile(total_recruitment, .025), 
            med = quantile(total_recruitment, .5), 
            hi = quantile(total_recruitment, .975))


# Superpopulation size ----------------------------------------------------

Nsuper <- rstan::extract(m_fit, pars = "Nsuper")$Nsuper
frac_observed <- length(unique(captures$pit_tag_id)) / Nsuper 
hist(frac_observed)
quantile(frac_observed, c(.025, .5, .975)) %>%
  tibble(p = round(., 2) * 100, 
         vals = c(0.025, .5, .975)) %>%
  write_csv("stan/pct_observed.csv")



# Write detection probability data to file --------------------------------

p_df <- rstan::extract(m_fit, pars = c("pr_detect"))[[1]] %>%
  apply(2, quantile, c(0.025, .5, .975)) %>%
  reshape2::melt(varnames = c("q", "t")) %>%
  as_tibble %>%
  mutate(q = case_when(
    q == "2.5%" ~ "lo", 
    q == "50%" ~ "med", 
    q == "97.5%" ~ "hi"
  )) %>%
  mutate(value = round(value, 2)) %>%
  tidyr::pivot_wider(names_from = q, values_from = value)
write_csv(p_df, here::here("out", "detection_prob_summary.csv"))

mean_p_df <- rstan::extract(m_fit, pars = "mu_detect")[[1]] %>%
  plogis %>%
  quantile(c(0.025, .5, .975)) %>%
  round(2)
names(mean_p_df) <- c("lo", "med", "hi")
as_tibble(t(mean_p_df)) %>%
  write_csv(here::here("out", "mean_p.csv"))


# Summarize survival on an annual basis -----------------------------------

primary_period_yrs <- survey_df %>%
  mutate(year = lubridate::year(visit_date)) %>%
  distinct(primary_period, year)

survival_summary <- s_post %>%
  melt(varnames = c('iter', 'i', 'primary_period')) %>%
  as_tibble %>%
  mutate(trt_grp = trt_grp[i]) %>%
  left_join(primary_period_yrs)

n_iter_use <- 1000
fs_annual_survival <- survival_summary %>%
  # use a subset of iterations to avoid memory explosion
  filter(iter %in% sample(1:max(survival_summary$iter), 
                          size = n_iter_use, replace = FALSE)) %>%
  group_by(i, trt_grp, year, iter) %>%
  summarize(alive = any(value == 1) | any(value == 2), 
            dead = any(value == 4)) %>%
  group_by(iter, i, trt_grp) %>%
  arrange(iter, i, year) %>%
  mutate(survived = case_when(
    alive & lead(alive) ~ TRUE, 
    alive & lead(dead) ~ FALSE,
    TRUE ~ NA)
    ) %>% 
  filter(!is.na(survived)) %>%
  ungroup %>%
  group_by(trt_grp, year, iter) %>%
  summarize(pr_survive_to_next_year = mean(survived))

fs_annual_survival_summary <- fs_annual_survival %>%
  ungroup %>%
  group_by(trt_grp, year) %>%
  summarize(median_pr_survive_to_next_year = median(pr_survive_to_next_year),
            lo = quantile(pr_survive_to_next_year, .025), 
            hi = quantile(pr_survive_to_next_year, .975))
write_csv(fs_annual_survival_summary, "out/fs_annual_survival_summary.csv")

fs_annual_survival %>%
  ggplot(aes(x = pr_survive_to_next_year, fill = trt_grp)) + 
  geom_density(alpha = 0.3) + 
  facet_wrap(~year, ncol = 1)

