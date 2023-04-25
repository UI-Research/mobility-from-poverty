/* this metric computes what share of extremely low, very low, and low
   income households are extremely rent burdened */

libname housing "V:\Centers\Ibp\KWerner\Kevin\Mobility\gates-mobility-metrics\02_housing";
libname desktop "C:\Users\kwerner\Desktop\Metrics";

options fmtsearch=(lib2018);

%macro compute_metrics_rent(microdata_file,metrics_file,year);
* Prepare a file containing HUD income levels for each county. This requires first
  importing a file with the income limits for each FMR, as well as a file that 
  includes the population for each FMR;
proc import datafile="&networkDir.\Section8-FY&year..csv" out=FMR_Income_Levels_&year dbms=csv replace;
  getnames=yes;
  guessingrows=100;
  datarow=2;
run;

data FMR_Income_levels_&year;
 set FMR_Income_levels_&year;
 rename state = statefip;
run;

data FMR_Income_levels_2014;
 set FMR_Income_levels_2014;
 if statefip = 2 and county = 270 then county = 158;
run;

proc sort data=FMR_Income_levels_2014; by statefip county; run;

/* calculate rent burden for each AMI group */
data desktop.renters_&year;
  merge &microdata_file.(in=a where=(pernum=1 and ownershp=2)) FMR_Income_Levels_&year(in=b keep=statefip county L50_4 L80_4 ELI_4);
  by statefip county; /*bring in heads of household for renters */
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


/* summarize by county */
proc means data=desktop.renters_&year noprint; 
  output out=renters_summed_wgt_&year(drop=_type_ _FREQ_) sum=;
  by statefip county;
  var below_80_ami rent_burden_80AMI below_50_ami rent_burden_50AMI below_30_ami rent_burden_30AMI;
  weight hhwt;
run;
data &metrics_file.;
  set renters_summed_&year;
  by statefip county;
  if below_80_ami ne . then share_burdened_80_AMI = rent_burden_80AMI/below_80_ami;
  if below_50_ami ne . then share_burdened_50_AMI = rent_burden_50AMI/below_50_ami;
  if below_30_ami ne . then share_burdened_30_AMI = rent_burden_30AMI/below_30_ami;
run;

/* get unweighted count in each county for each metric */
proc means data=desktop.renters_&year noprint; 
  output out=renters_unwgt_&year(drop=_type_ _FREQ_) sum=;
  by statefip county;
  var below_80_ami below_50_ami below_30_ami;
run;


/* change names so they do not overlap with weighted var names */
data renters_unwgt_&year (drop = below_80_ami below_50_ami below_30_ami);
 set renters_unwgt_&year;
 unwgt_below_80_ami = below_80_ami;
 unwgt_below_50_ami = below_50_ami;
 unwgt_below_30_ami = below_30_ami;
run;

/* merge on unweighted */
data renters_summed_&year;
 merge renters_summed_wgt_&year renters_unwgt_&year;
 by statefip county;
run;
%mend compute_metrics_rent;
/* this is for 2018 */
%compute_metrics_rent(lib2018.microdata, housing.metrics_rent_2018,year=2018);

/* this is for 2014 */
%compute_metrics_rent(lib2014.microdata, housing.metrics_rent_2014,year=2014);


proc means data=housing.metrics_rent_2014;
var share_burdened_80_AMI share_burdened_50_AMI share_burdened_30_AMI;
title '2014';
run;

proc means data=housing.metrics_rent_2018;
var share_burdened_80_AMI share_burdened_50_AMI share_burdened_30_AMI;
title '2018';
run;
