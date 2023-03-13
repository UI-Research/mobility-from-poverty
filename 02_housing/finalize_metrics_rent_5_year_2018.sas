/*************

This code reads in the rental metrics,
puts it in the right format, and outputs it as a csv

Kevin Werner

3/23/21

*************/

/*

Uses the dataset created by compute_metrics_rent as input

*/

%let filepath = V:\Centers\Ibp\KWerner\Kevin\Mobility\gates-mobility-metrics\02_housing\metrics_rent_subgroup.csv;

libname paul "V:\Centers\Ibp\KWerner\Kevin\Mobility\gates-mobility-metrics\02_housing";

/* I turned this into a macro so it can easily read both the 2014 and 2018 data */

data rent_missing_HI_5_year (keep = year state county subgroup share_burdened_30_ami share_burdened_50_ami share_burdened_80_ami
								share_burdened_30_ami_lb share_burdened_30_ami_ub share_burdened_50_ami_lb share_burdened_50_ami_ub
								share_burdened_80_ami_lb share_burdened_80_ami_ub unwgt_below_30_ami unwgt_below_50_ami unwgt_below_80_ami);
 set paul.metrics_rent_5_year;
 new_county = put(county,z3.); 
 state = put(statefip,z2.);
 drop county statefip;
 rename new_county = county;
 year = 2018;
 

 /* compute ub and lb */
 %macro bounds(ami);
 inverse_&ami = 1-share_burdened_&ami;
 interval_&ami = 1.96*sqrt((inverse_&ami*share_burdened_&ami)/unwgt_below_&ami);
 share_burdened_&ami._ub = share_burdened_&ami + interval_&ami;
 share_burdened_&ami._lb = share_burdened_&ami- interval_&ami;
 %mend bounds;
 %bounds(ami = 30_ami);
 %bounds(ami = 50_ami);
 %bounds(ami = 80_ami);

run;




/* add missing HI county so that there is observation for every county */

data metrics_rent_5_year;
 set rent_missing_HI_5_year end=eof;
 output;
 if eof then do;
  state = "15";
  county = "005";
  share_burdened_30_ami = .;
   share_burdened_50_ami = .;
    share_burdened_80_ami = .;
  share_burdened_30_ami_lb =.;
  share_burdened_30_ami_ub =.;
    share_burdened_50_ami_lb =.;
  share_burdened_50_ami_ub =.;
    share_burdened_80_ami_lb =.;
  share_burdened_80_ami_ub =.;
  output;
 end;
run;




/* sort final data set and order variables*/

data metrics_rent_5_year;
 retain year state county;
 set metrics_rent_5_year;
run;

proc sort data=metrics_rent_5_year; by year state county; run;



data metrics_rent_5_year (keep = year state county subgroup share_burdened_80_ami share_burdened_80_ami_ub share_burdened_80_ami_lb share_burdened_50_ami 
		share_burdened_50_ami_ub share_burdened_50_ami_lb share_burdened_30_ami share_burdened_30_ami_ub share_burdened_30_ami_lb);
 retain year state county share_burdened_80_ami share_burdened_80_ami_ub share_burdened_80_ami_lb share_burdened_50_ami 
		share_burdened_50_ami_ub share_burdened_50_ami_lb share_burdened_30_ami share_burdened_30_ami_ub share_burdened_30_ami_lb;
 set metrics_rent_5_year;
run;


/* export as csv */

proc export data = metrics_rent_5_year
  outfile = "&filepath"
  replace;
run;
