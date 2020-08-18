/*************

This code reads in the affordable housing metrics created by Paul,
puts it in the right format, and outputs it as a csv

I do NOT create confidence intervals for this metric because I don't think 
it's possible to do in this case (for a ratio)

Kevin Werner

7/28/20

*************/

%let filepath = V:\Centers\Ibp\KWerner\Kevin\Mobility\metrics_housing.csv;

libname paul "V:\Centers\Ibp\KWerner\Kevin\Mobility\Paul";

data housing_missing_HI (keep = year state county share_affordable_50_ami share_affordable_80_ami);
 set paul.metrics_housing;
 year = 2018;
 new_county = put(county,z3.); 
 state = put(statefip,z2.);
 drop county statefip;
 rename new_county = county;
 rename share_affordable_50AMI = share_affordable_50_ami;
 rename share_affordable_80AMI = share_affordable_80_ami;
run;

/* add missing HI county so that there is observation for every county */

data housing;
 set housing_missing_HI end=eof;
 output;
 if eof then do;
  year = 2018;
  state = "15";
  county = "005";
  share_affordable_50_ami = .;
  share_affordable_80_ami = .;
  output;
 end;
run;

/* sort final data set and order variables*/

data housing;
 retain year state county;
 set housing;
run;

proc sort data=housing; by year state county; run;



/* export as csv */

proc export data = housing
  outfile = "&filepath"
  replace;
run;
