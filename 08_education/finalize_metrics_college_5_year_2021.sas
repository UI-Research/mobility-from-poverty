/*************

This code reads in the college readiness metric created by compute_metrics_college_5_year_2021 adds confidence intervals,
put it in the right format, and outputs it as a csv

Kevin Werner

3/15/23

*************/


%let suppress = 30;

%let college_filepath = V:\Centers\Ibp\KWerner\Kevin\Mobility\gates-mobility-metrics\08_education\metrics_college_subgroup_2021.csv;

/***** create confidence interval and correctly format variables *******/

data college_missing_HI (keep = year county state share_hs_degree share_hs_degree_ub share_hs_degree_lb _FREQ_ subgroup subgroup_type)  ;
 set edu.metrics_college_subgroup_2021;
 year = 2021;
 /* suppress values under 30 */
 if _FREQ_ >= 0 and _FREQ_ < &suppress then share_with_HSdegree = .;


 no_hs_degree = 1 - share_with_HSdegree;
 interval = 1.96*sqrt((no_hs_degree*share_with_HSdegree)/_FREQ_); /* _FREQ_ is the unweighted count of people 19-20 */
 share_hs_degree_ub = share_with_HSdegree + interval;
 share_hs_degree_lb = share_with_HSdegree - interval;
 if share_hs_degree_ub > 1 then share_hs_degree_ub = 1;
 if share_hs_degree_lb ne . and share_hs_degree_lb < 0 then share_hs_degree_lb = 0;

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
  subgroup = 1;
  share_hs_degree = "";
  share_hs_degree_ub = "";
  share_hs_degree_lb = "";
  _FREQ_ = .;
  output;
 end;
run;
data metrics_college_ready;
 set metrics_college_ready end=eof;
 output;
 if eof then do;
  year = 2021;
  state = "15";
  county = "005";
  subgroup = 2;
  share_hs_degree = "";
  share_hs_degree_ub = "";
  share_hs_degree_lb = "";
   _FREQ_ = .;
  output;
 end;
run;
data metrics_college_ready;
 set metrics_college_ready end=eof;
 output;
 if eof then do;
  year = 2021;
  state = "15";
  county = "005";
  subgroup = 3;
  share_hs_degree = "";
  share_hs_degree_ub = "";
  share_hs_degree_lb = "";
   _FREQ_ = .;
  output;
 end;
run;
data metrics_college_ready;
 set metrics_college_ready end=eof;
 output;
 if eof then do;
  year = 2021;
  state = "15";
  county = "005";
  subgroup = 4;
  share_hs_degree = "";
  share_hs_degree_ub = "";
  share_hs_degree_lb = "";
   _FREQ_ = .;
  output;
 end;
run;
data metrics_college_ready;
 set metrics_college_ready end=eof;
 output;
 if eof then do;
  year = 2021;
  state = "15";
  county = "005";
  subgroup = .;
  share_hs_degree = "";
  share_hs_degree_ub = "";
  share_hs_degree_lb = "";
   _FREQ_ = .;
  output;
 end;
run;



/* sort final data set and order variables and add formats*/

PROC FORMAT ;
PICTURE Num    .="NA"
				OTHER = "9.99999";
			 run;

data metrics_college_ready;
 retain year state county subgroup_type subgroup  share_hs_degree share_hs_degree_ub share_hs_degree_lb;
 set metrics_college_ready;
 if share_hs_degree = . and _FREQ_ >= &suppress then share_hs_degree = 0;
 if share_hs_degree_ub = . and _FREQ_ >= &suppress then share_hs_degree_ub = 0;
 if share_hs_degree_lb = . and _FREQ_ >= &suppress then share_hs_degree_lb = 0;
 if subgroup in (1,2,3,4) then subgroup_type = "race-ethnicity";
 else subgroup_type = "all";
 format share_hs_degree num. share_hs_degree_ub num. share_hs_degree_lb num.;
run;

proc sort data=metrics_college_ready; by year state county subgroup; run;



/* export as csv */

proc export data = metrics_college_ready
  outfile = "&college_filepath"
  replace;
run;
