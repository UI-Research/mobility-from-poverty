---
name: Mobility Metric Update Issue Template
about: This template was designed as the default issue for updating and/or changing
  mobility metrics.
title: Metric Update Description
labels: ''
assignees: ''
---

## Metric Update

This issue updates the $$enter mobility metric$$. Please read through the instructions below carefully. The check at the bottom of this issue should all be completed and marked off prior to creating a final PR for the metric update.

Please review the instructions on the wiki before starting work on a metric update.

### Update Goals

-   [ ]
-   [ ]
-   [ ]

### Geographic files

Target geographic files and geographic crosswalks were updated prior to the 2025-26 metric update process. If you are editing an existing program please check that the crosswalk being used is the latest version. For more information on crosswalks, see the crosswalk page on the Wiki.

### Historical Data

If you are changing the methodology for a metric or adding a new subgroup, consider how this will impact prior years of the metric and if the time series will be coherent. Please see the section on historical data and years page on the wiki.

Please define the updates and/or changes being made as specifically as possible below:

### Checklist

The checklist below outlines key steps that should be taken during the process of this metric update. These steps should all be checked off prior to finalizing the metric update.

*Setup*

-   [ ] Metric lead has checked out a new branch from the `version2026` branch that is named after the number associated with this issue, i.e. `iss###`
-   [ ] Metric lead has reviewed the specifications file and the values specific to their metric

*Program Documentation*

-   [ ] Each step taken in the calculation is clearly documented in the code
-   [ ] The program is broken out into manageable steps and the code avoids using extensively long lines connected via pipes or pipe equivalents if not using R

*Reproducibility*

-   [ ] All relevant code used to create this metric run start to finish without bugs or errors
-   [ ] The program includes thorough comments explaining all steps
-   [ ] The program avoids hardcoding local file paths and instead uses global paths that will work regardless of where the program is being ran (i.e. here::here() for R users)
-   [ ] The program includes a “House Keeping” section which loads all necessary packages at the top of the program
-   [ ] All raw data that can be read into the code programmatically (i.e. via an API or web scraping) is done in the code
-   [ ] Any raw data used that cannot be read in programmatically is stored in the following (Box folder)

*Quality Control*

-   [ ] The program includes visuals of the distribution of key analysis variables throughout the calculation steps
-   [ ] The program includes visualizations of the final data as well as summary statistic and a selection of assumptions tests (including count of rows by year, missing values and calculation of outliers (min & max) plus any additional checks deemed necessary)
-   [ ] Assumption tests are applied to all years being created in the program. If a year in the historical version of the metric data is not being recreated in this program, that historical data is read in and differences with new years are visualized.
-   [ ] The program includes the creation of a quality variable for the metric and documents the method for assigning quality grades
-   [ ] The final data pass evaluation checks

*Back-updating*

-   [ ] If this update made substantive changes to the methodology of a metric the prior years of data were also reproduced or an alternative solution was found
-   [ ] Any additional subgroups were included in previous years made available for the metric

*Final Data*

-   [ ] The program reads out a final file in the form of a CSV document or multiple CSVs into a data folder in the relevant metric folder
-   [ ] Final files include the relevant years in title if the metric has multiple files separated by year
-   [ ] All final files being read out by the update program are put through the evaluate final data function

*Review*

-   [ ] When ready for review the metric lead has submitted a PR to `version2026` using the PR template
-   [ ] This code received a review from an approved reviewer
-   [ ] All comments and concerns raised by the reviewer have been addressed
