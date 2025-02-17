// Final data evaluation - test function
// Prior to running this function users should fill out the final data expectation CSV form located in the functions/testing folder 
// Users should create an expectation form for each final data file being created in their program 
// Every final data file created in a program should be put through this test function 
//
// Function call: evaluate_final_data
// Inputs:
//   exp_form_path (str): the file path (including csv name) to the expectation form for this data file
global exp_form_path "C:\Users\ekgut\OneDrive\Desktop\urban\Github\mobility-from-poverty\10a_final-evaluation\evaluation_form_homeless_student_place"
//   data (str): the data that is staged to be read out as the final file
global data "C:\Users\ekgut\OneDrive\Desktop\urban\Github\mobility-from-poverty\02_housing\data\final\homelessness_2014-2018_city"
//   geography (str): either "place" or "county" depending on the level of data being tested
global geography "place"
//   subgroups (logical): a true or false value indicating if the final file has subgroups'
global subgroups "race-ethnicity"
//   confidence_intervals  (logical): a true or false value indicating if the final file has confidence intervals
// Returns:
//   a series of test results that will throw an error if failed 
ssc install valuesof
ssc install moremata

program define evaluate_final_data
    args exp_form_path data geography subgroups confidence_intervals

    // Read in the data expectation form
    import delimited using $exp_form_path, clear rowrange(5:) varnames(3)
    drop if missing(metricnameaswritteninfinaldatafi) | strpos(userinput, "Example") > 0

    // Clean variable names
    rename (metricnameaswritteninfinaldatafi userinput qualityvariablesavailableyesorno confidenceintervalsyesorno) ///
           (metric_name user_input quality_available ci_available)

    // Pull information for variable check from expectation form
	valuesof metric_name
	global metric_name = r(values) 
    global quality_title = cond(quality_available == "Yes", metric_name + "_quality", "")
    global ci_low_title = cond(ci_available == "Yes", metric_name + "_lb", "")
    global ci_high_title = cond(ci_available == "Yes", metric_name + "_ub", "")
    global metric_geography = "$geography"
	global state = "state"
    global year = "year"
	*a gloabl for all the years listed in the final eval form
	preserve
	gen year_form = subinstr(allyearsusenospace, ";", " ", .)
	split year_form, gen(n) destring
	gen obs=_n
	keep if obs==1
	reshape long n, i(year_form) j(num_years)
	valuesof n
	global year_form = r(values)
	restore
	*a global for all subgroup types
	preserve
	if subgrouptypeleaveblankifnone != "" {
	split subgroupvaluesincludeallanduseno, gen(subgroupvalues) p(;)
	gen obs=_n
	keep if obs==1
	reshape long subgroupvalues, i(subgroupvaluesincludeallanduseno) j(num_types)
	valuesof subgroupvalues
	global subgroupvalues = r(subgroupvalues)
	restore
	}
	
    // Read in the data
    import delimited using $data, clear stringcols(_all)

    // Check if the data contains the expected variables
    foreach var of varlist $metric_name $quality_title $ci_low_title $ci_high_title {
        if "`var'" != "" {
            capture confirm variable `var'
            if _rc {
                di as error "Variable `var' not found in the data."
                exit 1
            }
        }
    }

    // Check if the data contains the expected geography
    capture confirm variable $geography
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
    foreach var of varlist $quality_title $ci_low_title $ci_high_title {  
        if "var'" != "" {
            count if missing(`var')
            local n_missing = r(N)
            if `n_missing' > 0 {
                di as error "Missing values found in variable `var'."
                exit 1
            }
        }
    }

    // Check FIPS codes
    if "$geography" == "county" { 
        gen geoid = state + county
    }
   else if "$geography" == "place" {
        gen geoid = state + place
    }
    gen geoid_length = length(geoid)
    egen unique_geoid_length = max(geoid_length)
    if unique_geoid_length != geoid_length[1] {
        di as error "Inconsistent lengths of FIPS codes."
        exit 1
    }

	// Check if the number of years in final eval form are same in output file
	preserve
	bysort year: gen obs=_n
	keep if obs==1
	destring year, replace
	valuesof year
	gen year_data = r(values)
	capture confirm year_data = "$year_form"
    if _rc {
        di as error "Years do not match those found in the data."
        exit 1
    }
	restore
	
	// Check if the subgroups in final eval form are same in output file
   preserve
	if "$subgroups" != "" {
	bysort year: gen obs=_n
	keep if obs==1
	destring year, replace
	valuesof year
	gen year_data = r(values)
	capture confirm year_data = "$year_form"
    if _rc {
        di as error "Years do not match those found in the data."
        exit 1
    }
	restore
	
end

evaluate_final_data $data $exp_form_path "place" 0 1

// Example usage:
// evaluate_final_data "path/to/expectation_form.csv" "path/to/data.csv" "place" 0 1
