/*************

This code reads in the employment metric created by compute_metrics_employment_5_year_2021, adds confidence intervals,
put it in the right format, and outputs it as a csv

Kevin Werner

3/15/23

*************/


%let employ_filepath = V:\Centers\Ibp\KWerner\Kevin\Mobility\gates-mobility-metrics\09_employment\metrics_employ_subgroup_2021.csv;

%let suppress = 30;

/* create confidence interval and correctly format variables */

data employment_missing_HI (keep = year county state subgroup subgroup_type share_employed share_employed_ub share_employed_lb _FREQ_)  ;
 set employ.metrics_employ_subgroup_2021;
 year = 2021;
 /* suppress values under 30 */
 if _FREQ_ >= 0 and _FREQ_ < &suppress then share_employed = .;


 not_employed = 1 - share_employed;
 interval = 1.96*sqrt((not_employed*share_employed)/_FREQ_);
 share_employed_ub = share_employed + interval;
 share_employed_lb = share_employed - interval;
 if share_employed_ub > 1 then share_employed_ub = 1;
 if share_employed_lb ne .  and share_employed_lb < 0 then share_employed_lb = 0;

 new_county = put(county,z3.); 
 state = put(statefip,z2.);
 drop county statefip;
 rename new_county = county;

 if share_employed = . and _FREQ_ >= &suppress then share_employed = 0;
 if share_employed_ub = . and _FREQ_ >= &suppress then share_employed_ub = 0;
 if share_employed_lb = . and _FREQ_ >= &suppress then share_employed_lb = 0;
 if subgroup in (1,2,3,4) then subgroup_type = "race-ethnicity";
 else subgroup_type = "all";
run;

/* add missing HI county so that there is observation for every county */

data employment;
 set employment_missing_HI end=eof;
 output;
 if eof then do;
  year = 2021;
  state = "15";
  county = "005";
  subgroup_type = "race-ethnicity";
  share_employed = .;
  share_employed_ub = .;
  share_employed_lb = .;
  _FREQ_ = .;
  do subgroup = 1 to 4;
   output;
  end;
  subgroup_type = "all";
  subgroup = .;
  output;
 end;
run;

/* sort final data set and order variables and add formats*/

PROC FORMAT ;
PICTURE Num    .="NA"
				OTHER = "9.99999";
			 run;

data employment;
 retain year state county subgroup_type subgroup ;
 set employment;
 format share_employed share_employed_ub share_employed_lb num.;
run;

proc sort data=employment; by year state county subgroup; run;

/* export as csv */

proc export data = employment
  outfile = "&employ_filepath"
  replace;
run;
