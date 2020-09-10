/*************

This code reads in the employment metric created by Paul, adds confidence intervals,
put it in the right format, and outputs it as a csv

Kevin Werner

7/28/20

*************/

/* 

This uses the SAS dataset created by Paul's compute_metrics_employment program
as input.

*/

%let filepath = V:\Centers\Ibp\KWerner\Kevin\Mobility\gates-mobility-metrics\09_employment\metrics_employment.csv;

libname paul "V:\Centers\Ibp\KWerner\Kevin\Mobility\gates-mobility-metrics\09_employment";

/* create confidence interval and correctly format variables */

data employment_missing_HI (keep = year county state share_employed share_employed_ub share_employed_lb)  ;
 set paul.metrics_unemployment;
 year = 2018;
 not_employed = 1 - share_employed;
 interval = 1.96*sqrt((not_employed*share_employed)/_FREQ_);
 share_employed_ub = share_employed + interval;
 share_employed_lb = share_employed - interval;

 new_county = put(county,z3.); 
 state = put(statefip,z2.);
 drop county statefip;
 rename new_county = county;
run;

/* add missing HI county so that there is observation for every county */

data employment;
 set employment_missing_HI end=eof;
 output;
 if eof then do;
  year = 2018;
  state = "15";
  county = "005";
  share_employed = .;
  share_employed_ub = .;
  share_employed_lb = .;
  output;
 end;
run;

/* sort final data set and order variables*/

data employment;
 retain year state county ;
 set employment;
run;

proc sort data=employment; by year state county; run;

/* export as csv */

proc export data = employment
  outfile = "&filepath"
  replace;
run;
