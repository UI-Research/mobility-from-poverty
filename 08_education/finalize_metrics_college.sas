/*************

This code reads in the college readiness metric created by Paul, adds confidence intervals,
put it in the right format, and outputs it as a csv

Kevin Werner

7/28/20

*************/

%let filepath = V:\Centers\Ibp\KWerner\Kevin\Mobility\metrics_college_ready.csv;

libname paul "V:\Centers\Ibp\KWerner\Kevin\Mobility\Paul";

/* create confidence interval and correctly format variables */

data college_missing_HI (keep = year county state share_hs_degree share_hs_degree_ub share_hs_degree_lb)  ;
 set paul.metrics_college;
 year = 2018;
 no_hs_degree = 1 - share_with_HSdegree;
 interval = 1.96*sqrt((no_hs_degree*share_with_HSdegree)/num_19_and_20);
 share_hs_degree_ub = share_with_HSdegree + interval;
 share_hs_degree_lb = share_with_HSdegree - interval;

 new_county = put(county,z3.); 
 state = put(statefip,z2.);
 drop county statefip;
 rename new_county = county;
 rename share_with_HSdegree = share_hs_degree;
run;


/* add missing HI county so that there is observation for every county */

data metrics_college_ready;
 set college_missing_HI end=eof;
 output;
 if eof then do;
  year = 2018;
  state = "15";
  county = "005";
  share_hs_degree = "";
  share_hs_degree_ub = "";
  share_hs_degree_lb = "";
  output;
 end;
run;


/* sort final data set and order variables*/

data metrics_college_ready;
 retain year state county share_hs_degree share_hs_degree_ub share_hs_degree_lb;
 set metrics_college_ready;
run;

proc sort data=metrics_college_ready; by year state county; run;



/* export as csv */

proc export data = metrics_college_ready
  outfile = "&filepath"
  replace;
run;
