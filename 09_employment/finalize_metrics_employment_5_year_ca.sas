/*************

This code reads in the employment metric created for the CA request, adds confidence intervals,
put it in the right format, and outputs it as a csv

Kevin Werner

5/3/21

*************/

/* 

This uses the SAS dataset created by compute_metrics_employment program
as input.

*/

/* create confidence interval and correctly format variables */

libname CA_req "V:\Centers\Ibp\KWerner\Kevin\Mobility\gates-mobility-metrics\09_employment\CA request";

%let suppress = 30;

data employment (keep = year county state subgroup subgroup_type broad_ind share_employed share_employed_ub share_employed_lb _FREQ_)  ;
 set CA_req.metrics_employment_subgroup;
 year = 2018;
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
 subgroup_type = "race-ethnicity";
run;

/* create PUMA quality metric (usually done in data quality program but done here for CA request) */

libname puma "V:\Centers\Ibp\KWerner\Kevin\Mobility\Paul";

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
 where statefip = 6 and county in (1, 13, 41, 55, 75, 81, 85, 95, 97);
 state = statefip;
 if sum_products ne . then do;
  if sum_products >= 0.75 then puma_flag = 1; /* create indicator */
   else if sum_products < 0.75 and sum_products >= 0.35 then puma_flag = 2;
   else if sum_products < 0.35 then puma_flag = 3; 
  end;
  else puma_flag = .;
 new_county = put(county, z3.); 
 new_statefip = put(state, z2.);
 drop county state;
 rename new_county = county;
 rename new_statefip = state;
  
run;

data employment_with_flag;
 merge employment puma_county;
 by state county;

/* create size quality metric */
 if _FREQ_ < 100 then size_flag = 1;
  else size_flag = 0;

/* create final quality metric */
 if size_flag = 0 then do; 
  if puma_flag = 1 then employed_quality = 1;
  else if puma_flag = 2 then employed_quality = 2;
  else if puma_flag = 3 then employed_quality = 2;
 end;
 else if size_flag = 1 then employed_quality = 3;
 else employed_quality = .;

 run;

/* sort final data set and order variables*/

data employment_with_flag (drop = pop10	afact AFACT2 statefip puma products sum_products county_pop puma_flag size_flag);
 retain year state county subgroup_type subgroup broad_ind;
 set employment_with_flag;

run;

proc sort data=employment_with_flag; by year state county subgroup broad_ind; run;

/* export as csv */

proc export data = employment_with_flag
  outfile = "V:\Centers\Ibp\KWerner\Kevin\Mobility\gates-mobility-metrics\09_employment\CA request\CA_employment.csv"
  replace;
run;

/********************/

