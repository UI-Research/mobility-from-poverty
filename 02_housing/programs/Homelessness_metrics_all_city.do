** HOMELESSNESS **
** E Gutierrez **
** 08/23/2022 **
** Uses nongeographic district data 
clear all

global gitfolder "C:\Users\ekgut\OneDrive\Desktop\urban\Github\mobility-from-poverty"
*global boxfolder "D:\Users\EBlom\Box Sync\Metrics Database\Housing"
global years 2014 2015 2016 2017 2018 2019 

cap n mkdir "${gitfolder}\02_housing\data"
cd "${gitfolder}\02_housing\data"

cap n mkdir "raw"
cap n mkdir "intermediate"
cap n mkdir "built"

** install educationdata command **
cap n ssc install libjson
net install educationdata, replace from("https://urbaninstitute.github.io/education-data-package-stata/")

** Get CCD district data **
foreach year in $years {
	educationdata using "district ccd directory", sub(year=`year') col(year leaid city_location enrollment fips) clear
	save "intermediate/ccd_lea_`year'_city.dta", replace
}


** Download EDFacts data **
*https://www2.ed.gov/about/inits/ed/edfacts/data-files/school-status-data.html
foreach year in $years {
	local nextyear = `year' - 2000 + 1
	if `year'== 2018 copy "https://www2.ed.gov/about/inits/ed/edfacts/data-files/lea-homeless-enrolled-sy`year'-`nextyear'-wide.csv" "raw/EDFacts Homelessness `year'.csv", replace
	if `year'< 2018  copy "https://www2.ed.gov/about/inits/ed/edfacts/data-files/lea-homeless-enrolled-sy`year'-`nextyear'.csv" "raw/EDFacts Homelessness `year'.csv", replace
	if `year'== 2019  copy "https://www2.ed.gov/about/inits/ed/edfacts/data-files/lea-homeless-enrolled-sy`year'-`nextyear'-long.csv" "raw/EDFacts Homelessness `year'.csv", replace

	import delimited "raw/EDFacts Homelessness `year'.csv", clear
	gen year = `year'
	if year<2017 {
	ren cdw cwd
	ren lep el
	}
	if year==2018{
	ren sheltered sheltered
	}
	save "raw/edfacts_homelessness_`year'.dta", replace
}
*EG: 2019 is only available in long form - reshape below
use "raw/edfacts_homelessness_2019.dta", clear
drop school_year_text data_group_id category subgrant_status prek_flag date_cur
replace cat_abbrv="shel_tran_h" if cat_abbrv=="SHELTERED_TRANSITIONAL_HOUSING"
reshape wide student_count,  i(year stnam fipst leaid st_leaid leanm) j(cat_abbrv) string
*rename to match other years' variables
ren student_countAM7 amin_an
ren student_countBL7 black
ren student_countHI7 hispanic
ren student_countWH7 white
ren student_countMU7 twomore
ren student_countPI7 nh_pi
ren student_countAS7 asian
ren student_countCWD cwd
ren student_countDOUBLED_UP doubled_up
ren student_countEL lep
ren student_countHOTELS_MOTELS hotels_motels
ren student_countMIG mig
ren student_countTOTAL total
ren student_countUHY uhy
ren student_countUNSHELTERED unsheltered
ren student_countshel_tran_h sheltered
save "raw/edfacts_homelessness_2019wide.dta", replace

** Data suppression: data are suppressed when values are between 0-2, but if only one value is suppressed the next smallest number is also suppressed ** 
** I replaced all suppressed data with the midpoint (1) but this does not yield numbers (for 2017) that align perfectly with this report: 
** https://nche.ed.gov/wp-content/uploads/2020/01/Federal-Data-Summary-SY-15.16-to-17.18-Published-1.30.2020.pdf (Tables 5 and 6)
** Note also that data are unduplicated * by LEA * which does not mean they will necessarily be unduplicated * by county * if students switch between LEAs in a county **

clear
foreach year in $years {
	if `year'<2019 {
		append using "raw/edfacts_homelessness_`year'.dta" 
		}
		else {
	append using "raw/edfacts_homelessness_`year'wide.dta" 
	}
	}
	
rename total homeless

foreach var in homeless hotels_motels unsheltered sheltered doubled_up cwd lep amin_an black hispanic white twomore nh_pi asian mig  { // 
	di "`var'"
	gen supp_`var' = 1 if `var'=="S"
	replace `var'="1" if `var'=="S"
	destring `var', replace
	bysort year fipst subgrant_status: egen min_`var' = min(`var')
	bysort year fipst subgrant_status: egen count_supp_`var' = total(supp_`var')
	gen `var'_lower_ci = `var'
	replace `var'_lower_ci = 0 if supp_`var'==1
	gen `var'_upper_ci = `var'
	replace `var'_upper_ci = 2 if supp_`var'==1
	replace `var'_upper_ci = min_`var' if supp_`var'==1 & count_supp_`var'<=2 // if only one of two are suppressed, replace with next smallest number
}

keep year leaid *homeless* *hotels_motels* *unsheltered* *sheltered* *doubled_up* *cwd* *lep* *amin_an* *black* *hispanic* *white* *twomore* *nh_pi* *asian*
tostring leaid, replace
replace leaid = "0" + leaid if strlen(leaid)!=7
assert strlen(leaid)==7

save "intermediate/homelessness_all_years.dta", replace


** Using leaid to calculate homelessness share **
use "intermediate/homelessness_all_years.dta", clear
foreach year in $years {
	merge m:1 year leaid using "intermediate/ccd_lea_`year'_city.dta", update
	drop if _merge==2
	drop _merge
}

*EG: is this really what we want?
replace enrollment=0 if enrollment<0 | enrollment==.

foreach var in homeless hotels_motels unsheltered sheltered doubled_up cwd lep amin_an black hispanic white twomore nh_pi asian {
replace `var'=0 if enrollment==0
}
foreach var in homeless hotels_motels unsheltered sheltered doubled_up cwd lep amin_an black hispanic white twomore nh_pi asian {
replace `var'_upper_ci=0 if enrollment==0
}
foreach var in homeless hotels_motels unsheltered sheltered doubled_up cwd lep amin_an black hispanic white twomore nh_pi asian {
replace `var'_lower_ci=0 if enrollment==0
}
foreach var in homeless hotels_motels unsheltered sheltered doubled_up cwd lep amin_an black hispanic white twomore nh_pi asian {
replace supp_`var'=0 if enrollment==0
}

*EG: since this refers to homeless as total and enrollment, I think this doesn't need the subgroups
gen enroll_nonsupp = enrollment if supp_homeless!=1
gen enroll_supp = enrollment if supp_homeless==1

*no need to collapse since already at the district level
*collapse (sum) *homeless* *hotels_motels* *sheltered* *doubled_up* *cwd* *lep* *amin_an* *black* *hispanic* *white* *twomore* *nh_pi* *asian* enrollment enroll_nonsupp enroll_supp, by(year state county)

foreach var in homeless hotels_motels unsheltered sheltered doubled_up cwd lep amin_an black hispanic white twomore nh_pi asian {
rename `var' `var'_count
rename `var'_lower_ci `var'_count_lb
rename `var'_upper_ci `var'_count_ub
rename supp_`var' `var'_districts_suppress
gen `var'_share = `var'_count/enrollment
}

*EG: same comment as above - I don't think we want individual quality since homeless is the total
gen coverage = enroll_nonsupp/enrollment
gen homeless_quality = 1 if homeless_count_ub / homeless_count_lb <=1.05
replace homeless_quality = 2 if homeless_count_ub / homeless_count_lb > 1.05 & homeless_count_ub / homeless_count_lb <=1.1
replace homeless_quality = 3 if homeless_quality==. & homeless_count!=.

sum coverage, d, if homeless_quality==1
sum coverage, d, if homeless_quality==2
sum coverage, d, if homeless_quality==3

foreach var in homeless hotels_motels unsheltered sheltered doubled_up cwd lep amin_an black hispanic white twomore nh_pi asian {
drop `var'_districts_suppress
}
drop enrollment coverage enroll_supp enroll_nonsupp

*EG:not sure what led to the manual adjustment here
*replace county="102" if state=="46" & county=="113"

order year fips city_location *homeless* *hotels_motels* *sheltered* *doubled_up* *cwd* *lep* *amin_an* *black* *hispanic* *white* *twomore* *nh_pi* *asian* 

gsort -year fips city_location 

export delimited using "built/homelessness_all_city.csv", replace
*export delimited using "${gitfolder}\02_housing\homelessness_all.csv", replace
*export delimited using "${boxfolder}/homelessness_all.csv", replace

/*
. tab year homeless_quality, m

 Academic year (fall |              homeless_quality
           semester) |         1          2          3          . |     Total
---------------------+--------------------------------------------+----------
                2014 |     2,289        101        429        323 |     3,142 
                2018 |     2,523         93        240        286 |     3,142 
---------------------+--------------------------------------------+----------
               Total |     4,812        194        669        609 |     6,284 
*/


