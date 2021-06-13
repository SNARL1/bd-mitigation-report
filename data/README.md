# Data from: Effectiveness of antifungal treatments during chytridiomycosis epizootics in populations of an endangered frog

*Roland A. Knapp, Maxwell B. Joseph, Thomas C. Smith, et al.*

This repository contains datasets collected during six antifungal treatments conducted in an effort to improve the probability of mountain yellow-legged frog populations persisting following epizootics caused by the amphibian chytrid fungus *Batrachochytrium dendrobatidis* (Bd). 
These datasets are associated with the manuscript **Effectiveness of antifungal treatments during chytridiomycosis epizootics in populations of an endangered frog**. 
All treatments except that in Treasure Lakes Basin were conducted as experiments, with frogs assigned to treated and untreated control groups. 
All of the raw data are tabular, in comma separated value (CSV) format. 
Missing values in all files are coded as NA. 

### Itraconazole treatments of early life stages (Dusy and Barrett Lakes Basins)

#### dusybarrett-20092010-captures.csv

This CSV file contains data collected from tadpoles and subadults during the itraconazole treatment experiments in Barrett Lakes Basin and Dusy Basin. 

Fields: 

- `site`: 5-digit site identification code.
- `basin`: Lake basin in which the treatment was conducted (Barrett, Dusy).
- `visit_date`: Date on which the record was collected (YYYY-MM-DD).
- `date_label`: Date categories identifying records as collected prior to, during, or after the treatment.
- `treatment`: Frog treatment category (treated, control).
- `survey_type`: Survey type during which record was collected (swab).
- `species`: Frog species code (ramu).
- `stage`: Frog life stage (tadpole, subadult).
- `capture_animal_state`: Animal state at the time of capture (healthy, sick). 
- `tad_stage`: Gosner stage of tadpole.
- `swab_id`: 8-digit swab identification code.
- `bd_load`: Number of Bd ITS copies on swab.
- `year_std`: Year in which survey was conducted standardized relative to the year in which the treatment was conducted (0, 1).
- `num_days`: Number of days since the start of the itraconazole treatment period. 

#### dusybarrett-20092010-counts.csv

This CSV file contains frog count data collected during visual encounter surveys (VES) at the study ponds in Barrett Lakes Basin and Dusy Basin following the itraconazole treatments. 

Fields

- `site`: 5-digit site identification code.
- `basin`: Lake basin in which the treatment was conducted (Barrett, Dusy).
- `treatment`: Frog treatment category (treated, control).
- `visit_date`: Date on which VES was conducted (YYYY-MM-DD).
- `plot_date`: Date for plotting purposes, slightly revised from `visit_date` to combine adjacent dates.
- `year_std`: Year in which VES was conducted standardized relative to the year in which the treatment was conducted (0, 1).
- `tadpole`: Number of tadpoles counted during VES.
- `subadult`: Number of subadults counted during VES.

#### dusy-2010-zsppool.csv

This CSV file contains data on water samples collected from the Dusy Basin study ponds before and after itraconazole treatment to estimate the size of the zoospore pools.

Fields

- `sample_id`: Water sample identification code. 
- `plate_id`: Identification code for PCR plate on which sample was run. 
- `site_id`: 5-digit site identification code.
- `pre_post`: Sampling period descriptor, relative to treatment (pre, post)
- `tmt`: Frog treatment category (treated, control).
- `replicate`: PCR replicate number.
- `bd_load`: Number of Bd ITS copies on filter, normalized to a 1-liter sample volume.

### Itraconazole treatment of adults (LeConte and Treasure Basins)

#### leconte-20152018-captures.csv

This CSV file contains data collected from adult frogs during itraconazole treatment experiments conducted in LeConte Basin.

Fields

- `site_id`: 5-digit site identification code.
- `location`: Location within LeConte Basin where treatment experiment was conducted (lower, upper).
- `visit_date`: Date on which the record was collected (YYYY-MM-DD).
- `trt_period`: Categories to identify records collected immediately before and at end of treatment period (pretreat, endtreat).
- `category`: Frog treatment category (treated, control).
- `trt_died`: Categories to identify frogs that died during the treatment period, or survived (TRUE, FALSE). 
- `pit_tag_ref`: Unique identifier associated with an individual's passive integrated transponder (PIT) tag.
- `tag_new`: Categories to indicate whether a tag was inserted into an untagged frog, or whether a frog was already tagged (TRUE, FALSE). 
- `length`: Snout-vent length, in millimeters.
- `swab_id`: 8-digit swab identification code.
- `bd_load`: Number of Bd ITS copies on swab.

#### leconte-20152018-surveys.csv

This CSV file contains data on the initial frog capture surveys and subsequent capture-mark-recapture (CMR) surveys conducted as part of the LeConte Basin treatment experiments. 

Fields

- `visit_date`: Date on which the survey was conducted (YYYY-MM-DD).
- `location`: Location within LeConte Basin where treatment experiment was conducted (lower, upper).
- `category`: Type of survey (capture, cmr).
- `primary_period`: Identifier for the site visit. Added by `leconte-cmr-model.R` during analysis of CMR data. 
- `secondary_period`: Identifier for the survey within a site visit. Added by `leconte-cmr-model.R` during analysis of CMR data.  

#### treasure-captures-swabs.csv

This CSV file contains data on adult frogs before, during, and after the itraconazole treatment conducted in Treasure Basin.

Fields

- `site_id`: 5-digit site identification code.
- `visit_date`: Date on which the record was collected (YYYY-MM-DD).
- `survey_type`: Type of survey (swab, cmr).
- `survey_treatment`: Categories indicating whether record was collected during the treatment period or before/after the treatment period (Survey, Treatment).
- `species`: Frog species code (ramu).
- `capture_life_stage`: Frog life stage (adult).
- `capture_animal_state`: Animal state at the time of capture (healthy, sick). 
- `pit_tag_ref`: Unique identifier associated with an individual's PIT tag.
- `tag_new`: Categories to indicate whether a tag was inserted into an untagged frog, or whether a frog was already tagged (TRUE, FALSE). 
- `sex`: Sex of animal.
- `length`: Snout-vent length, in millimeters.
- `weight`: Weight, in grams. 
- `swab_id`: 8-digit swab identification code.
- `replicate`: PCR replicate number.
- `bd_load`: Number of Bd ITS copies on swab.

#### treasure-Bd-4.csv

This CSV file contains data on the effectiveness of itraconazole treatment as a function of the number of daily treatments that a frog received. 

Fields

- `pit_tag_ref`: Unique identifier associated with an individual's PIT tag.
- `capture_swab`: Bd load (number of Bd ITS copies on swab) prior to treatment. 
- `release_swab`: Bd load (number of Bd ITS copies on swab) when released.
- `recapture_swab`: Bd load (number of Bd ITS copies on swab) when recaptured during subsequent CMR surveys.
- `days_inside`: Number of days frog spent in pen during the treatment period, which is equivalent to the number of daily itraconazole treatments received. 
- `LRR`: Log-response ratio, indicating treatment effectiveness, calculated as the negative log ratio of pre-treatment to post-treatment Bd loads.
- `capture_swab_std`: Bd load prior to treatment standardized to mean = 0 and standard deviation = 1.

### Microbiome augmentation of subadults (Dusy Basin)

#### dusy-2012-swabs.csv

This CSV file contains data collected from subadults during the experiment in Dusy Basin in which the frog microbiome was augmented with the probiotic bacterium *Janthinobacterium lividum*. 

Fields

- `site_id`: 5-digit site identification code.
- `visit_date`: Date on which the record was collected (YYYY-MM-DD).
- `group_date`: Identical to `visit_date` for this data subset.
- `capture_stage`: Frog life stage (subadult).
- `toe_clip1`: Code indicating whether the second toe on the left or right front foot was clipped (L2 = control, R2 = treated).
- `swab_id`: 8-digit swab identification code.
- `bd_load`: Number of Bd ITS copies on swab.
- `jliv_ge`: Number of *J. lividum* genomic equivalents on swab. 
- `expt_or_wild`: Category indicating whether frog was included in the experiment or was a non-experimental animal (expt, wild).
- `expt_trt`: Frog treatment category (treated, control). 
- `trt_stage`: Frog life stage during pre-*J. lividum* itraconazole treatment. 
