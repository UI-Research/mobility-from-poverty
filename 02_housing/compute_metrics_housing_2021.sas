*=================================================================;
*Compute county-level hosuing metrics;
*=================================================================;
libname housing "V:\Centers\Ibp\KWerner\Kevin\Mobility\gates-mobility-metrics\02_housing";
libname desktop "S:\KWerner\Metrics";

options fmtsearch=(lib2021);

%macro compute_metrics_housing(microdata_file,vacant_file,metrics_file,year);
* Prepare a file containing HUD income levels for each county. This requires first
  importing a file with the income limits for each FMR, as well as a file that 
  includes the population for each FMR;
proc import datafile="&networkDir.\Section8-FY&year..csv" out=FMR_Income_Levels_&year dbms=csv replace;
  getnames=yes;
  guessingrows=100;
  datarow=2;
run;
proc import datafile="&networkDir.\FY&year._4050_FMRs_rev.csv" out=FMR_pop_&year dbms=csv replace
;
  getnames=yes;
  guessingrows=100;
  datarow=2;
run;

/*
data FMR_Income_levels_2014;
 set FMR_Income_levels_2014;
 if state = 2 and county = 270 then county = 158;
run;

proc sort data=FMR_Income_levels_2014; by fips2010; run;
*/

*Convert the FMR code on the population file from a character string to a number,
 and add the population variable onto the income level file;
/*data FMR_pop;
  set FMR_pop(rename=(fips2010=fips2010_char));
  fips2010=input(fips2010_char,10.);
run;*/
data FMR_Income_Levels_&year;
  merge FMR_Income_Levels_&year FMR_pop_&year(keep=fips2010 pop2017);
  by fips2010;
run;
*Make some final adjustments to the income file so it can be matched to the ACS microdata by counties;
data FMR_Income_Levels_&year;
  set FMR_Income_Levels_&year(rename=(county=countytemp));
  length statefip 3;
  length county 4;
  statefip=state;
  county=mod(countytemp,1000);/*the last 3-digits are the county code (first 2 are state)*/
  drop state countytemp;
  /*these 2 FMRs appear in the income file but not in the file with population, and it was decided to drop them*/
  if fips2010 in (3608799998,3611999998) then delete;
  /*Provide populations for FMRs missing from population file*/
  /*(Jurisdictions may no longer exist)*/
  if fips2010=2300742765 and pop2017=. then pop2017=173;
  if fips2010=2302911755 and pop2017=. then pop2017=26;
run;
/*Most FMRs have a one-to-one correspondence with counties. However, some counties (mainly in New England)
 contain multiple FMRs. For these counties, replace the multiple FMR records with just
 one county record, using the weighted average value of the income levels, weighted 
 by the FMR population.*/
proc means data=FMR_Income_Levels_&year nway noprint;
 class statefip county;
 var L50_1-L50_8 ELI_1-ELI_8 L80_1-L80_8 ;
 weight pop2017;
 output out=County_income_limits_&year n=num_of_FMRs mean=;
run;

*Merge on the 80% and 50% AMI income levels and determine:
  1) which households are <= 80% and <= 50% of AMI for a family of 4 
     (regardless of the actual household size!!!). 
  2) which units are affordable for a family of 4 at 80% and 50% of AMI
     (regardless of the actual unit size!!!). "Affordable" means costs are < 30% of the AMI
	 (again, for a family of 4!!!). For owners, use the housing cost, and for renters, use the gross rent.
NOTE: in the merge statement, (where=pernum=1) gets one obs for each hh;
data desktop.households_&year;
  merge &microdata_file.(in=a where=(pernum=1)) County_income_limits_&year(in=b keep=statefip county L50_4 L80_4 ELI_4);
  by statefip county;
  if a;
  if L80_4 ne . then do;
    Below80AMI = hhincome < L80_4;  
    if ownershp = 1 then Affordable80AMI = (owncost*12) <= (L80_4*0.30);  
    else if ownershp = 2 then Affordable80AMI = (rentgrs*12) <= (L80_4*0.30);  
	else put "error: " ownershp=;
  end;
  if L50_4 ne . then do;
    Below50AMI = hhincome < L50_4;  
    if ownershp = 1 then Affordable50AMI = (owncost*12) <= (L50_4*0.30);  
    else if ownershp = 2 then Affordable50AMI = (rentgrs*12) <= (L50_4*0.30);  
	else put "error: " ownershp=;
  end;
  if ELI_4 ne . then do;
    Below30AMI = hhincome < ELI_4;  
    if ownershp = 1 then Affordable30AMI = (owncost*12) <= (ELI_4*0.30);  
    else if ownershp = 2 then Affordable30AMI = (rentgrs*12) <= (ELI_4*0.30);  
	else put "error: " ownershp=;
  end;
run;

*Need to account for vacant units as well.
*Merge on the 80% and 50% AMI income levels and determine which vacant units are affordable
 for a family of 4 at 80% and 50% of AMI (regardless of the actual unit size!!!).  If there is a non-zero
 value for gross rent, use that for the costs.  Otherwise, if there is a valid house value, use the housing
 cost that was calcualted in the "prepare_vacant" macro.;
data vacant;
  merge &vacant_file.(in=a) County_income_limits_&year(in=b keep=statefip county L50_4 L80_4 ELI_4);
  by statefip county;
  if a;
  if L80_4 ne . then do;
    if rentgrs>0 then Affordable80AMI = (rentgrs*12) <= (L80_4*0.30);  
    else if valueh ne 9999999 then Affordable80AMI = (total_monthly_cost*12) <= (L80_4*0.30);
  end;
  if L50_4 ne . then do;
    if rentgrs>0 then Affordable50AMI = (rentgrs*12) <= (L50_4*0.30);  
    else if valueh ne 9999999 then Affordable50AMI = (total_monthly_cost*12) <= (L50_4*0.30);
  end;
  if ELI_4 ne . then do;
    if rentgrs>0 then Affordable30AMI = (rentgrs*12) <= (ELI_4*0.30);  
    else if valueh ne 9999999 then Affordable30AMI = (total_monthly_cost*12) <= (ELI_4*0.30);
  end;
run;

*Summarize by county, combine households and vacant units, and compute metrics;
proc means data=desktop.Households_&year noprint; 
  output out=households_summed_&year(drop=_type_) sum=;
  by statefip county;
  var Below80AMI Affordable80AMI Below50AMI Affordable50AMI Below30AMI Affordable30AMI;
  weight hhwt;
run;
proc means data=vacant noprint; 
  output out=vacant_summed_&year(drop=_type_ _freq_) sum=Affordable80AMI_vacant Affordable50AMI_vacant Affordable30AMI_vacant;
  by statefip county;
  var  Affordable80AMI Affordable50AMI Affordable30AMI;
  weight hhwt;
run;
data &metrics_file.;
  merge vacant_summed_&year households_summed_&year ;
  by statefip county;
  if Affordable80AMI_vacant ne . and Affordable80AMI_vacant ne . and Affordable30AMI_vacant ne . then do;
   if Below80AMI ne . then share_affordable_80AMI = (Affordable80AMI+Affordable80AMI_vacant)/Below80AMI;
   if Below50AMI ne . then share_affordable_50AMI = (Affordable50AMI+Affordable50AMI_vacant)/Below50AMI;
   if Below30AMI ne . then share_affordable_30AMI = (Affordable30AMI+Affordable30AMI_vacant)/Below30AMI;
  end;
  else do;
   if Below80AMI ne . then share_affordable_80AMI = (Affordable80AMI)/Below80AMI;
   if Below50AMI ne . then share_affordable_50AMI = (Affordable50AMI)/Below50AMI;
   if Below30AMI ne . then share_affordable_30AMI = (Affordable30AMI)/Below30AMI;
  end;
run;
%mend compute_metrics_housing;

/* this is for 2021 */
%compute_metrics_housing(lib2021.microdata,lib2021.vacant,housing.metrics_housing_2021,year=2021);


proc means data=housing.metrics_housing_2021;
var share_affordable_80AMI share_affordable_50AMI share_affordable_30AMI;
title '2021';
run;

proc print data = housing.metrics_housing_2021;
 where share_affordable_80AMI = . or share_affordable_50AMI = . or share_affordable_30AMI = .;
run;
