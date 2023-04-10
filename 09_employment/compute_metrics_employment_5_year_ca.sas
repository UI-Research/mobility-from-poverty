*=================================================================;
*Compute county-level unemployment/joblessness metrics;

*Computes the industry X race employment tabs for selected CA counties

*To run this, you need to first run 1_initial.sas and also make sure that
*you have the output producted by 2_puma_to_county.sas

*The new input for this program is usa_00030.csv, which is saved a
*csv rather than a .dat to avoid having to format. You also need the
*main microdata_5_year SAS data set.
*=================================================================;
options fmtsearch=(lib2018);

libname CA_req "V:\Centers\Ibp\KWerner\Kevin\Mobility\gates-mobility-metrics\09_employment\CA request";


 Proc format ;
  Value subgroup_f ( default = 30)
 4 = "White, Non-Hispanic"
 1 = "Black, Non-Hispanic"
 3 = "Other Races and Ethnicities"
 2 = "Hispanic"
;

run;

/* import the new industry variable */
proc import datafile="V:\Centers\Ibp\KWerner\Kevin\Mobility\Paul\2018\usa_00030.csv" out=industry_raw dbms=csv replace;
  getnames=yes;
  guessingrows=1000;
  datarow=2;
run;

proc sort data = industry_raw; by multyear serial pernum; run;
proc sort data = lib2018.microdata_5_year; by multyear serial pernum; run;

/* create the broad industry variable 
   I used the broad industry categories in the IPUMS IND variable
   You can see those categories here: https://usa.ipums.org/usa/volii/ind2017.shtml*/
data industry; 
 set industry_raw;
 if GQ in (3,4,5) then delete; /*delete accidentally included group quarters*/
 if ind in (0170:0490) then broad_ind = "Agriculture, Forestry, Fishing, and Hunting, and Mining";
  else if ind in (0770) then broad_ind = "Construction";
  else if ind in (1070:3990) then broad_ind = "Manufacturing";
  else if ind in (4070:4590) then broad_ind = "Wholesale Trade";
  else if ind in (4670:5790) then broad_ind = "Retail Trade";
  else if ind in (6070:6390, 0570:0690) then broad_ind = "Transportation and Warehousing, and Utilities";
  else if ind in (6470:6780) then broad_ind = "Information";
  else if ind in (6870:7190) then broad_ind = "Finance and Insurance, and Real Estate, and Rental and Leasing";
  else if ind in (7270:7790) then broad_ind = "Professional, Scientific, and Management, and Administrative, and Waste Management Services";
  else if ind in (7860:8470) then broad_ind = "Educational Services, and Health Care and Social Assistance";
  else if ind in (8561:8690) then broad_ind = "Arts, Entertainment, and Recreation, and Accommodation and Food Services";
  else if ind in (8770:9290) then broad_ind = "Other Services, Except Public Administration";
  else if ind in (9370:9590) then broad_ind = "Public Administration";
  else if ind in (9670:9870) then broad_ind = "Military";
  else if ind in (9920) then broad_ind = "Unemployed, last worked 5 years ago or earlier or never worked";
  else broad_ind = "Not in universe";
run;
/*
proc freq data = industry;
 table ind*broad_ind / nocol norow nopercent;
run;
*/
data CA_employment;
 merge lib2018.microdata_5_year industry;
 by multyear serial pernum;
 if STATEFIP = 6 and county in (1, 13, 41, 55, 75, 81, 85, 95, 97); /* only keep CA counties that we are interested in */
run;

proc sort data = CA_employment; by statefip county broad_ind; run;

%macro compute_metrics_unemployment(microdata_file,metrics_file);
/* creates dataset with number of 25-54 year olds by county */
proc means data=&microdata_file.(where=(25<=age<=54)) noprint completetypes; 
  output out=num_25_thru_54(drop=_type_) sum=num_25_thru_54;
  by statefip county broad_ind;
  class subgroup / preloadfmt ;
  format subgroup subgroup_f.;
  var perwt;
run;
/* creates dataset with number of employed 25-54 year olds by county */
/* empstat values:
0		N/A
1		Employed
2		Unemployed
3		Not in labor force
*/
proc means data=&microdata_file.(where=((25<=age<=54) and empstat=1)) noprint completetypes; 
  output out=num_employed(drop=_type_ _freq_) sum=num_employed;
  by statefip county broad_ind;
  class subgroup / preloadfmt ;
  format subgroup subgroup_f.;
  var perwt;
run;
proc sort data=num_25_thru_54; by statefip county subgroup; run;
proc sort data=num_employed; by statefip county subgroup; run;
/* merges the two datasets and computes the share employed */
data &metrics_file.;
  merge num_25_thru_54(in=a) num_employed(in=b);
  by statefip county subgroup broad_ind;
  if not a or not b then put "error: missing a matching obs: " statefip= county= num_25_thru_54= num_employed=;
  else if num_25_thru_54 <=0 then put "warning: no 25-54 yr-olds: " statefip= county= num_25_thru_54= num_employed=;
  else share_employed = num_employed/num_25_thru_54;
  if subgroup = . then delete;
run;
%mend compute_metrics_unemployment;

%compute_metrics_unemployment(CA_employment,CA_req.metrics_employment_subgroup);

/* check to make sure numbers match the output */
proc freq data=CA_employment;
 where county = 1 and 25<=age<=54;
 table subgroup*broad_ind*empstat / nocol norow nopercent;
 weight perwt;
run;
