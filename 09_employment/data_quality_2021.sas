/*

This code creates the data quality metric for each of the ACS indecies.

The metric is 1-3, where 1 is best quality and 3 is worst. The metrics for
the ACS indices included here are based on what percent of data for the 
county actually came from the county itself, and the sample size in each 
county.

Programmed by Kevin Werner

9/1/20

The program does the following:
-Creates the county size flag (same for every metric)
-Creates the sample size flag (metric-specific)
-Merges the two flags and creates the final data quality flag
-Brings in the metric CSVs
-Adds the data quality flag to the metrics and outputs the CSVs
*/

/* need a library for every metric */
libname desktop "S:\KWerner\Metrics";
libname puma "V:\Centers\Ibp\KWerner\Kevin\Mobility\Paul";
libname metrics "V:\Centers\Ibp\KWerner\Kevin\Mobility\Paul\2021";
libname edu "V:\Centers\Ibp\KWerner\Kevin\Mobility\gates-mobility-metrics\08_education";
libname income "V:\Centers\Ibp\KWerner\Kevin\Mobility\gates-mobility-metrics\01_financial-well-being";
libname house "V:\Centers\Ibp\KWerner\Kevin\Mobility\gates-mobility-metrics\02_housing";
libname fam "V:\Centers\Ibp\KWerner\Kevin\Mobility\gates-mobility-metrics\03_family";
libname employ "V:\Centers\Ibp\KWerner\Kevin\Mobility\gates-mobility-metrics\09_employment";

%let metrics_folder = V:\Centers\Ibp\KWerner\Kevin\Mobility\gates-mobility-metrics\; 

/* Read in puma to county file and create flags for high percentage
of data from outside county. Per Greg, 75% or more from the county is good,
below 35% is bad, in between is marginal.

This is calculated by taking the product of percentagge of PUMA in county and
percentage of county in PUMA for each county-PUMA pairing, and summing
across the county

This code gets the portion of data on each county that comes from that county. 
There is a row for each state/county/PUMA combination. 
The afact is the share of a county in a PUMA and afact2 is the share of a PUMA in a county.
If afact and afact2 were both 1, that means the county and PUMA shared the same borders. 

If afact is <1 and afact2 is 1, the PUMA spans a counties, but that county is entirely 
in the PUMA. If afact2 is 0.5 in this example, then products will equal 0.5. Products is summed for
each instance of the county, but there is only one instance, so the sum is 0.5. 

If afact is 1 and afact2 is <1, then the county is spread over multiple PUMAs. afact and afact2 are
multiplied together and summed for each instance of the county. So if the county is spread perfectly 
among two PUMAs, afact2 will be 0.5 for each row, the product of afact and afact2 will be 0.5, and 
the sum will 1 one, meaning we know where 100% of the county's data comes from. 

If both afact and afact2 are <1, then the result is a combination of previous two examples. There 
will be mutliple instances of rows to be summed, but the total sum will likely be less than 1.

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
 if county_pop >= 35000 then small_county = 0; /* create small county indicator requested by Greg */
  else if county_pop <35000 then small_county = 1;
run;

proc freq data = puma_county;
 table puma_flag*small_county / missing nocol;
run;

proc freq data=puma_county;
 table puma_flag;
run;

proc means data=puma_county;
 var sum_products;
run;

/**** next step is to create a sample size flag for each metric ****/

/* for the housing metric, I use an intermediate dataset produced
when creating the metric so I can get the unweighted
number of households with <30 AMI to use as the size flag. The 
dataset I use as input is created as an intermediate step in 
Paul's code and contains only households. 

I also use this dataset to create the total number of households, 
which is the sample size for the income metric*/
%macro number_of_hhs(year);
data households_&year (keep = statefip county Below30AMI_unw household year);
  set desktop.households_&year; /* this file should be output by the program compute_metrics_housing.sas */
  if L50_4 ne . then do;
    Below30AMI_unw = hhincome < ELI_4;  
  end;
  household = 1;
run;

proc means data=households_&year noprint; 
  output out=number_hhs_&year(drop=_type_) sum=;
  by year statefip county;
  var Below30AMI_unw household ;
run;
%mend number_of_hhs;
%number_of_hhs(year=2021);

/* get state and county in same format 
data house.metrics_housing_2021;
 set house.metrics_housing_2021;
 new_county = input(county, 8.); 
 new_statefip = input(state, 8.);
 drop county state;
 rename new_county = county;
 rename new_statefip = statefip;
run;*/

/* add number of low income households to housing metric */
data metrics_housing_2021;
 merge house.metrics_housing_2021 number_hhs_2021;
 by /*year*/ statefip county; /************** only need year if dataset has multiple years on it **************/
run;

/* create income metric that right now just has the number of total households */
data metrics_income_2021 (keep = statefip county household);
 set number_hhs_2021;
run;

/* create digital access metric that right now just has the number of total households */
data metrics_access_2021 (keep = statefip county household);
 set number_hhs_2021;
run;

/* get total number of rental households that are ELI for the rental metric */
%macro number_of_eli_renters(year);
data renters_&year (keep = statefip county Below30AMI_unw household year);
  set desktop.renters_&year; /* this file should be output by the program compute_metrics_rent.sas */
  if ELI_4 ne . then do;
    Below30AMI_unw = hhincome < ELI_4;  
  end;
  household = 1;
run;

proc means data=renters_&year noprint; 
  output out=number_renters_&year(drop=_type_) sum=;
  by year statefip county;
  var Below30AMI_unw household ;
run;
%mend number_of_eli_renters;
%number_of_eli_renters(year=2021);

/* get state and county in same format 
data house.metrics_rent_2021;
 set house.metrics_rent_2021;
 new_county = input(county, 8.); 
 new_statefip = input(state, 8.);
 drop county state;
 rename new_county = county;
 rename new_statefip = statefip;
run;*/

/* add number of ELI retners to rent metric */
data metrics_rent_2021;
 merge house.metrics_rent_2021 number_renters_2021;
 by /*year*/ statefip county; /************** only need year if dataset has multiple years on it **************/
run;

 
/* Load in each ACS metric and check the sample size in each county. 

The denominator for each of the metrics is as follows:
-College: number of people ages 19 and 20
-Family: number of people under age 18
-Employment: number of people 25-54
-Housing: number of households below 50% of area median income
-Preschool: number of people ages 3 and 4
-Income: total number of households

These denominators are used as the sample size flags
*/
%macro metric(lib= , dataset= , denominator= );
data &dataset. ;
 set &lib..&dataset. ;
 if &denominator < 30 then size_flag = 1;
  else size_flag = 0;
run;
%mend metric;
%metric(lib = edu, dataset = metrics_college_2021, denominator = _FREQ_);
%metric(lib = fam, dataset = metrics_famstruc_2021, denominator = _FREQ_);
%metric(lib = employ, dataset = metrics_employment_2021, denominator = _FREQ_);
%metric(lib = work, dataset = metrics_housing_2021, denominator = Below30AMI_unw);
%metric(lib = edu, dataset = metrics_preschool_2021, denominator = _FREQ_);
%metric(lib = work, dataset = metrics_income_2021, denominator = household);
%metric(lib = work, dataset = metrics_access_2021, denominator = household);
%metric(lib = work, dataset = metrics_rent_2021, denominator = Below30AMI_unw);

/* add a year variable for all datasets except Housing and Rent. This is needed for a later merge, and will allow more years
	of data to be added more easily */
%macro add_year(lib= , dataset= );
data &dataset.;
 set &dataset.;
 year = 2021;
run;
%mend add_year;
%add_year(dataset = metrics_college_2021);
%add_year(dataset = metrics_famstruc_2021);
%add_year(dataset = metrics_employment_2021);
%add_year(dataset = metrics_preschool_2021);
%add_year(dataset = metrics_income_2021);
%add_year(dataset = metrics_access_2021);
*%add_year(dataset = metrics_rent_2021);
%add_year(dataset = metrics_housing_2021);



/****
Next step is to merge the PUMA flag with each individual metric, and then create the final 
data quality metric based on both the SIZE and PUMA flags
****/

/* first need to turn statefip and county back into numeric for preschool metric */
data metrics_preschool_2021;
 set metrics_preschool_2021;
 new_county = input(county, 8.); 
 new_statefip = input(state, 8.);
 drop county state;
 rename new_county = county;
 rename new_statefip = statefip;
run;

proc sort data = metrics_preschool_2021; by statefip county; run;
proc sort data = metrics_housing_2021; by statefip county; run;
proc sort data = metrics_rent_2021; by statefip county; run;

/* this creates the quality metric. Per email from Greg on 9/18/20, 
only ACS metrics with sample size < 30 should be be marked as "3"
This code gives a county a "1" if they have a large sample size and
at least 75% of the data comes from county. If the county has a large
sample size and less than 75% of the data comes from the county, the 
county gets a "2." Small sample size gives a "3" */

%macro flag(dataset= , metric= ); 
data &dataset._flag (keep = state county &metric._quality year);
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
 if state = 15 and county = 5 then &metric._quality = .;
run;


/* tests */
proc freq data = &dataset._flag;
 table &metric._quality;
 title "&dataset.";
run;

%mend flag;

%flag(dataset = metrics_college_2021, metric = share_hs_degree); 
%flag(dataset = metrics_famstruc_2021, metric = famstruc);
%flag(dataset = metrics_employment_2021, metric = share_employed);
%flag(dataset = metrics_housing_2021, metric = share_affordable);
%flag(dataset = metrics_preschool_2021, metric = share_in_preschool);
%flag(dataset = metrics_income_2021, metric = pctl);
%flag(dataset = metrics_access_2021, metric = share_access);
*%flag(dataset = metrics_rent_2021, metric = rent);

/*
proc print data=metrics_housing_flag;
 where housing_quality = 3;
run;
*/

/**** output as CSVs ****/
/* first I infile the original metric CSVs.

	Next, I merge the flag with the infiled csv

	Then, I output as a final CSV */

%macro output(dataset= , folder =, metric = );
proc import datafile="&metrics_folder.&folder.&dataset..csv" out=&dataset._orig dbms=csv replace;
  getnames=yes;
  guessingrows=3000;
  datarow=2;
run;

proc sort data=&dataset._orig;  by year state county; run;
proc sort data=&dataset._flag;  by year state county; run;

data &dataset._final (drop = _FREQ_ quality);
 merge &dataset._orig &dataset._flag;
 by year state county;
 if state = 15 and county = 5 then &metric._quality = 3;
 /* make sure that state and county have leading 0s */
 new_county = put(county, z3.); 
 new_statefip = put(state, z2.);
 drop county state;
 rename new_county = county;
 rename new_statefip = state;
run;

data &dataset._final;
	retain year state county;
 	set &dataset._final;
run;

proc export data= &dataset._final
 outfile = "&metrics_folder.&folder.&dataset..csv"
 replace;
run;
%mend output;
%output(dataset = metrics_college_2021, folder = 08_education\, metric = share_hs_degree); 
%output(dataset = metrics_preschool_2021, folder = 08_education\, metric = share_in_preschool); 
%output(dataset = metrics_famstruc_2021, folder = 03_family\, metric = famstruc); 
%output(dataset = metrics_income_2021, folder = 01_financial-well-being\, metric = pctl); 
%output(dataset = metrics_housing_2021, folder = 02_housing\, metric = share_affordable); 
*%output(dataset = metrics_rent_2021, folder = 02_housing\); 
%output(dataset = metrics_employment_2021, folder = 09_employment\, metric = share_employed); 
*%output(dataset = metrics_access_2021, folder = 06_neighborhoods\); 


/* I want to test if the number of people ages 19 and 20
in the microdata file is the same as the sum of the _FREQ_
variable in the metrics_college file. They should equal */


/* 119258. Wooo, they match 
proc means data = metrics_rent;
 var share_burdened_30_ami share_burdened_50_ami share_burdened_80_ami;
run;

proc univariate data=metrics_rent;
  var share_burdened_80_ami;;
  histogram;
run;
proc univariate data=metrics_rent;
  var  share_burdened_50_ami ;;
  histogram;
run;
proc univariate data=metrics_rent;
  var share_burdened_30_ami  ;;
  histogram;
run;

proc print data=metrics_rent;
 where share_burdened_50_ami > .8;
run;
