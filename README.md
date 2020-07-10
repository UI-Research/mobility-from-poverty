This repository contains code to construct 26 county-level metrics that broadly measure mobility from poverty. To learn more please read

* [Boosting Upward Mobility: Metrics to Inform Local Action](https://www.urban.org/research/publication/boosting-upward-mobility-metrics-inform-local-action)
* [Boosting Upward Mobility: Metrics to Inform Local Action Summary](https://www.urban.org/research/publication/boosting-upward-mobility-metrics-inform-local-action-summary)

# Motivation

The objective of this repository is to make all results reproducible, to document processes and assumptions, and to make it easier for analysts to produce metrics in future years. A little extra effort today can make a big difference in the future. For more motivation, please read the motivation for a style guide by  [Michael Stepner](https://github.com/michaelstepner/healthinequality-code/tree/master/code#motivation). 

The guide is a work-in-progress. If there are any ambiguities or unresolved questions, please contact [Aaron R. Williams](awilliams@urban.org). 

# Contents

todo(aaron): link to sections

# Contributing

## Organization

* Each metric or *closely* related set of metrics should have its own directory. The name of the directory should only contain lower case letters, numbers, and hyphens. Do not include spaces. 
* Each subdirectory should include a README.md. The README.md should include all information outlined in the README.md for each file created in the subdirectory. It should also contain clear instructions for running the code. 
* Avoid absolute file paths. If using R use `.Rproj`. If using Stata, use projects. Otherwise, set the working directory. 
* **Do not add any data to the repository.** Each subfolder should contain a `data/` folder for intermediate and final data files. The `data/` folder should be added to the `.gitignore`. 
* If possible, download your data with code or pull your data from an API with code. 
* **Do not include any credentials in the repository.** Please reach out to [Aaron R. Williams](awilliams@urban.org) if this creates issues. 
* Use names that play well with default ordering (e.g. 01, 02 and YYYY-MM-DD dates) for directory and file names.

## GitHub Workflow

* Do not work on the `master` branch. 
* Check out a branch with your first name in lowercase. Additional branching is allowed but merge all changes into your main branch. 
* If you are using files or scripts created by others, be sure to regularly pull from the master branch. 
* Commit changes regularly with detailed commit messages. 
* Regularly push your code to your remote branch on GitHub. 
* To contribute to the `master` branch, put in a Pull Request. Tag Aaron R. Williams as a reviewer (@awunderground). Briefly describe what the PR does. 
* Aaron R. Williams will review and incorporate changes into the `master` branch. He may ask you to make changes. 

**Please reach out Aaron with any questions.** The only thing he loves more than version control is helping people learn version control. 

## Data Standards

* All final files should be in the .csv format.
* Important intermediate files should be added to Box. Final data files should be added to Box.

### Joining variables

* The first three variables in every file should be `state`, `county`, and `tract`. `state` should be a two characters FIPS code, `county` should be a three character FIPS code, and `tract` should be a six character FIPS code. All variables should have leading zeros for ids beginning in zeros. 

### Values

* Include all counties even if a county is all missing values. Every join to the master file should be one-to-one.
* Variable names should only include lower case letters, numbers, and underscores (lower camel case, i.e. camel_case). 
* Percentages should be stored as proportions between o and 1 inclusive with a leading zero. (75% should be 0.75)
* Missing values should be coded as `NA`

### Sorting

* All files should be sorted by `state`, `county`, and `tract`, the first three variables in every file. 

## Code Standards 

* Use descriptive names for all variables, data sets, functions, and macros. Avoid abbreviations. 
* Include comments that state why, not what. Include comments for all assumptions. 
* Don't repeat yourself. If you do anything more than twice, turn it into a function or macro. Document the function or macro. 
* Use ISO 8601 dates (YYYY-MM-DD).

# Code Review

## Scope of the review

Code and documentation will be reviewed by Aaron R. Williams and possibly additional reviewers. Aaron's code and documentation will be reviewed by someone else. Code reviews will be handled through GitHub. The scope of the review will involve the following three levels:

1. Reproduction of results. 
    * Code should not error out. 
    * The code should exactly recreate the final result. 
2. A line-by-line review of code logic. 
    * Variable construction: What is the unit of analysis? Is it consistent throughout the dataset?
    * Are new variables what they say they are (check codebooks)?
    * Check whether simple operations like addition/subtraction/division exclude observations with missing data.
    * Does the researcher subset the data at all? Is it done permanently or temporarily?
    * How are missing values coded?
    * Look at merges/joins and appends - do the data appear to be matched appropriately? Are there identical non-ID variables in both datasets? How are non-matching data handled or dropped?
    * Are weights used consistently?
3. Code Architecture/Readability.
    * Is the code DRY (don't repeat yourself)? If code is repeated more than once, recommend that the writer turn the repeated code into a function.
    * Is there a place where a variable is rebuilt or changed later on?
    * Are values transcribed by hand?

## How to Prepare for a Code Review

* Data access should be abundantly clear. Scripts should download the data or instructions for the necessary files located on Box should be included. 
* Write tests with code like `assert` and `stopifnot()` to demonstrate the validity of calculations. 
* State if special computation was used (i.e. the Stata server or SAS server). 
* If scripts use many variable names, make sure to include a codebook so reviewers can follow along.
* For calculations, code should be commented with clear variable labels. 

# License for Code

todo(aaron): find the appropriate license

# Contact

Please contact [Aaron R. Williams](awilliams@urban.org) with questions. 
