# mrmr analysis of Pinchot dataset (South Fork Kings River)

# Load dependencies
source('R/load-deps.R')

# Install mrmr package if installed version is not the latest available version
remotes::install_github("SNARL1/mrmr")

# Create required data frames
captures <- "./data/clean/captures_pinchot.csv" %>% read_csv
translocations <- "./data/clean/translocations_pinchot.csv" %>% read_csv
surveys <- "./data/clean/surveys_pinchot.csv" %>% read_csv

# Read and clean the data
dat <- clean_data(captures = captures, surveys = surveys, translocations = translocations)

# Fit model
mod <- fit_model(dat, cores = parallel::detectCores(), chains = 4, iter = 2000) #, control = list(adapt_delta = 0.9))

# Save model objects (in case of crash during visualizations)
write_rds(mod, "./out/model_pinchot_mrmr.rds", "xz", compression = 9L)

# To diagnose potential non-convergence of the MCMC algorithm, inspect traceplots, Rhat estimates (any >= 1.01?)
traceplot(mod$m_fit, pars = "Nsuper")
pars_to_plot <- c('alpha_lambda', 
                  'sigma_lambda', 
                  'beta_phi', 
                  'sigma_phi', 
                  'beta_detect')
traceplot(mod$m_fit, pars = pars_to_plot)
print(mod$m_fit, pars = pars_to_plot)

# Visualize model results
plot_model(mod, what = 'abundance')
plot_model(mod, what = 'recruitment')
plot_model(mod, what = 'survival')

# Create survival table
survival_table(mod)

# Customize plots
p1 <- plot_model(mod, what = 'survival') 
p1 <- p1 + ggtitle('A. Survival of translocated frogs') +
  theme(legend.position = "none")

p2 <- plot_model(mod, what = 'abundance') 
p2 <- p2 + ggtitle('B. Population size') +
  ylab("Number of adults")

p3 <- plot_model(mod, what = 'recruitment')
p3 <- p3 + ggtitle('C. Recruitment') +
  ylab("Number of adults")

p1 / p2 / p3
ggsave("./out/pinchot_mrmr_plots.png", width = 6.5, height = 7.2)
