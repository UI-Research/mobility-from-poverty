---
name: Moibility Metric Update Issue Template (TEST)
about: This template was designed as the default issue for updating and/or changing
  mobility metrics.
title: iss###
labels: ''
assignees: ''

---

## Metric update issue

This issue updates the \[enter mobility metric\]. Please read through the instructions below carefully. The check at the bottom of this issue should all be completed and marked off prior to creating a final PR for the metric update.

Please review the instructions on the wiki before starting work on a metric update.

### Crosswalks

Crosswalks were updated at the start of the 2024-25 metric update process. If you are editing an existing program please check that the crosswalk being used is the latest version. For more information on crosswalks, see the crosswalk page on the wiki.

### Historical Data

If you are changing the methodology for a metric or adding a new subgroup, consider how this will impact prior years of the metric and if the time series will be coherent. Please see the section on historical data and years page on the wiki.

Please define the updates and/or changes being made as specifically as possible below:

### Checklist

*Code Reproducibility & Content*

-   [ ] All relevant code used to create this metric run start to finish without bugs or errors
-   [ ] The program includes thorough comments explaining all steps
-   [ ] All raw data that can be read into the code programmatically (i.e. via an API or web scraping) is done in the code
-   [ ] Any raw data used that cannot be read in programmatically is stored in the following (Box folder)\[[https://urbanorg.box.com/s/gpqd26sk5kqlymnfngyvjfs4qf9o2zvc\]](https://urbanorg.box.com/s/gpqd26sk5kqlymnfngyvjfs4qf9o2zvc])

*Back-updating*

-   [ ] If this update made substantive changes to the methodology of a metric the prior years of data were also reproduced or an alternative solution was found
-   [ ] Any additional subgroups were included in previous years made available for the metric

*Final Data*

-   [ ] If this update changed the years, subgroup names or added new subgroups a completed/updated final data expectation form was completed
-   [ ] The final data went through the “Final Data Evaluation Function” and passed all tests
-   [ ] The final data includes all years and subgroups available/created for the metric. And if not, the final data folder includes historical versions that match the structure of the updated final files

*Review*

-   [ ] This code received a review from an approved reviewer
-   [ ] All comments and concerns raised by the reviewer have been addressed
