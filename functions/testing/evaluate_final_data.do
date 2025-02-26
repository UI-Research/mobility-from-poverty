// Final data evaluation - test function
// Prior to running this function users should fill out the final data expectation CSV form located in the functions/testing folder 
// Users should create an expectation form for each final data file being created in their program 
// Every final data file created in a program should be put through this test function 
//
// Function call: evaluate_final_data
// Inputs:
//   exp_form_path (str): the file path (including csv name) to the expectation form for this data file
//   data (str): the data that is staged to be read out as the final file
//   geography (str): either "place" or "county" depending on the level of data being tested
//   subgroups (logical): a true or false value indicating if the final file has subgroups
//   confidence_intervals  (logical): a true or false value indicating if the final file has confidence intervals
// Returns:
//   a series of test results that will throw an error if failed 

program define evaluate_final_data
    args exp_form_path data geography subgroups confidence_intervals

    // Read in the data expectation form
    import delimited using "`exp_form_path'", clear
    drop if missing(metric_name_as_written_in_final_data_file) | strpos(user_input, "Example") > 0

    // Clean variable names
    rename (metric_name_as_written_in_final_data_file user_input quality_variables_available_yes_or_no confidence_intervals_yes_or_no) ///
           (metric_name user_input quality_available ci_available)

    // Pull information for variable check from expectation form
    gen quality_title = cond(quality_available == "Yes", metric_name + "_quality", "")
    gen ci_low_title = cond(ci_available == "Yes", metric_name + "_lb", "")
    gen ci_high_title = cond(ci_available == "Yes", metric_name + "_ub", "")
    gen metric_geography = "`geography'"
    gen state = "state"
    gen year = "year"

    // Read in the data
    import delimited using "`data'", clear

    // Check if the data contains the expected variables
    foreach var of varlist metric_name quality_title ci_low_title ci_high_title {
        if "`var'" != "" {
            capture confirm variable `var'
            if _rc {
                di as error "Variable `var' not found in the data."
                exit 1
            }
        }
    }

    // Check if the data contains the expected geography
    capture confirm variable `geography'
    if _rc {
        di as error "Geography variable `geography' not found in the data."
        exit 1
    }

    // Check if the data contains the state and year variables
    capture confirm variable state
    if _rc {
        di as error "State variable not found in the data."
        exit 1
    }

    capture confirm variable year
    if _rc {
        di as error "Year variable not found in the data."
        exit 1
    }

    // Check for missing values in quality and confidence interval columns
    foreach var of varlist quality_title ci_low_title ci_high_title {
        if "`var'" != "" {
            count if missing(`var')
            local n_missing = r(N)
            if `n_missing' > 0 {
                di as error "Missing values found in variable `var'."
                exit 1
            }
        }
    }

    // Check FIPS codes
    if "`geography'" == "county" {
        gen geoid = state + county
    }
    else if "`geography'" == "place" {
        gen geoid = state + place
    }
    gen geoid_length = length(geoid)
    egen unique_geoid_length = total(geoid_length)
    if unique_geoid_length != geoid_length[1] {
        di as error "Inconsistent lengths of FIPS codes."
        exit 1
    }

    // Compare final data and exp_form variable titles
    if `subgroups' {
        drop all_years_use_no_space confidence_intervals_yes_or_no quality_available
        reshape long, i(metric_name) j(variable)
        sort variable
    }
    else {
        drop all_years_use_no_space confidence_intervals_yes_or_no quality_available subgroup_type subgroup
        reshape long, i(metric_name) j(variable)
        sort variable
    }

    // Display the processed expectation form
    list

end

// Example usage:
// evaluate_final_data "path/to/expectation_form.csv" "path/to/data.csv" "place" 0 1