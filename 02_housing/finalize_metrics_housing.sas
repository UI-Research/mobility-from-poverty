/*************

This code reads in the affordable housing metrics created by Paul,
puts it in the right format, and outputs it as a csv

I do NOT create confidence intervals for this metric because I don't think 
it's possible to do in this case (for a ratio)

Kevin Werner

7/28/20

*************/

/*

Uses the dataset created by compute_metrics_housing as input

*/

%let filepath = V:\Centers\Ibp\KWerner\Kevin\Mobility\gates-mobility-metrics\02_housing\metrics_housing.csv;

libname paul "V:\Centers\Ibp\KWerner\Kevin\Mobility\gates-mobility-metrics\02_housing";

/* I turned this into a macro so it can easily read both the 2014 and 2018 data */

%macro finalize_housing(year);
data housing_missing_HI_&year (keep = year state county share_affordable_30_ami share_affordable_50_ami share_affordable_80_ami);
 set paul.metrics_housing_&year;
 year = &year;
 new_county = put(county,z3.); 
 state = put(statefip,z2.);
 drop county statefip;
 rename new_county = county;
 rename share_affordable_30AMI = share_affordable_30_ami;
 rename share_affordable_50AMI = share_affordable_50_ami;
 rename share_affordable_80AMI = share_affordable_80_ami;
run;

/* add missing HI county so that there is observation for every county */

data housing_&year;
 set housing_missing_HI_&year end=eof;
 output;
 if eof then do;
  year = &year;
  state = "15";
  county = "005";
  share_affordable_30_ami = .;
  share_affordable_50_ami = .;
  share_affordable_80_ami = .;
  output;
 end;
run;

/* sort final data set and order variables*/

data housing_&year;
 retain year state county;
 set housing_&year;
run;

proc sort data=housing_&year; by year state county; run;

%mend finalize_housing;
%finalize_housing(year = 2014);
%finalize_housing(year = 2018);

/* append the two datasets together */
data housing;
 set housing_2014;
run;

proc append base=housing data=housing_2018;
run;

data paul.metrics_housing;
 set housing;
run;


/* export as csv */

proc export data = housing
  outfile = "&filepath"
  replace;
run;
