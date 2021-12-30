FROM rocker/tidyverse

USER rstudio

WORKDIR /home/rstudio

COPY DESCRIPTION DESCRIPTION

RUN R -e "getwd()"

RUN R -e "devtools::install_deps()"

USER root
