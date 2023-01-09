/*************

This code reads in the rental metrics,
puts it in the right format, and outputs it as a csv

Kevin Werner

3/23/21

*************/

/*

Uses the dataset created by compute_metrics_rent as input

*/

%let filepath = V:\Centers\Ibp\KWerner\Kevin\Mobility\gates-mobility-metrics\02_housing\metrics_rent_2021.csv;

libname paul "V:\Centers\Ibp\KWerner\Kevin\Mobility\gates-mobility-metrics\02_housing";

/* I turned this into a macro so it can easily read both the 2014 and 2018 data */

%macro finalize_rent(year);
data rent_missing_HI_&year (keep = year state county share_burdened_30_ami share_burdened_50_ami share_burdened_80_ami
								share_burdened_30_ami_lb share_burdened_30_ami_ub share_burdened_50_ami_lb share_burdened_50_ami_ub
								share_burdened_80_ami_lb share_burdened_80_ami_ub unwgt_below_30_ami unwgt_below_50_ami unwgt_below_80_ami);
 set paul.metrics_rent_&year;
 year = &year;
 new_county = put(county,z3.); 
 state = put(statefip,z2.);
 drop county statefip;
 rename new_county = county;
 

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

data rent_&year;
 set rent_missing_HI_&year end=eof;
 output;
 if eof then do;
  year = &year;
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

data rent_&year;
 retain year state county;
 set rent_&year;
run;

proc sort data=rent_&year; by year state county; run;

%mend finalize_rent;
%finalize_rent(year = 2021);


/* append the two datasets together 
data rent;
 set rent_2014;
run;

proc append base=rent data=rent_2018;
run;*/

data paul.metrics_rent (keep = year state county share_burdened_80_ami share_burdened_80_ami_ub share_burdened_80_ami_lb share_burdened_50_ami 
		share_burdened_50_ami_ub share_burdened_50_ami_lb share_burdened_30_ami share_burdened_30_ami_ub share_burdened_30_ami_lb);
 retain year state county share_burdened_80_ami share_burdened_80_ami_ub share_burdened_80_ami_lb share_burdened_50_ami 
		share_burdened_50_ami_ub share_burdened_50_ami_lb share_burdened_30_ami share_burdened_30_ami_ub share_burdened_30_ami_lb;
 set rent_2021;
run;


/* export as csv */

proc export data = paul.metrics_rent
  outfile = "&filepath"
  replace;
run;
