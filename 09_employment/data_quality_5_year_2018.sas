/*

This code creates the data quality metric for each of the ACS indecies.

The metric is 1-3, where 1 is best quality and 3 is worst. The metrics for
the ACS indices included here are based on what percent of data for the 
county actually came from the county itself, and the sample size in each 
county.

Programmed by Kevin Werner

12/1/20

The program does the following:
-Creates the county size flag (same for every metric)
-Creates the sample size flag (metric-specific)
-Merges the two flags and creates the final data quality flag
-Brings in the metric CSVs
-Adds the data quality flag to the metrics and outputs the CSVs
*/

/* need a library for every metric */
libname desktop "C:\Users\kwerner\Desktop\Metrics";
libname puma "V:\Centers\Ibp\KWerner\Kevin\Mobility\Paul";
libname metrics "V:\Centers\Ibp\KWerner\Kevin\Mobility\Paul\2018";
libname edu "V:\Centers\Ibp\KWerner\Kevin\Mobility\gates-mobility-metrics\08_education";
libname income "V:\Centers\Ibp\KWerner\Kevin\Mobility\gates-mobility-metrics\01_financial-well-being";
libname house "V:\Centers\Ibp\KWerner\Kevin\Mobility\gates-mobility-metrics\02_housing";
libname fam "V:\Centers\Ibp\KWerner\Kevin\Mobility\gates-mobility-metrics\03_family";
libname employ "V:\Centers\Ibp\KWerner\Kevin\Mobility\gates-mobility-metrics\09_employment";
libname lib2018 "V:\Centers\Ibp\KWerner\Kevin\Mobility\Paul\2018";

%let metrics_folder = V:\Centers\Ibp\KWerner\Kevin\Mobility\gates-mobility-metrics\; 

options fmtsearch=(lib2018);

 Proc format;
  Value subgroup_f
 4 = "White, Non Hispanic"
 1 = "Black, Non Hispanic"
 3 = "Other Races and Ethnicities"
 2 = "Hispanic"
;
run;


/* Read in puma to county file and create flags for high percentage
of data from outside county. Per Greg, 75% or more from the county is good,
below 35% is bad, in between is marginal.

This is calculated by taking the product of percentagge of PUMA in county and
percentage of county in PUMA for each county-PUMA pairing, and summing
across the county
*/

data puma_county;
 set puma.puma_to_county; /* this file should be output by the 2_puma_county.sas program */
 by statefip county;
 products = afact*AFACT2;
 retain sum_products county_pop;
 if statefip = 51 and county = 515 then delete;
 if first.county then do;
  sum_products = 0;
  county_pop = 0;
 end;
 sum_products + products;
 county_pop + pop10;
 if last.county then output;
run;

data puma_county;
 set puma_county;
 if sum_products ne . then do;
  if sum_products >= 0.75 then puma_flag = 1; /* create indicator */
   else if sum_products < 0.75 and sum_products >= 0.35 then puma_flag = 2;
   else if sum_products < 0.35 then puma_flag = 3; 
  end;
  else puma_flag = .;
run;

/**** next step is to create a sample size flag for each metric ****/

/* for the income metrics, I create a dataset with just households */

data housholds_5_year (keep = statefip county subgroup pernum);
 set lib2018.microdata_5_year;
 where pernum = 1;
run;


/* create income metric that right now just has the number of total households */
proc means data=housholds_5_year noprint; 
  output out=metrics_income_subgroup(drop=_type_) sum=;
  by statefip county subgroup;
  var pernum ;
run;



 
/* Load in each ACS metric and check the sample size in each county. 

The denominator for each of the metrics is as follows:
-College: number of people ages 19 and 20
-Family: number of people under age 18
-Employment: number of people 25-54
-Preschool: number of people ages 3 and 4
-Income: total number of households

These denominators are used as the sample size flags
*/
%macro metric(lib= , dataset= , denominator= );
data &dataset. ;
 set &lib..&dataset. ;
 if &denominator < 100 then size_flag = 1;
  else size_flag = 0;
run;
%mend metric;
%metric(lib = edu, dataset = metrics_college_subgroup, denominator = _FREQ_);
%metric(lib = fam, dataset = metrics_famstruc_subgroup, denominator = _FREQ_);
%metric(lib = employ, dataset = metrics_employment_subgroup, denominator = _FREQ_);
%metric(lib = edu, dataset = metrics_preschool_subgroup, denominator = _FREQ_);
%metric(lib = work, dataset = metrics_income_subgroup, denominator = pernum);


/****
Next step is to merge the PUMA flag with each individual metric, and then create the final 
data quality metric based on both the SIZE and PUMA flags
****/

/* first need to turn statefip and county back into numeric for preschool metric */
data metrics_preschool_subgroup;
 set metrics_preschool_subgroup;
 new_county = input(county, 8.); 
 new_statefip = input(state, 8.);
 drop county state;
 rename new_county = county;
 rename new_statefip = statefip;
run;

proc sort data = metrics_preschool_subgroup; by statefip county subgroup; run;

/* this creates the quality metric. Per discussion with Greg, 
only ACS metrics with sample size < 100 should be be marked as "3"
This code gives a county a "1" if they have a large sample size and
at least 75% of the data comes from county. If the county has a large
sample size and less than 75% of the data comes from the county, the 
county gets a "2." Small sample size gives a "3" */

%macro flag(dataset= , metric= ); 
data &dataset._flag (keep = state county subgroup &metric._quality);
 merge &dataset. puma_county;
 by statefip county;
 if size_flag = 0 then do; 
  if puma_flag = 1 then &metric._quality = 1;
  else if puma_flag = 2 then &metric._quality = 2;
  else if puma_flag = 3 then &metric._quality = 2;
 end;
 else if size_flag = 1 then &metric._quality = 3;
 else &metric._quality = .;


 state = statefip;

 /* I have to change the subgroup variable to character, since when I bring in the original CSV it will be a character var */

length subgroup_c $30;
if subgroup = 4 then subgroup_c = "White, Non-Hispanic";
 else if subgroup = 1 then subgroup_c = "Black, Non-Hispanic";
 else if subgroup = 3 then subgroup_c = "Other Races and Ethnicities";
 else if subgroup = 2 then subgroup_c = "Hispanic";

 drop subgroup;

 rename subgroup_c = subgroup;

run;

/* tests */
proc freq data = &dataset._flag;
 table &metric._quality;
 title "&dataset.";
run;

%mend flag;

%flag(dataset = metrics_college_subgroup, metric = hs_degree); 
%flag(dataset = metrics_famstruc_subgroup, metric = famstruc);
%flag(dataset = metrics_employment_subgroup, metric = employed);
%flag(dataset = metrics_preschool_subgroup, metric = preschool);
%flag(dataset = metrics_income_subgroup, metric = pctl);


/**** output as CSVs ****/
/* first I infile the original metric CSVs.

	Next, I merge the flag with the infiled csv

	Then, I output as a final CSV */

%macro output(dataset= , folder =, metric = );
proc import datafile="&metrics_folder.&folder.&dataset..csv" out=&dataset._orig dbms=csv replace;
  getnames=yes;
  guessingrows=100;
  datarow=2;
run;

data &dataset._f (drop = _FREQ_ quality);
 merge &dataset._orig &dataset._flag;
 by state county;
 if state = 15 and county = 5 then &metric._quality = 3;
/* make sure that state and county have leading 0s */
 new_county = put(county, z3.); 
 new_statefip = put(state, z2.);
 drop county state;
 rename new_county = county;
 rename new_statefip = state;
run;

data &dataset._f;
	retain year state county subgroup_type subgroup;
 	set &dataset._f;
run;

proc export data= &dataset._f
 outfile = "&metrics_folder.&folder.&dataset..csv"
 replace;
run;

%mend output;
%output(dataset = metrics_college_subgroup, folder = 08_education\, metric = hs_degree); 
%output(dataset = metrics_preschool_subgroup, folder = 08_education\, metric = preschool); 
%output(dataset = metrics_famstruc_subgroup, folder = 03_family\, metric = famstruc); 
%output(dataset = metrics_income_subgroup, folder = 01_financial-well-being\, metric = pctl); 
%output(dataset = metrics_employment_subgroup, folder = 09_employment\, metric = employed); 


/* I want to test if the number of people ages 19 and 20
in the microdata file is the same as the sum of the _FREQ_
variable in the metrics_college file. They should equal */

data college_test (keep = age_19_20);
 set metrics.microdata_5_year;
 if age in (19,20) then age_19_20 = 1;
  else age_19_20 = 0;
run;

proc freq data = college_test;
 table age_19_20;
run;
/* 598835 */

proc means data = metrics_college_subgroup sum ;
 var _FREQ_;
run;

/* 598835. Wooo, they match */

/* frequency tests */
proc freq data=metrics_college_subgroup_f;
 table hs_degree_quality;
run;
proc freq data=metrics_preschool_subgroup_f;
 table preschool_quality;
run;
proc freq data=metrics_famstruc_subgroup_f;
 table famstruc_quality;
run;
proc freq data=metrics_income_subgroup_f;
 table pctl_quality;
run;
proc freq data=metrics_employment_subgroup_f;
 table employed_quality;
run;

/* checks to see how many got suppressed */
proc freq data=metrics_college_subgroup_f;
 where share_hs_degree = .;
 table subgroup / missing ;
run;
proc freq data=metrics_preschool_subgroup_f;
 where share_in_preschool = .;
 table share_in_preschool / missing ;
run;
proc freq data=metrics_famstruc_subgroup_f;
 where famstruc_2par_married = .;
 table famstruc_2par_married / missing ;
run;
proc freq data=metrics_income_subgroup_f;
 where pctl_80 = .;
 table pctl_80 / missing ;
run;
proc freq data=metrics_employment_subgroup_f;
 where share_employed = .;
 table share_employed / missing;
run;
