# Mitigating the effects of the amphibian chytrid fungus

## Authors of this repository
Roland A. Knapp [![ORCiD](https://img.shields.io/badge/ORCiD-0000--0002--1954--2745-green.svg)](http://orcid.org/0000-0002-1954-2745)

Maxwell B. Joseph [![ORCiD](https://img.shields.io/badge/ORCiD-0000--0002--7745--9990-green.svg)](http://orcid.org/0000-0002-7745-9990)

Thomas C. Smith [![ORCiD](https://img.shields.io/badge/ORCiD-0000--0001--7908--438X-green.svg)](http://orcid.org/0000-0001-7908-438X)

## Overview of contents
This repository is a research compendium for a decade-long effort to mitigate the effects of the amphibian chytrid fungus *Batrachochytrium dendrobatidis* ("Bd") on populations of the endangered [mountain yellow-legged frog](https://bit.ly/conservationstrategy). 
These mitigation efforts were conducted in the southern Sierra Nevada mountains (California, USA) during the period 2006-2018. 
This research culminated in the publication of a peer-reviewed paper entitled, "Effectiveness of antifungal treatments during chytridiomycosis epizootics in populations of an endangered frog" ([Knapp et al. 2022](https://doi.org/10.7717/peerj.12712)). 

The repository contains data, code to analyze treatment outcomes, and a report/manuscript describing the results of Bd mitigation efforts. 
These efforts included the following:
1. Treatment of young life stage frogs with the antifungal drug, itraconazole, in Kings Canyon National Park (Barrett Lakes Basin - 2009, Dusy Basin - 2010).
2. Treatment of adults with itraconazole in LeConte Canyon (Kings Canyon National Park - 2015) and Treasure Lakes (Inyo National Forest - 2018).
3. Treatment of metamorphs with the commensal antifungal bacterium *Janthinobacterium lividum* in Kings Canyon National Park (Dusy Basin - 2012).
4. Reintroduction of Bd-naive adults to several sites in the South Fork Kings River watershed of Kings Canyon National Park (Upper, Ruskin, and Pinchot Basins) in 2013.
5. Reintroduction of adults from declining frog populations to several sites in Sequoia National Park (Tyndall and Milestone basins) and Kings Canyon National Park (Pinchot and Sixty Lake basins) during 2016-2018.
6. Translocation of adults from persistent frog populations in Yosemite National Park to reestablish extirpated populations (2006-2018). This section summarizes the results from an April-2020 report submitted to Yosemite National Park ("Describing the dynamics of translocated Sierra Nevada yellow-legged frog populations in Yosemite National Park to aid future conservation efforts").

All sections (1-6) are included in a December-2020 report ("Effectiveness of actions to mitigate impacts of the amphibian chytrid fungus on mountain yellow-legged
frog populations") that was a required deliverable under U.S. Department of the Interior - National Park Service cooperative agreement number P19AC00789 (repository release = [v1.0](https://github.com/SNARL1/bd-mitigation-report/releases)). 
Sections 1-3 are included in [Knapp et al. (2022)](https://doi.org/10.7717/peerj.12712) (releases [v2.0](https://github.com/SNARL1/bd-mitigation-report/releases) and [v3.0](https://github.com/SNARL1/bd-mitigation-report/releases)). 

All raw data used in the analyses are in the `data` directory (see `README` file in that directory for details).
All R code to analyze the data are in the `R` directory. 
Stan code used to fit the LeConte multi-state model is in the `stan` directory.
All R code and bibliography files to create the report/manuscript are in the `report` directory.

## License
Manuscript: [CC-BY-4.0](http://creativecommons.org/licenses/by/4.0/)

Code: [MIT](https://choosealicense.com/licenses/mit/) | year: 2022, copyright holder: Roland Knapp

Data: [CC0 1.0](https://creativecommons.org/publicdomain/zero/1.0/)

See [LICENSE](https://github.com/SNARL1/bd-mitigation-report/blob/master/LICENSE.md) file for details. 

## About the data

See the README file in the data directory (data/README.md) for a description of each data file.

## Reproducing the analyses

### Hardware requirements

Most of the `xxxxx_analysis_mrmr.Rmd` files can be run on a computer with 32 GB of RAM and at least four physical CPU cores. 
The exception is `70550_analysis_mrmr.Rmd` that, due to the large number of frogs included in the associated datasets, requires at least 128 GB of RAM. 

### Software requirements

We ran the analyses using R and the R packages listed in the DESCRIPTION file. 
All of the packages are available via the CRAN repository except [cmdstanr](https://mc-stan.org/cmdstanr/#installation) and [mrmr](https://snarl1.github.io/mrmr/index.html). 
An installation of [cmdstan](https://mc-stan.org/cmdstanr/#installation) is also required. 

We used the following R version and OS: 
* [R](https://www.r-project.org/) version 4.0.5 (2021-03-31) 
* Platform: x86_64-pc-linux-gnu (64-bit) 
* Running under: Ubuntu 20.04.3 LTS

### Docker instructiuons

As an alternative to a local installation, the software requirements have been wrapped in a Docker image (see Dockerfile for source code). 
To run and use the Docker container, follow these steps: 
1. [Install Docker](https://docs.docker.com/get-docker/), if not already installed.  
2. Start the Docker container for the bd-mitigation-report project (Linux users will need to preface the command with `sudo`):  

```bash
docker run -e PASSWORD=yourpasswordhere --rm -p 8787:8787 rolandknapp/bd-mitigation-report
```

This will launch an RStudio server on port 8787. 
"yourpasswordhere" is a password of your choice that will be used to access the RStudio server (step 3).  

3. Navigate to http://localhost:8787/. In the login window, username = "rstudio" and password = password you specified in step 2.
4. In the RStudio server, [create a new project and clone the bd-mitigation-report repository into it](https://book.cds101.com/using-rstudio-server-to-clone-a-github-repo-as-a-new-project.html). 
You are now able to run any of the code in the repository - all of the dependencies are already installed.  
5. When done working with the repository in the browser window, log out of the RStudio server (File > Sign Out).
Close the Docker container running in Terminal with `ctrl-c`. If there are any files from your work in the container that you want to preserve (e.g., plots), save them to your local computer.
Any unsaved files will be lost when the container is closed.  

## Acknowledgements
Many people contributed to this project over its 10+ year lifespan. 
These include summer field assistants, research colleagues, and collaborators in the National Park Service, U.S. Fish and Wildlife Service, California Department of Fish and Wildlife, and U.S. Forest Service. 
Thanks to all of you for your contributions that made this project possible. 
For a list of people who made particularly important contributions, in [Knapp et al. (2022)](https://doi.org/10.7717/peerj.12712) see the list of authors and the Acknowledgements section. 
Funding for this project was provided by the National Park Service, National Science Foundation, and National Institutes of Health. Additional funding details are provided in the "Funding" section of [Knapp et al. (2022)](https://doi.org/10.7717/peerj.12712). 

## Contact
Roland Knapp, Research Biologist, University of California Sierra Nevada Aquatic Research Laboratory, Mammoth Lakes, CA 93546 USA; rolandknapp(at)ucsb.edu, <https://mountainlakesresearch.com/roland-knapp/>.
