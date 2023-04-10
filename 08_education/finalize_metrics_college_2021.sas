/*************

This code reads in the college readiness metric created by Paul, adds confidence intervals,
put it in the right format, and outputs it as a csv

Kevin Werner

7/28/20

*************/

/* 

You need metrics_college to run this code.

I put metrics_college in the 08_education subfolder of the repository.

*/

%let filepath = V:\Centers\Ibp\KWerner\Kevin\Mobility\gates-mobility-metrics\08_education\metrics_college_2021.csv;

libname edu "V:\Centers\Ibp\KWerner\Kevin\Mobility\gates-mobility-metrics\08_education";


/***** create confidence interval and correctly format variables *******/

data college_missing_HI (keep = year county state share_hs_degree share_hs_degree_ub share_hs_degree_lb _FREQ_)  ;
 set edu.metrics_college_2021;
 year = 2021;
 no_hs_degree = 1 - share_with_HSdegree;
 interval = 1.96*sqrt((no_hs_degree*share_with_HSdegree)/_FREQ_); /* _FREQ_ is the unweighted count of people 19-20 */
 share_hs_degree_ub = share_with_HSdegree + interval;
 share_hs_degree_lb = share_with_HSdegree - interval;

 if share_hs_degree_ub > 1 then share_hs_degree_ub = 1;
 if share_hs_degree_lb < 0 then share_hs_degree_lb = 0;

 /* put variables in correct format */
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
  year = 2021;
  state = "15";
  county = "005";
  share_hs_degree = "";
  share_hs_degree_ub = "";
  share_hs_degree_lb = "";
  output;
 end;
run;


/* sort final data set and order variables*/

PROC FORMAT ;
PICTURE Num    .="NA"
				OTHER = "9.99999";
			 run;

data metrics_college_ready;
 retain year state county share_hs_degree share_hs_degree_ub share_hs_degree_lb;
 set metrics_college_ready;
 format share_hs_degree share_hs_degree_ub share_hs_degree_lb num.;
run;

proc sort data=metrics_college_ready; by year state county; run;



/* export as csv */

proc export data = metrics_college_ready
  outfile = "&filepath"
  replace;
run;
