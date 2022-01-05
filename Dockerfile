FROM rocker/tidyverse

USER root

RUN apt-get update \
  && apt-get install -y --no-install-recommends \
  libglpk40

RUN apt-get install \
  && apt-get install -y --no-install-recommends \
  libxt6
  
USER rstudio

WORKDIR /home/rstudio

COPY DESCRIPTION DESCRIPTION

RUN R -e "getwd()"

RUN R -e "devtools::install_deps()"

USER root
