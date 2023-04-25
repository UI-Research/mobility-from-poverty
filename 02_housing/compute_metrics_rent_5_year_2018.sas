/* this metric computes what share of extremely low, very low, and low
   income households are extremely rent burdened

5 year data used for race metrics*/

libname housing "V:\Centers\Ibp\KWerner\Kevin\Mobility\gates-mobility-metrics\02_housing";

options fmtsearch=(lib2018);


 Proc format;
  Value subgroup_f ( default = 30)
 4 = "White, Non-Hispanic"
 1 = "Black, Non-Hispanic"
 3 = "Other Races and Ethnicities"
 2 = "Hispanic"
;

run;



* Prepare a file containing HUD income levels for each county. This requires first
  importing a file with the income limits for each FMR, as well as a file that 
  includes the population for each FMR;
*2018;
proc import datafile="&networkDir.\Section8-FY2018.csv" out=FMR_Income_Levels_2018 dbms=csv replace;
  getnames=yes;
  guessingrows=100;
  datarow=2;
run;
data FMR_Income_levels_2018 (keep=year statefip county L50_4 L80_4 ELI_4);
 set FMR_Income_levels_2018;
 rename state = statefip;
 year = 2018;
run;

/*note that in previous metric I imported FMR limits for each year in the 5-year file
  I don't think this is actually necessary because the income variables are adjusted for
  inflation to the last year in the 5-year file.
*/
	
/*
*2017;
proc import datafile="&networkDir.\Section8-FY2017.csv" out=FMR_Income_Levels_2017 dbms=csv replace;
  getnames=yes;
  guessingrows=100;
  datarow=2;
run;
data FMR_Income_levels_2017 (keep=multyear statefip county L50_4 L80_4 ELI_4);
 set FMR_Income_levels_2017;
 rename state = statefip;
 multyear = 2017;
run;

*2016;
proc import datafile="&networkDir.\Section8-FY2016.csv" out=FMR_Income_Levels_2016 dbms=csv replace;
  getnames=yes;
  guessingrows=100;
  datarow=2;
run;
data FMR_Income_levels_2016(keep=multyear statefip county L50_4 L80_4 ELI_4);
 set FMR_Income_levels_2016;
 rename state = statefip;
 multyear = 2016;
run;

*2015;
proc import datafile="&networkDir.\Section8-FY2015.csv" out=FMR_Income_Levels_2015 dbms=csv replace;
  getnames=yes;
  guessingrows=100;
  datarow=2;
run;
data FMR_Income_levels_2015(keep=multyear statefip county L50_4 L80_4 ELI_4);
 set FMR_Income_levels_2015;
 rename state = statefip;
 multyear = 2015;
run;

*2014;
proc import datafile="&networkDir.\Section8-FY2014.csv" out=FMR_Income_Levels_2014 dbms=csv replace;
  getnames=yes;
  guessingrows=100;
  datarow=2;
run;
data FMR_Income_levels_2014(keep=multyear statefip county L50_4 L80_4 ELI_4);
 set FMR_Income_levels_2014;
 rename state = statefip;
 multyear = 2014;
run;


proc append base=FMR_Income_levels_2018 data=FMR_Income_levels_2017;
run;
proc append base=FMR_Income_levels_2018 data=FMR_Income_levels_2016;
run;
proc append base=FMR_Income_levels_2018 data=FMR_Income_levels_2015;
run;
proc append base=FMR_Income_levels_2018 data=FMR_Income_levels_2014;
run;
*/

proc sort data = lib2018.microdata_5_year; by year statefip county; run;
proc sort data = FMR_Income_Levels_2018; by year statefip county; run;

%macro compute_metrics_rent(microdata_file,metrics_file);


/* calculate rent burden for each AMI group */
data desktop.renters_5_year;
  merge &microdata_file.(in=a where=(pernum=1 and ownershp=2)) FMR_Income_Levels_2018(in=b keep=year statefip county L50_4 L80_4 ELI_4);
  by multyear statefip county; /*bring in heads of household for renters */
  if a;
  if L80_4 ne . then do;
    below_80_ami = hhincome < L80_4;  
	if below_80_ami = 1 and ((rentgrs*12) > (hhincome/2)) then rent_burden_80AMI = 1; /*is rent > 50% of income? */
	 else rent_burden_80AMI = 0;
  end;
  if L50_4 ne . then do;
    below_50_ami = hhincome < L50_4;  
	if below_50_ami = 1 and ((rentgrs*12) > (hhincome/2)) then rent_burden_50AMI = 1;
	 else rent_burden_50AMI = 0;
  end;
  if ELI_4 ne . then do;
    below_30_ami = hhincome < ELI_4;  
	if below_30_ami = 1 and ((rentgrs*12) > (hhincome/2)) then rent_burden_30AMI = 1;
	 else rent_burden_30AMI = 0;
  end;
run;

proc sort data = desktop.renters_5_year; by statefip county ; run;


/* summarize by county */
proc means data=desktop.renters_5_year noprint; 
  output out=renters_summed_wgt_5_year(drop=_type_ _FREQ_) sum=;
  by statefip county ;
  var below_80_ami rent_burden_80AMI below_50_ami rent_burden_50AMI below_30_ami rent_burden_30AMI;
  weight hhwt;
  class subgroup /preloadfmt ;
  format subgroup subgroup_f.; 
run;
data renters_summed_wgt_5_year;
  set renters_summed_wgt_5_year;
  by statefip county subgroup;
  if below_80_ami ne . then share_burdened_80_AMI = rent_burden_80AMI/below_80_ami;
  if below_50_ami ne . then share_burdened_50_AMI = rent_burden_50AMI/below_50_ami;
  if below_30_ami ne . then share_burdened_30_AMI = rent_burden_30AMI/below_30_ami;
run;

/* get unweighted count in each county for each metric */
proc means data=desktop.renters_5_year noprint; 
  output out=renters_unwgt_5_year(drop=_type_ _FREQ_) sum=;
  by statefip county;
  var below_80_ami below_50_ami below_30_ami;
    class subgroup /preloadfmt ;
  format subgroup subgroup_f.; 
run;


/* change names so they do not overlap with weighted var names */
data renters_unwgt_5_year (drop = below_80_ami below_50_ami below_30_ami);
 set renters_unwgt_5_year;
 unwgt_below_80_ami = below_80_ami;
 unwgt_below_50_ami = below_50_ami;
 unwgt_below_30_ami = below_30_ami;
run;

/* merge on unweighted */
data housing.metrics_rent_5_year;
 merge renters_summed_wgt_5_year renters_unwgt_5_year;
 by statefip county subgroup;
 if subgroup = . then delete;
run;
%mend compute_metrics_rent;
/* this is for 2018 */
%compute_metrics_rent(lib2018.microdata_5_year, housing.metrics_rent_5_year_2018);

/*
proc means data=housing.metrics_rent_5_year;
var share_burdened_80_AMI share_burdened_50_AMI share_burdened_30_AMI;
where subgroup =.;
run;


proc means data=desktop.renters_5_year noprint; 
  output out=mn_test(drop=_type_ _FREQ_) sum=;
  by statefip county ;
  var below_80_ami rent_burden_80AMI below_50_ami rent_burden_50AMI below_30_ami rent_burden_30AMI;
  where MULTYEAR = 2018 and statefip = 27 and county = 123;
run;

proc means data=desktop.renters_2018 noprint; 
  output out=mn_test2(drop=_type_ _FREQ_) sum=;
  by statefip county ;
  var below_80_ami rent_burden_80AMI below_50_ami rent_burden_50AMI below_30_ami rent_burden_30AMI;
  where statefip = 27 and county = 123;
run;

proc means data=desktop.renters_5_year noprint; 
  output out=mn_test3(drop=_type_ _FREQ_) sum=;
  by statefip county ;
  var below_80_ami rent_burden_80AMI below_50_ami rent_burden_50AMI below_30_ami rent_burden_30AMI;
  where statefip = 27 and county = 123;
run;
*/
