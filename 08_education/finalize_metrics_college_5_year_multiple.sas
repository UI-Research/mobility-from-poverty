/*************

This code reads in the datasets created by compute_metrics_college_multiple and crates the CSVs

Kevin Werner

1/12/22

*************/



/***** create confidence interval and correctly format variables *******/

%let &suppress = 30;

%macro finalize(input, missing_HI, final, year);

data &missing_HI (keep = year county state share_hs_degree share_hs_degree_ub share_hs_degree_lb _FREQ_ subgroup subgroup_type)  ;
 set edu.&input;
 year = &year;
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

data &final;
 set &missing_HI end=eof;
 output;
 if eof then do;
  year = &year;
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
data &final;
 set &final end=eof;
 output;
 if eof then do;
  year = &year;
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
data &final;
 set &final end=eof;
 output;
 if eof then do;
  year = &year;
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
data &final;
 set &final end=eof;
 output;
 if eof then do;
  year = &year;
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


/* sort final data set and order variables*/

data &final;
 retain year state county subgroup_type subgroup  share_hs_degree share_hs_degree_ub share_hs_degree_lb;
 set &final;
 if share_hs_degree = . and _FREQ_ >= &suppress then share_hs_degree = 0;
 if share_hs_degree_ub = . and _FREQ_ >= &suppress then share_hs_degree_ub = 0;
 if share_hs_degree_lb = . and _FREQ_ >= &suppress then share_hs_degree_lb = 0;
 subgroup_type = "race-ethnicity";
run;

proc sort data=&final; by year state county subgroup; run;



/* export as csv */

proc export data = &final
  outfile = "V:\Centers\Ibp\KWerner\Kevin\Mobility\gates-mobility-metrics\08_education\college_5_year&year..csv"
  replace;
run;

%mend finalize;
%finalize(metrics_college_5_2019, missing_HI_2019, college_2019, 2019);
%finalize(metrics_college_5_2018, missing_HI_2018, college_2018, 2018);
%finalize(metrics_college_5_2017, missing_HI_2017, college_2017, 2017);
%finalize(metrics_college_5_2016, missing_HI_2016, college_2016, 2016);
%finalize(metrics_college_5_2015, missing_HI_2015, college_2015, 2015);
