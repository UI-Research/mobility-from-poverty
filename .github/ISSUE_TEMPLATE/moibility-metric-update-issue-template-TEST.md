---
name: Moibility Metric Update Issue Template
about: This template was designed as the default issue for updating and/or changing
  mobility metrics.
title: Metric Update Description
labels: ''
assignees: ''

---

## Metric Update

This issue updates the \[enter mobility metric\]. Please read through the instructions below carefully. The check at the bottom of this issue should all be completed and marked off prior to creating a final PR for the metric update.

[Enter update goals - column F from the UMF_Update_Tracker]


Please review the instructions on the wiki before starting work on a metric update.

### Crosswalks

Crosswalks were updated prior to the 2024-25 metric update process. If you are editing an existing program please check that the crosswalk being used is the latest version. For more information on crosswalks, see the crosswalk page on the Wiki.

### Checklist

The checklist below outlines key steps that should be taken during the process of this metric update. These steps should all be checked off prior to finalizing the metric update.

*Setup*
-   [ ] Metric lead has checked out a new branch from the Version2025 repo that is named after the number associated with this issue, i.e. iss###
-   [ ] Metric lead has filled out the final data expectations from located in the functions folder of the repo and saved this form in the metrics data folder for all relevant final output files 
-   [ ] Metric lead has read through the existing version of the program and has located and overviewed the existing output files  

*Program Documentation* 
-   [ ] The update program includes a description at the start with the date, the latest changes made and the author of the metric lead that made them
-   [ ] If the program reads in raw data that is not available through an API, then the code includes a note on where this data is in Box (including the title of relevant files) 
-   [ ] Each step taken in the calculation is clearly documented in the code using comments 
-   [ ] The program is broken out into manageable steps and the code avoids using extensively long lines connected via pipes or pipe equivalents if not using R

*Quality Control*
-   [ ] The program includes visuals of the distribution of key analysis variables throughout the calculation steps
-   [ ] The program includes visualizations of the final data as well as summary statistic and a selection of assumptions tests (including count of rows by year, missing values, etc.)
-   [ ] The program includes the creation of a quality variable for the metric and documents the method for assigning quality grades 

*Reproducibility* 
-   [ ] The program runs from start to finish without stopping due to errors or incompleteness 
-   [ ] The program avoids hardcoding local file paths and instead uses global paths that will work regardless of where the program is being ran (i.e. here::here() for R users)
-   [ ] The program includes a “House Keeping” section which loads all necessary packages at the top of the program

*Final Data*
-   [ ] The program reads out a final file in the form of a CSV document or multiple CSVs into a data folder in the relevant metric folder
-   [ ] Final files include the relevant years in title if the metric has multiple files separated by year
-   [ ] All final files being read out by the update program are put through the evaluate final data function 

*Review*
-   [ ] When ready for review the metric lead has submitted a PR to Version2025 using the PR template 
