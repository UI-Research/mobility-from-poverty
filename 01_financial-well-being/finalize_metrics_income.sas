/*************

This code recreates the income metrics created by Paul, adds confidence intervals,
put it in the right format, and outputs it as a csv

Kevin Werner

7/22/20

NOTE: per email from Greg on 9/10/20, I have removed the confidence interval code.

*************/

%let filepath18 = V:\Centers\Ibp\KWerner\Kevin\Mobility\gates-mobility-metrics\01_financial-well-being\metrics_income_2018.csv;
%let filepath14 = V:\Centers\Ibp\KWerner\Kevin\Mobility\gates-mobility-metrics\01_financial-well-being\metrics_income_2014.csv;

/* this runs on the microdata file output by 3_prepate_microdata */

libname lib2018 "V:\Centers\Ibp\KWerner\Kevin\Mobility\Paul\2018";
libname lib2014 "V:\Centers\Ibp\KWerner\Kevin\Mobility\Paul\2014";

%macro compute_metrics(microdata_file,year);
/******************* income metric *********************/
/* this exactly recreates Paul's percentiles
   based on the procedure described here: 
   https://blogs.sas.com/content/iml/2017/02/22/difference-of-medians-sas.html */

ods select none; ods output ParameterEstimates = income_ci_&year;
proc quantreg data=&microdata_file(where=(pernum=1));
	model hhincome = / quantile = 0.8 0.5 0.2;
	by statefip county;
	weight hhwt;
run;
ods select all;

/* reshape with the quantiles wide so there is only one row per state/county */
proc sort data=income_ci_&year out=income_ci_sorted_&year;
 by statefip county Quantile;
run;

proc transpose data=income_ci_sorted_&year out=out1_&year;
 by statefip county Quantile;
 var Estimate;
run;
proc transpose data=out1_&year delimiter = _ out=income_ci_wide_&year  (drop = _name_);
 by statefip county;
 var col1;
 ID _name_ Quantile;
run;

/* put in proper format */

data metric_income_&year;
 set income_ci_wide_&year;
 year = &year;
 new_county = put(county,z3.); 
 state = put(statefip,z2.);
 drop county statefip;
 rename new_county = county;
 rename Estimate_0_2 = pctl_20;
 rename Estimate_0_5 = pctl_50;
 rename Estimate_0_8 = pctl_80;
run;

/* add missing HI county so that there is observation for every county */

data metrics_income_&year;
 set metric_income_&year end=eof;
 output;
 if eof then do;
  year = 2018;
  state = "15";
  county = "005";
  pctl_20 = .;
  pctl_50 = .;
  pctl_80 = .;
  output;
 end;
run;

/* sort final data set and order variables*/

data metrics_income_&year;
 retain year state county pctl_20 pctl_50 pctl_80;
 set metrics_income_&year;
run;

proc sort data=metrics_income_&year; by year state county; run;
%mend compute_metrics;

/* this is for 2018 */
%compute_metrics(lib2018.microdata,year=2018);

/* this is for 2014 */
%compute_metrics(lib2014.microdata,year=2014);

/* export as csv */

proc export data = metrics_income_2018
  outfile = "&filepath18"
  replace;
run;

proc export data = metrics_income_2014
  outfile = "&filepath14"
  replace;
run;
/*tests

proc univariate data=lib2014.microdata;
 var hhincome;
 weight hhwt;
 where statefip = 1 and county = 1 and pernum=1;
run;

proc means data=lib2018.microdata p20 p50 p80;
 var hhincome;
 weight hhwt;
 where statefip = 1 and county = 1 and pernum=1;;
run;
*/
