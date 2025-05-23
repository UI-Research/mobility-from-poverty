# Boosting Upward Mobility from Poverty

This repository contains code to construct 26 metrics for 25 predictors of mobility across 5 pillars that broadly measure mobility from poverty.
The data are available for 3,143 counties (example: [Los Angeles County](https://upward-mobility.urban.org/sites/default/files/mobility-metrics-data-pages/999_county-pages/06037/index.html)) and 486 selected cities (example: [Philadelphia](https://upward-mobility.urban.org/sites/default/files/mobility-metrics-data-pages/998_place-pages/4260000/index.html)).

To learn more about the upward mobility framework, please read:

-   [Project website](https://upward-mobility.urban.org/)
-   [Boosting Upward Mobility: Metrics to Inform Local Action (2nd Edition)](https://www.urban.org/research/publication/boosting-upward-mobility-metrics-inform-local-action-second-edition)
-   [Boosting Upward Mobility: Metrics to Inform Local Action Technical Report (2nd Edition)](https://www.urban.org/research/publication/boosting-upward-mobility-metrics-inform-local-action-second-edition-technical-report)

To learn more about the data, please read:

-   [Mobility metrics Urban Institute Data Catalog page](https://datacatalog.urban.org/dataset/boosting-upward-mobility-metrics-inform-local-action)
-   [Mobility metrics data dictionary](https://ui-research.github.io/mobility-from-poverty/)
-   [Mobility metrics methodological notes](https://github.com/UI-Research/mobility-from-poverty/blob/main/documentation/overview.md)

# Motivation

The objective of this repository is to make all results reproducible, to document processes and assumptions, and to make it easier for analysts to produce metrics in future years.
A little extra effort today can make a big difference in the future.
For more motivation, please read the motivation for a style guide by [Michael Stepner](https://github.com/michaelstepner/healthinequality-code/tree/master/code#motivation).
If that isn't enough, read the section on [technical debt](https://github.com/michaelstepner/healthinequality-code/blob/master/code/readme.md#technical-debt).

This guide is a work-in-progress. If there are any ambiguities or unresolved questions, please contact Aaron R. Williams. 

# Table of Contents

-   [Repository Contents](#repository-contents)
-   [File Descriptions](#file-descriptions)
    -   [Recent File](#recent-file)
    -   [Multi-Year File](#multi-year-file)
    -   [Variables](#variables)
-   [Project Organization](#project-organization)
-   [GitHub](#github)
    -   [GitHub Standards](#github-standards)
    -   [Github Basic](#github-basics)
    -   [GitHub Workflow](#github-workflow)
    -   [Working with issues](#working-with-issues)
-   [Data Standards](#data-standards)
    -   [Joining Variables](#joining-variables)
    -   [Variable Names](#variable-names)
    -   [Values](#values)
    -   [Sorting](#sorting)
    -   [Crosswalks](#crosswalks)
    -   [Standard Errors and Confidence Intervals](#standard-errors-and-confidence-intervals)
    -   [Validation](#validation)
    -   [Quality Flags](#quality-flags)
    -   [Data Dictionary](#data-dictionary)
    -   [Subgroups File Structure](#subgroups-file-structure)
    -   [File names](#file-names)
-   [Code Standards](#code-standards)
    -   [Subgroups Code](#subgroups-code)
-   [Code and technical Review](#code-and-technical-review)
    -   [Scope of the Review](#scope-of-the-review)
    -   [How to Prepare for a Code Review](#how-to-prepare-for-a-code-review)
    -   [Code Reviews in GitHub](#code-reviews-in-github)
    -   [Code Branching for Reviewers](#code-branching-for-reviewers)
-   [Creating the Final File](#creating-the-final-file)
-   [Data Dictionary](#data-dictionary)
-   [External Users](#external-users)
-   [Contact](#contact)

# Repository Contents

**Note:** The code is organized by nine domains for legacy reasons even though the [updated framework](https://upward-mobility.urban.org/mobility-metrics-framework) is organized into five pillars.
Below is a table showing each predictor by pillar, and the domain it was previously assigned to.

|            Legacy Domain            |                      Pillar                      |          Predictors                  |
|:----------------:|:-----------------------------:|:---------------------:|
|        01_financial-well-being      |                    Rewarding Work                |     Opportunities for income <br/> Financial security <br/> Wealth-building opportunities    |  
|             02_housing              |   Opportunity-Rich & Inclusive Neighborhoods     |  Housing affordability <br/>   Housing stability       |
|              03_health              | Healthy Environment & Access to Good Health Care |   Access to health services <br/> Neonatal health <br/> Safety from trauma       |
|        05_local-governments         |           Responsive & Just Governance           |    Political participation <br/> Descriptive representation          |
|          06_neighborhoods           |    Opportunity-Rich & Inclusive Neighborhoods    |      Economic inclusion <br/> Racial diversity <br/> Transportation access <br/> Environmental quality <br/> Social capital   |
|              07_safety              |           Responsive & Just Governance           |       Safety from crime <br/> Just policing              |
|            08_education             |              High-Quality Education              |      Access to preschool <br/> Effective public education <br/> School economic diversity <br/>  Preparation for college <br/> Digital access            |
|            09_employment            |                  Rewarding Work                  |   Employment opportunities <br/> Access to jobs paying a living wage         |
                                                                                             

# File Descriptions

The [all metrics combined datasets](https://datacatalog.urban.org/dataset/boosting-upward-mobility-metrics-inform-local-action-10) for this project are read out into several file formats which are described below.
The main difference is the geographic level of the data (city vs county), the number of years included and whether subgroups (i.e. race/ethnicity) are included.
The all metrics combined files are in the ["long" format](https://www.theanalysisfactor.com/wide-and-long-data/) as opposed to a "wide" format, meaning that in the files covering multiple years or subgroup each unique geography will account for more than one row.
The data are hosted publicly on the [Urban Institute data catalog](https://datacatalog.urban.org/).

## Recent Files

-   The recent county file has exactly one row per county and contains the most recent year for each of the mobility metrics.
    This file should have exactly 3,143 observations and contain missing values where metrics were unavailable, suppressed, or not computed.

    | state | county | state_name |   county_name    | Var1... |
    |:-----:|:------:|:----------:|:----------------:|:-------:|
    |  01   |  001   | "Alabama"  | "Autauga County" |         |
    |  01   |  003   | "Alabama"  | "Baldwin County" |         |
    |  01   |  005   | "Alabama"  | "Barbour County" |         |

-   The recent city file has one row per census place and contains the most recent year for each of the mobility metrics.
    This file should have exactly 486 observations and contain missing values where metrics were unavailable, suppressed, or not computed.
    Cities are defined as census places that have a population of 75,000 or greater.

## Multi-Year Files

-   The multi-year county file contains one observation per county per year.
    It contains missing values where metrics are unavailable, suppressed, or have not been computed.
    Prior to 2020 this file has 3,142 observations per year and 3,143 for the years 2020 to the most recent.

    | year | state | county | state_name |   county_name    | Var1... |
    |:----:|:-----:|:------:|:----------:|:----------------:|:-------:|
    | 2014 |  01   |  001   | "Alabama"  | "Autauga County" |         |
    | 2014 |  01   |  003   | "Alabama"  | "Baldwin County" |         |
    | 2014 |  01   |  005   | "Alabama"  | "Barbour County" |         |

-   The multi-year city file contains one observation per large city per year.
    It contains missing values where metrics are unavailable, suppressed, or have not been computed.
    This file has 486 observations per year.

## Subgroups Files

-   The subgroups county files contain multiple observations per county per year. These files are long and have multiple observations per county per year are for subgroups like race/ethnicity and poverty status.

| year | state | county | state_name |   county_name    |  subgroup_type   |           subgroup            |
|:--------:|:--------:|:--------:|:--------:|:--------:|:--------:|:-----------:|
| 2014 |  01   |  001   | "Alabama"  | "Autauga County" |      "all"       |             "All"             |
| 2014 |  01   |  001   | "Alabama"  | "Autauga County" | "race-ethnicity" |     "Black, Non-Hispanic"     |
| 2014 |  01   |  001   | "Alabama"  | "Autauga County" | "race-ethnicity" |          "Hispanic"           |
| 2014 |  01   |  001   | "Alabama"  | "Autauga County" | "race-ethnicity" | "Other Races and Ethnicities" |
| 2014 |  01   |  001   | "Alabama"  | "Autauga County" | "race-ethnicity" |     "White, Non-Hispanic"     |

-   The subgroups city files contain multiple observations per census place per year. These files are long and have multiple observations per census place per year are for subgroups like race/ethnicity and poverty status.

# Project Organization

-   Each domain should have its own directory (e.g. 01_financial-well-being, 02_housing, etc.). The name of the directory should only contain lower case letters, numbers, and hyphens. Do not include spaces.
-   The [overview documentation file](https://github.com/UI-Research/mobility-from-poverty/blob/main/documentation/overview.md) includes information about the metrics. It should contain clear instructions for running the code. It should contain a brief list of the assumptions and methodology used to create each metric.
-   Avoid absolute file paths, meaning code should never reference a folder that exists outside of this repository. If using R, use `.Rproj`. If using Stata, use projects. Otherwise, set the working directory. This ensures that the code is portable.
-   **Only add final metric data to the repository.** Each subfolder should contain a `data/` folder for intermediate data files. The `data/` folder should be added to the `.gitignore`. The final metric data should be added to GitHub.
-   If possible, download your data with code or pull your data from an API with code.
-   **Do not include any credentials in the repository.** Please reach out to Aaron R. Williams if this creates issues.
-   Use names that play well with default ordering (e.g. 01, 02 and YYYY-MM-DD dates) for directory and file names.

# GitHub 

## GitHub Standards 

-   Do not work on the `main` branch. This project uses a staging branch called `version2024` that all updates should work through as if it were the main branch. All updates should be pushed to this branch.
-   **Only add final metric data to the repository.** Each subfolder should contain a `data/` folder for intermediate data files. The `data/` folder should be added to the `.gitignore`. The final metric files should be added to GitHub.
-   Regularly pull from the remote `version2024` branch to keep your local and remote branches up-to-date. Most merges will automatically resolve. [Here](https://docs.github.com/en/github/collaborating-with-issues-and-pull-requests/resolving-a-merge-conflict-using-the-command-line) are tips for resolving other merge conflicts.
-   [GitHub issues](https://docs.github.com/en/github/managing-your-work-on-github/about-issues) exist for each metric and work branches should always be tied to an issue.

## GitHub Basics

An Urban Institute-focused introduction to GitHub including installation instructions is available [here](https://ui-research.github.io/urbngit/).

After installing Git and setting up a GitHub account, follow these steps to get started on Windows:

1.  Right click and select "Git Bash Here" where you want to copy the repository (main folder) on your computer.
2.  Submit `git clone https://github.com/UI-Research/mobility-from-poverty.git`. You will need to enter your user email and password. Everything will then copy to your computer.
3.  Close Git Bash.
4.  Enter the `gates-mobility-metrics` folder, right click, and select "Git Bash Here".
5.  Submit `git checkout -b version2024` to get to the staging branch. 
6.  This project uses an issue based branching system. When you start working on an issue you will create a branch for it using `git checkout -b <"issue name">` but replace `"issue name"` with the issue you are working on. 
7. For issues that already have branches created you can switch to them using the command `git checkout <"issue name">`

After this, you should be able to edit files and then add them to Git with the process outlined in the guide above.

## GitHub Workflow

GitHub will be used as the primary form of communication for programs and data.
The workflow will rely on GitHub Issues that will be linked to metrics work goals.
These issues will be organized and tracked using [GitHub projects](https://github.com/orgs/UI-Research/projects/4) which can be viewed on the GitHub repository.

*Note:* The GitHub repository is public and all files that are not included in the gitignore will be publicly available when pushed to the repository.

1.  Set up Git
2.  Clone the repository
3.  From the mobility-from-poverty folder you have cloned to your local computer, make sure you are on the `version2024` branch - `mobility-from-poverty` - and ensure it is up to date with GitHub:
    -   `git checkout version2024` o `git pull origin version2024`
4.  Check out a branch with the same name as the issue connected to that metric
    -   `git checkout -b <"issue name">`
5.  Additional branching is allowed but merge all changes into the branch tied to the issue.
6.  Add your changes to the code.
    -   The command `git status` shows which files have changed.

    -   `git diff <"filename">` will highlight which lines have been modified.

    -   Use the arrow keys to scroll, and press `q` if you need to exit the prompt.

    -   `git add [filename]` will stage files to commit (`git add -u` will add all modified files).

    -   `git commit -m <"your message here">` will commit changes to version control.
        Commit messages should be clear and meaningful.

    -   `git push origin <"issue branch name">` will push committed changes up to the GitHub for review.
7.  To contribute to the `main` branch, put in a Pull Request. Tag your assigned reviewer (@reviewer). Briefly describe what the PR does.
8. All code will go through a code review process with an assigned reviewer. After a successful review, the changes will be pulled into the `version2024` branch. Reviewers may ask you to make changes. **For Urban employees only, please reach out to the "umf-mobilitymetrics3" slack channel if you have questions.**

## Working with issues

Issues exist for each metric update that needs to be completed. Metric leads will be assigned to their issues using GitHub (assignments will be linked to GitHub accounts).

Note that issues will include notes on what needs to be completed outside of updating to the latest data. There are two types of recurring notes that appear on most issues:
- Renaming: There will be specific requests for renaming variables that will include the new variable names.
- Adding subgroups: There will be requests that read like "Add race or sex". These refer to adding these subgroups to the final metric data.

# Data Standards

This section will walk through the standards around data starting with the raw data used to create the metric, joining variables that need to be included in every file, data naming and sorting conventions, data quality standards and standard errors, subgroup files and file naming/final metric file standards.

### Starting or raw data practices

-   Starting or raw data should be pulled using code or should be added to Box. Only final data files should be added GitHub repository.
-   Whenever possible, programs should pull data directly from the original source, meaning raw data does not have to be downloaded manually prior to code execution for the program to work. For example, programs that rely on American Community Survey (ACS) data should write code that utilizes the [Census API](https://www.census.gov/data/developers/data-sets.html) to pull in micro data; for [R programmers] the [ipumsr package](https://developer.ipums.org/docs/v2/apiprogram/clients/) is a great tool for pulling ACS micro data from the Census API using code.
-   When it is not possible to pull data in code, please download the data raw data files into this [Box folder](https://urbanorg.app.box.com/folder/277418607770?s=gpqd26sk5kqlymnfngyvjfs4qf9o2zvc) so that it can be made universally available to all contributors on the project. Ensure that files have clear names and code is clearly commented so it is clear to other users what data is being used and where it is stored. Also, ensure that programs are written so they do not save over the starting/raw data file(s).

-   Programs should have detailed commentary on where the data is being pulled from and any specifics around accessing it (where to go, what to select, etc.) regardless of whether it is downloaded in the code or on to Box.

## Joining variables

-   The first three variables in every file should be `year`, `state`, and `county`/`place`. `year` should be a four digit numeric variable.

    -   `state` should be a two characters FIPS code.

    -   `county` should be a three character FIPS code.

    -   `place` should the 5-digit census place FIPS.
        Intermediate files at the tract-level should include `tract` as the fourth variable.

    -   `tract` should be a six character FIPS code.
        All geography variables should have leading zeros for ids beginning in zeros.

#### Subgroups Specific Variables

The all metrics combined subgroup datasets will contain a subset of metrics from the original/years dataset because not all metrics will be extended for subgroup analysis.

The only variables in the subgroup datasets that will not be in the aggregate datasets will be `subgroup_type` and `subgroup`.

`subgroup_type` will be the broader category that the descriptive variable the data is being broken out by falls into, for example `race-ethnicity`

`subgroup` will be the name of the specific subgroup. These may differ some across metrics so we will need to converge on the appropriate names. The table below shows the current list of subgroup types and subgroup values, if your metric has subgroup data the values should match the names in the table below.

| subgroup category | subgroup_type (variable name) | subgroup | 
|:--------:|:--------:|:--------:|
| Race and ethnicity | race-ethnicity | All Black, Non-Hispanic <br/> Hispanic <br/> Other Races and Ethnicities <br/> White, Non-Hispanic | 
| Race | race-ethnicity |  All <br/> Black <br/> Hispanic <br/> Other Races and Ethnicities <br/> White | 
| Race share | race-share | All <br/> Majority Non-White <br/> Majority White, Non-Hispanic <br/> Mixed Race and Ethnicity| 
| Income | income | All <br/> Low Income <br/> Not Low-Income | 

**If you are an Urban employee and believe that the values of the subgroup do not align with the table above please reach out to the umf-mobilitymetrics3 slack channel for guidance.**

### Variable Names

In addition to the prescribed variable names (year, state, county, place, subgroup_type, and subgroup) each dataset will also have (a) variable(s) specific to the metric.

In previous rounds of this work, we renamed variables for metrics when building the database so the names are consistent and descriptive.
All names start with the following:

-   shares prefixed with `share_`: For example, the variable showing the share with debt in collections is titled `share_debt_col`
-   percentiles prefixed with `pctl_`: For example, the variable showing the 20th percentile of income is titled `pctl_income_20`
-   rates prefixed with `rate_`: For example, the variable showing the reported violent crimes per 100,000 people is titled `rate_violent_crime`
-   counts prefixed with `count_`: For example, the variable showing the number of public-school children who are ever homeless during the school year is titled `count_homeless`
-   index prefixed with `index_` : For example, the variable showing the air quality index is titled `index_air_quality`

Moving forward, please use these standardized variable names in the program for each of your assigned metrics. Variable names should only include lower case letters, numbers, and underscores (lower camel case, i.e. camel_case).

### Values

-   Missing values should be coded as empty cells.
-   FIPS codes should always contain leading zeros so that state codes are two digits, county codes are three digits, and place codes are five digits.

Values for subgroups will depend on data availability and prioritization.
For race, the objective is to pull "Black, Non-Hispanic", "Hispanic", "Other Races and Ethnicities", and "White, Non-Hispanic." If a subgroup lacks the precision to be responsibly reported, then report an `NA` and set the data quality to `NA`.
Try to not combine groups such as "Other Races and Ethnicities" with "White, Non-Hispanic".

### Sorting

-   All files should be sorted by `year`, `state`, and `county`/`place`, the first three variables in every file. Files at different geographic levels should be sorted by `year` and then in order by largest geographic level (i.e. state) to smallest geographic level (i.e. Census block).
-   Subgroup files should be sorted by `year`, `state`, `county`/`place`, `subgroup_type`, and `subgroup`. All sorting should be alphanumeric. Importantly, the race/ethnicity groups should be sorted alphabetically so that "Black, Non-Hispanic" appears first and "White, Non-Hispanic" appears last.

### Crosswalks

- The project repository contains crosswalk files for matching geographies between years and from data that is available at different levels then county and place. If your code performs a crosswalk it should be using the files provided in this folder.
- Crosswalk joins should join the metric data onto the crosswalk (for example, with a `leftjoin` in R you should have the crosswalk be the X variable). This ensures that the geographies included in the data are consistent across metrics (it is okay if your metric data is missing certain geographies). 

### Subgroups File Structure

A new database with one observation per subgroup per county per year, so that metric values for subgroups are rows.
This database will be in a long format and contain the "all" group.
For example, if there are four subgroups then there should be 3,143x4 + 3,143x1 = 15,715 observations per year.
This may seem foreign to some Stata and SAS programmers but it has several advantages.

1.  It limits the challenges in standardization of naming conventions and the number of variables. For example, imagine adding four subgroups in a wide format. This would mean adding four variables, four lower bounds, four upper bounds, and four quality metrics. In addition to being unwieldy, it would result in burdensome variable names (e.g. \`share_debt_coll_nonhispanic_white_quality1).
2.  This format is [tidy](https://www.jstatsoft.org/article/view/v059i10) (Wickham, 2014) and has many appealing features for data analysis.
3.  The format works best for the Mobility Metrics Data Tables. For R programmers, creating long versions of the data using the pivot_longer function.

### Data Quality Flags

-   All files should include data quality flags.
-   Construct a "quality" flag for each constructed metric. Include it as a variable with the suffix `_quality`. For example, the variable showing the air quality index is titled `index_air_quality`.
-   All observations should receive one of the following three grades or a missing value.

| Score | Description                                                                                                                                                                                                                                                       |
|-----------|------------------------------------------------------------|
| 1     | The calculated metric for the observation is high-quality and there are no substantial concerns with measurement error, missingness, sample size, or precision.                                                                                                   |
| 2     | There are issues with the calculated metric for the observation but the issues are limited. It is OK for a community partner to look at the metric.                                                                                                               |
| 3     | There are serious issues with the calculated metric for the observation. It is possible to calculate the metric but there are critical issues with measurement error, missingness, sample size, and/or precision. A community should not act on this information. |
|       | It was not possible to calculate a metric for the county or city.                                                                                                                                                                                                 |

-   Describe how you determined the grades in your methodology description. For example, observations with more than 20% missing values received a score of `3`.

### Standard Errors and Confidence Intervals

-   If possible, construct 95 percent confidence intervals for metrics.
-   Add confidence bounds as columns in the `.csv` files. The variables should have the suffixes `_lb` for lower bound and `_ub` for upper bound.
-   Do not include the `_lb` and `_ub` if a 95 percent confidence interval calculation isn't possible.

### Validation

- Include data visualizations (e.g. histograms or scatterplots) and six-number summaries (min, 25th percentile, median, mean, 75th percentile, max) to explore the distribution of calculated metrics. Ensure that values make sense (e.g. median income should not be $8 million).
- If possible, compare calculated values against external data sources. This is useful for intermediate steps (e.g. does the number of votes in a state match published totals?) and final metrics (e.g. does median household income in California align with Census Bureau estimates?)

### File Names

1.  Final metric files should have descriptive names related to the metric and must only include lower case letters, numbers, and underscores (lower camel case, i.e. camel_case).
    Do not use spaces.It is up to you how to name the files for your metric but the file names need to be consistent (meaning you should refer to the metric in the file name the same way every time) and should be concise.

    -   For example, the 2022 county metric file for the share of low-weight births metric, which fall under the Neonatal Health predictor, could be named "lwb_metric_2022_county.csv"
  

2.  Save data in a folder titled "final" to keep the repository organized.
    When saving files, include the year, geography (county or place), and subgroup information in the file name unless the file is combined (e.g. the file contains multiple years).

    -   For combined files, replace the year with "all". Continuing with the low-weight birth example, to be consistent with the name above the combined place level file  would be named "lwb_metric_all_place.csv" 
    - For subgroup data, a combined county file with subgroup data would be titled "lwb_metric_all_subgroups_plce.csv"

### Final Metric Files

-   All final files should be in the `.csv` format. The files should be delimited with a comma.
-   Do not open and save any `.csv` files in Microsoft Excel. Excel defaults lead to analytic errors.
-   Final metric files should have a row for all geographies that are included in the all files combined dataset 
       -   For county files with 2020 data and onward this will be 3,143 observations.
       -   For place files this will be 486 observations.

# Code Standards

-   The [tidyverse style guide](https://style.tidyverse.org/) was written for R but contains lots of good language-agnostic suggestions for programming. 

-   The top of each script should clearly label the purpose of the script. Here is an example Stata header:

<!-- -->

    /*************************/
    Programmer: [your name]
    Date created: [date]
    Date of last revision: [date]
    Ancestor Program: [Path to the program including the name of the program]
    original data: [Path of where the data live]
    Description: [Overall description]
    (1)[insert task description here, and then copy & paste this to indicate where that task is later in your program]
    (2)
    (3) [etc...]
    */
    /*************************/

*Scripts should be clearly organized so others can follow them.*

#### Commenting

*Include comments throughout your scripts so others can follow your work and decisions.* Include comments that state "why", not "what".
Include comments for all assumptions.

#### Naming & Dates

Use descriptive names for all variables, datasets, functions, and macros.
*Avoid abbreviations.* Use ISO 8601 dates (YYYY-MM-DD).

#### Assertions and Tests

Write assertions and in-line tests.
Assertions, things expected to always be true about the code, should be tested in-line.
[healthinequality-code](https://github.com/michaelstepner/healthinequality-code/blob/master/code/readme.md#assert-what-youre-expecting-to-be-true) offers some good background.
`assert` is useful in Stata and `stopifnot()` is useful in R.

Write tests for final files.
For example, write a test if all numbers should be non-negative or if values should not exceed \$3,000.

Check that the value ranges make sense.
Spot-check your outliers to confirm that those values are not an error.
In some cases, you might need to dig on the internet to see if say a community has the worst rates of air quality that there's some verification of that.
Or if homelessness among students spiked that there's some context that could explain that.
If not, then check your code to make sure it is doing what you think it is doing.

Also, check the data quality flag.
Look at the distribution of assigned quality.

Write tests for macros and functions to ensure appropriate behavior.

> Whenever you are tempted to type something into a print statement or a debugger expression, write it as a test instead.
> --- Martin Fowler

#### Benchmarking

Check final calculations against state and/or national numbers if available.

For questions about code, please contact [upwardmobility\@urban.org](mailto:upwardmobility@urban.org) and include "Code in GitHub" in the subject line.

## Subgroups Code 

Metric leads will need to decide whether to create new scripts/programs for extending the database (additional years or subgroup analysis) or to extend existing scripts.
The optimal approach may differ based on the situation.
For example, some metric leads will need to change datasets entirely (e.g. 1-year vs. 5-year ACS data) and new scripts may be most efficient and clean, while other metric leads may need to make minimal changes to an existing script.

1.  Do not worry about editing existing scripts provided they recreate the original dataset. There is no need to use version control in file names (i.e. script.R to script2.R). Git will handle this. If you have not added your data as a .csv to version control, then please reach out to Aaron (this is a change from earlier policy).
2.  When possible, use functions and macros to avoid repeating the same code multiple times. For example, if you are pulling the 1-year ACS, try to write functions that take year as an argument and then call the function multiple times instead of copying-and-pasting code.

# Code and Technical Review

## Scope of the review

All code and documentation will go through a review process. Code reviews will be handled through GitHub. 

It is possible that changes will be requested before the completion of a code review. For example, a reviewer may send the code back to the analyst if the code isn't reproducible (i.e. doesn't run) or if the documentation is insufficient for th reviewer to follow the logic. 

The scope of the review will involve the following three levels:

1.  Reproduction of results.
    -   Code should not error out. Warnings and notes are also cause for concern.
    -   The code should exactly recreate the final result.
2.  A line-by-line review of code logic.
    -   Code script should include top-level description of process and what the code accomplishes.
    -   Does the author's process and analytical choices make sense given the metric they are trying to calculate? Is the process implemented correctly?
    -   Variable construction: What is the unit of analysis? Is it consistent throughout the dataset?
    -   Are new variables what they say they are (check codebooks)?
    -   Check whether simple operations like addition/subtraction/division exclude observations with missing data.
    -   Does the researcher subset the data at all? Is it done permanently or temporarily?
    -   How are missing values coded?
    -   Look at merges/joins and appends - do the data appear to be matched appropriately? Are there identical non-ID variables in both datasets? How are non-matching data handled or dropped?
    -   Is the correct geographic crosswalk used?
    -   Are weights used consistently and correctly?
3.  Code Architecture/Readability.
    -   Is the code DRY (don't repeat yourself)? If code is repeated more than once, recommend that the writer turn the repeated code into a function or macro.
    -   Is there a place where a variable is rebuilt or changed later on?
    -   Are values transcribed by hand?
    -   "Messy but error-free" is not an acceptable status for finalized code. Code should be easy to follow, efficient, reproduceable, and should reflect well on the organization and project team.
4.  Public Release *Is the code clearly commented for public release (e.g., no use of abbreviations or acronyms that are Urban Institute specific)* Is the code free from any licenses, PII, or proprietary information?

## How to Prepare for a Code Review

-   Data access should be abundantly clear. Scripts should download the data or instructions for the necessary files located on Box should be included (see Starting or raw data practices above).
-   State if special computation was used when running the program (i.e. the Stata server or SAS server, anything off of a standard desktop).
-   If scripts use many variable names, make sure to include a codebook so reviewers can follow along. Code books should include variable names along with definitions of the variable. For categorical variables, please include a list of the possible categories for the given variable.
-   Clearly comment each step in the program with a focus on why the step is needed. Make sure to explain the logic behind the step so that a reviewer can judge whether the code effectively accomplishes this.
-   Use clear object (names of data frames or macro variables) and file names. For file names see the file naming convention above. 

**All scripts should run all the way through without errors. This should be the case regardless of the user/computer.**

## Code Reviews in GitHub

Our code review process will be handled through GitHub, which has powerful tools for code review.
[This page outlines the functionality.](https://github.com/features/code-review/)

### 1. Request

In our workflow, every analyst will push their code to the repository on its own branch named after the issue created for that task.
The process of reconciling these different branches into one branch called `version2024` is handled through pull requests.

For example, I will put in a pull request from `"issexample"` to `version2024`.
At this point, a reviewer will be requested in the pull request.
Aaron and Claudia will flag the reviewers.

<img src="images/request-review.png" width="400" height="200"/>

### 2. Review

The code will not be merged to `version2024` until the reviewer(s) approve the pull request.

GitHub will generate a line-by-line comparison of every line that is added or removed from `"issexample"` to `version2024`.

<img src="images/line-by-line.png" width="800" height="300"/>

Reviewers can add line-specific comments in GitHub.

<img src="images/comments.png" width="500" height="200"/>

### 3. Approve

Reviewers can also add overall comments before approving or requesting changes for the pull request.
If additional changes are added, GitHub will highlight the specific lines that changed in response to the review--this will save the reviewer time on second or third reviews of the same code.

<img src="images/approve-review.png" width="300" height="200"/>

Once the code is approved, the branch can be merged into the `main` branch where it can referenced and used for subsequent analyses.

## Code Branching for Reviewers

Line-by-line edits and feedback should be handled by reviewers through the point-and-click interface on GitHub.
Running code from a pull request will require [branching](https://guides.github.com/introduction/flow/).

Suppose you are reviewing code from branch `"issexample2"`.
You need to "fetch" the `"issexample2"` branch on to your local computer to run and review the code.
Steps:

1.  Open up Git Bash in the directory by right clicking in the `mobility-from-poverty` directory and and selecting Git Bash Here (on Windows).
3.  Make sure you are on the `version2024` branch `git checkout version2024`
2.  Submit `git status` and ensure that you don't have any tracked changes that have not been committed.
3.  Use `git branch` to see your current branch and other available branches. You should at least see `version2024` and `main`.
4.  Submit `git fetch` to get remote branches.
5.  Submit `git checkout --track origin/issexample2` to switch to the `issexample2` branch. Submit `git branch` to confirm the change.

At this point, you should be able to run and review the code.
Back on GitHub, you should be able to add line-by-line comments to the Pull Request if you click "Files changed" and then click the blue plus sign that appears next to the number by the line of code.

When your review is complete, click the green "Review changes" button on GitHub.
You should be able to add overall comments, approve the Pull Request, or Request changes to the Pull Request.
If you request changes, you will need to `git pull issexample2` after the analyst pushes the updated code to GitHub.

When you are done, you can switch back to your branch with `git checkout branch-name` where `branch-name` is the name of the branch you wish to switch to.
If you have un-committed changes, you will need to get rid of them with `git stash`.
You shouldn't make substantive changes on some else's branch.

*After all metrics have updated on `version2024`, reviewed and approved will the changes be merged with the `main` repository.*

# Creating the All Metrics Combined Files

The code to create the final collective files that combine all metrics is in `10_construct-database/`

There will be two final files.
The first file with be a year-county file with one row per county per year.
The second file will be county-level file with only the most recent year of data for each variable.
Both files will be [tidy data](https://vita.had.co.nz/papers/tidy-data.pdf) with each variable in its own column, each observation in its own row, and each value in its own cell.

# Data Dictionary

The [data dictionary](https://ui-research.github.io/mobility-from-poverty-dictionary/) is a website created with Quarto and hosted on GitHub pages.
The Quarto documents are stored in `mobility-from-poverty-documentation/`.
The folder contains its own `.Rproj` for Quarto reasons.
The website is contained in `docs/`.
Use the following steps to update the website.

1.  Open `mobility-from-poverty-documentation/mobility-from-poverty-documentation.Rproj`
2.  Update files but **do not click render**. Common types of changes include
    -   Updating .qmd files with additional information
    -   Re-rendering the documentation after updating the mobility metrics
    -   Updating R functions to change the information included in the data dictionary
3.  Run `quarto render` at the command line.
4.  Add, commit, and push the files to GitHub.
5.  Open a pull request to the branch that GitHub pages uses.

# External Users

For users outside of the Urban Institute that would like to utilize this repository this section offers guidance and tips.

*General repository structure*

The folders in this repository are broken into three main sections: Domains, Data and Documentation/Auxiliary.

1. Domains
  - Each domain in the UMF project has a folder (for example, 08_education). This folder holds the programs for the creation of the predictors that fall under that domain, for example, metrics for access to preschool, effective public education, school diversity, preparation for college, and digital access.
  
2. Data
  - The final data produced for each domain folder is within that domain in the "data/final" folder. The collective final data in raw form is also hosted in this repository under the folder titled "data". 

3. Documentation/Auxiliary
  - The other folders either document or provide auxiliary information/data for creating the predictors. The folder titled "documentation" holds a description of each predictor code in the repository as well as an introductory training to using Git and GitHub. 
  - Other auxiliary folder include the geographic-crosswalks folder which hosts all of the crosswalks the programs in this repository utilize. There is also a folder for constructing the database from the individual predictor files. 
  
For more specific use cases see below.

## Finding code 

One benefit of hosting this work on a public repository is that external users can view and download the code used to create these indicators. If you would like to download the code used to create a certain UMF data point you can find it in one of the folder held in this repository. 
To track down the right folder, first utilize the table under repository contents to match your predictor of interest (right-hand column) with that predictor's domain. The folder containing the code for that predictor will have a title similar to the domain. Enter that folder on GitHub and locate the program file with the predictor in the title. 

*Example: Environmental quality* The environmental quality predictor falls under the Opportunity-Rich & Inclusive Neighborhoods pillar. In the GitHub repository there is a folder titled 06_neighborhoods - this is the corresponding folder. Inside that folder is another folder titled environment. It is in that folder you will find the program that creates the predictor. GitHub will give you the option to download the raw version of the file. 

## Locating raw data

The origins of the raw data used to create each of these indicators should be readily available in the code associated with each predictor. There are likely two primary ways you can trace the data: 

1) For predictors where the raw data is not available for direct download through an API, the source of the raw data will be noted in text at the top of the code. Follow the link or description to download this data.

2) For predictors where the data is available through an API, the code will utilize that API to pull the data directly. You can read the section of the code that interacts with the API to see what variables and specifications are used. 


# Contact

**For Urban employees only, please reach out to the "umf-mobilitymetrics3" slack channel if you have questions.** For external users please contact Aaron R. Williams with questions.
