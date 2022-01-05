# Mitigating the effects of the amphibian chytrid fungus

## Authors of this repository
Roland A. Knapp [![ORCiD](https://img.shields.io/badge/ORCiD-0000--0002--1954--2745-green.svg)](http://orcid.org/0000-0002-1954-2745)

Maxwell B. Joseph [![ORCiD](https://img.shields.io/badge/ORCiD-0000--0002--7745--9990-green.svg)](http://orcid.org/0000-0002-7745-9990)

Thomas C. Smith [![ORCiD](https://img.shields.io/badge/ORCiD-0000--0001--7908--438X-green.svg)](http://orcid.org/0000-0001-7908-438X)

## Overview of content
This repository is a research compendium for a decade-long effort to mitigate the effects of the amphibian chytrid fungus *Batrachochytrium dendrobatidis* ("Bd") on populations of the endangered [mountain yellow-legged frog](https://bit.ly/conservationstrategy). 
These mitigation efforts were conducted in the southern Sierra Nevada mountains (California, USA) during the period 2006-2018. This research culminated in the publication of a peer-reviewed paper entitled, "Effectiveness of antifungal treatments during chytridiomycosis epizootics in populations of an endangered frog" ([Knapp et al. 2022. PeerJ: XXXXX](xxxxxxxx)). 

The repository contains data, code to analyze treatment outcomes, and a report/manuscript describing the results of Bd mitigation efforts. 
These efforts included the following:
1. Treatment of young life stage frogs with the antifungal drug, itraconazole, in Kings Canyon National Park (Barrett Lakes Basin - 2009, Dusy Basin - 2010).
2. Treatment of adults with itraconazole in LeConte Canyon (Kings Canyon National Park - 2015) and Treasure Lakes (Inyo National Forest - 2018).
3. Treatment of metamorphs with the commensal antifungal bacterium *Janthinobacterium lividum* in Kings Canyon National Park (Dusy Basin - 2012).
4. Reintroduction of Bd-naive adults to several sites in the South Fork Kings River watershed of Kings Canyon National Park (Upper, Ruskin, and Pinchot Basins) in 2013.
5. Reintroduction of adults from declining frog populations to several sites in Sequoia National Park (Tyndall and Milestone basins) and Kings Canyon National Park (Pinchot and Sixty Lake basins) during 2016-2018.
6. Translocation of adults from persistent frog populations in Yosemite National Park to reestablish extirpated populations (2006-2018). This section summarizes the results from an April-2020 report submitted to Yosemite National Park ("Describing the dynamics of translocated Sierra Nevada yellow-legged frog populations in Yosemite National Park to aid future conservation efforts").

All sections (1-6) are included in a December-2020 report ("Effectiveness of actions to mitigate impacts of the amphibian chytrid fungus on mountain yellow-legged
frog populations") that was a required deliverable under U.S. Department of the Interior - National Park Service cooperative agreement number P19AC00789 (repository release = [v1](https://github.com/SNARL1/bd-mitigation-report/releases)). 
Sections 1-3 are included in Knapp et al. (2022) (releases [v2](https://github.com/SNARL1/bd-mitigation-report/releases) and [v3](https://github.com/SNARL1/bd-mitigation-report/releases)). 

All raw data used in the analyses are in the `data` directory (see `README` file in that directory for details).
All R code to analyze the data are in the `R` directory. 
Stan code used to fit the LeConte multi-state model is in the `stan` directory.
All R code and bibliography files to create the report/manuscript are in the `report` directory.

## License
Manuscript: [CC-BY-4.0](http://creativecommons.org/licenses/by/4.0/)

Code: [MIT](https://choosealicense.com/licenses/mit/) | year: 2022, copyright holder: Roland Knapp

Data: [CC0 1.0](https://creativecommons.org/publicdomain/zero/1.0/)

See [LICENSE](https://github.com/SNARL1/bd-mitigation-report/blob/master/LICENSE.md) file for details. 

## Installing package dependencies

You can install R package dependencies via:

```r
# install.packages("remotes")
remotes::install_deps()
```

## Docker instructions
A Docker image is an executable package of software that includes all dependencies needed to run an application (e.g., all of the code in this research compendium). The Docker image can be run (as a "container") from anywhere, including in a browser window, without requiring any changes to the local computer (e.g., software installation). To create and run the Docker image for this research compendium, follow these steps. 

1. [Clone](https://book.cds101.com/using-rstudio-server-to-clone-a-github-repo-as-a-new-project.html) the bd-mitigation-report repository to your computer. 
2. Install [Docker](https://docs.docker.com/get-docker/) on your computer. 
3. Set the local working directory as the top level directory of the repository: bd-mitigation-report/
4. Build a Docker image that includes RStudio and all other dependencies (as specified in the [Dockerfile](https://github.com/SNARL1/bd-mitigation-report/blob/master/Dockerfile)): 

```
docker build -t bd-mitigation-report .
```

5. Start a Docker container using the image built in step 4: 

```
docker run -e PASSWORD=yourpasswordhere --rm -p 8787:8787 bd-mitigation-report
```
"yourpasswordhere" is a password of your choice that will be used to access the container's RStudio server (step 6). 

6. Connect to the container's RStudio Server in a web browser at `localhost:8787`. In the login window, username = "rstudio" and password = password you specified in step 5. 
7. In RStudio Server, create a new project and clone the repository into it, as in step 1. In the localhost browser window, you are now able to run any of the code in the repository without having to install the dependencies. 
8. When done working with the repository in the browser window, log out of RStudio Server (File > Log Out). Close the Docker container running in Terminal with `ctrl-c`. 
9. The next time you want to work with the containerized repository using RStudio Server, repeat steps 5-8. 

## Contact
Roland Knapp, Research Biologist, University of California Sierra Nevada Aquatic Research Laboratory, Mammoth Lakes, CA 93546 USA; rolandknapp(at)ucsb.edu, <https://mountainlakesresearch.com/roland-knapp/>.
