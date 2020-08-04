/*************

This code recreates the income metrics created by Paul, adds confidence intervals,
put it in the right format, and outputs it as a csv

Kevin Werner

7/22/20

*************/

%let filepath = V:\Centers\Ibp\KWerner\Kevin\Mobility\metrics_income.csv;

libname paul "V:\Centers\Ibp\KWerner\Kevin\Mobility\Paul";


/******************* income metric *********************/
/* this exactly recreates Paul's percentiles, and adds confidence intervals
   based on the procedure described here: 
   https://blogs.sas.com/content/iml/2017/02/22/difference-of-medians-sas.html */

ods select none; ods output ParameterEstimates = income_ci;
proc quantreg data=paul.microdata(where=(pernum=1));
	model hhincome = / quantile = 0.8 0.5 0.2;
	by statefip county;
	weight hhwt;
run;
ods select all;

/* reshape with the quantiles wide so there is only one row per state/county */
proc sort data=income_ci out=income_ci_sorted;
 by statefip county Quantile;
run;

proc transpose data=income_ci_sorted out=out1;
 by statefip county Quantile;
 var Estimate LowerCL UpperCL;
run;
proc transpose data=out1 delimiter = _ out=income_ci_wide  (drop = _name_);
 by statefip county;
 var col1;
 ID _name_ Quantile;
run;

/* put in proper format */

data metric_income;
 set income_ci_wide;
 year = 2018;
 new_county = put(county,z3.); 
 state = put(statefip,z2.);
 drop county statefip;
 rename new_county = county;
 rename Estimate_0_2 = pctl_20;
 rename LowerCL_0_2 = pctl_20_lb;
 rename UpperCL_0_2 = pctl_20_ub;
 rename Estimate_0_5 = pctl_50;
 rename LowerCL_0_5 = pctl_50_lb;
 rename UpperCL_0_5 = pctl_50_ub;
 rename Estimate_0_8 = pctl_80;
 rename LowerCL_0_8 = pctl_80_lb;
 rename UpperCL_0_8 = pctl_80_ub;
run;

/* add missing HI county so that there is observation for every county */

data metrics_income;
 set metric_income end=eof;
 output;
 if eof then do;
  year = 2018;
  state = "15";
  county = "005";
  pctl_20 = .;
  pctl_20_lb = .;
  pctl_20_ub = .;
  pctl_50 = .;
  pctl_50_lb = .;
  pctl_50_ub = .;
  pctl_80 = .;
  pctl_80_lb = .;
  pctl_80_ub = .;
  output;
 end;
run;

/* sort final data set and order variables*/

data metrics_income;
 retain year state county pctl_20 pctl_20_ub pctl_20_lb pctl_50 pctl_50_ub pctl_50_lb pctl_80 pctl_80_ub pctl_80_lb;
 set metrics_income;
run;

proc sort data=metrics_income; by year state county; run;

/* export as csv */

proc export data = metrics_income
  outfile = "&filepath"
  replace;
run;
