# Mitigating the effects of the amphibian chytrid fungus

*Roland A. Knapp, Maxwell B. Joseph, and Thomas C. Smith*

This repository contains data, models, and a report/manuscript describing antifungal treatments, frog translocations, and frog reintroductions conducted to mitigate the effects of the amphibian chytrid fungus *Batrachochytrium dendrobatidis* on populations of the endangered [mountain yellow-legged frog](https://bit.ly/conservationstrategy). 
These mitigation efforts were conducted in the southern Sierra Nevada mountains (California, USA) during the period 2006-2018. 

The mitigation efforts included the following:
1. Treatment of young life stages with the antifungal drug, itraconazole, in Barrett Lakes Basin (2009) and Dusy Basin (2010).
2. Treatment of adults with itraconazole in LeConte Canyon (2015) and Treasure Lakes (2018).
3. Treatment of metamorphs with the commensal antifungal bacterium *Janthinobacterium lividum* in Dusy Basin (2012).
4. Reintroduction of Bd-naive adults to South Fork Kings River (Upper, Ruskin, and Pinchot Basins) in 2013.
5. Reintroduction of adults from declining populations to Tyndall, Milestone, Pinchot, and Sixty Lake Basins in 2016-2018.
6. Translocation of adults from persistent populations in Yosemite. This summarizes the main results from the 2020 Yosemite translocation analysis report.

All sections (1-6) are included in a report ("Version 1") that was a required deliverable under U.S. Department of the Interior - National Park Service cooperative agreement number P19AC00789. 
Sections 1-3 are included in the following peer-reviewed paper: Knapp et al. 2022. Effectiveness of antifungal treatments during chytridiomycosis epizootics in populations of an endangered frog. PeerJ: XXXXX ("Version 2" = original submission, "Version 3" = final submission). 

All raw data used in the analyses are in the `data` directory (see `README` file in that directory for details).
All R code to analyze the data are in the `R` directory. 
All R code and bibliography files to create the report/manuscript are in the `report` directory.
Stan code used to fit the LeConte multi-state model is in the `stan` directory. 

This repository is maintained by Roland Knapp (roland.knapp(at)ucsb.edu).

## Installing package dependencies

You can install R package dependencies via:

```r
# install.packages("remotes")
remotes::install_deps()
```

## Docker instructions

To build a Docker image with the dependencies installed: 

```
docker build -t bd-mitigation-report .
```

The built image will include RStudio and all dependencies for this project. 
To start a Docker container after building the image: 

```
docker run -e PASSWORD=yourpasswordhere --rm -p 8787:8787 bd-mitigation-report
```

Then, you can connect to the container's RStudio server in a web browser at `localhost:8787`.
