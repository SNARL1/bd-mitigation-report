all: report/report.pdf

leconte_cmr = stan/2018_abund.csv \
	stan/ctrl_abund.csv \
	stan/load_diffs.csv \
	stan/pct_observed.csv \
	stan/survival_diffs.csv \
	fig/leconte-fig.png

leconte_data = data/leconte-20152018-surveys.csv \
	data/leconte-20152018-captures.csv

$(leconte_cmr): stan/time-varying.stan R/leconte-cmr-model.R $(leconte_data)
	Rscript --vanilla R/leconte-cmr-model.R

report/report.pdf: report/report.Rmd bibliography.bib ecology.csl header.sty
	Rscript -e "rmarkdown::render('report/report.Rmd')"
