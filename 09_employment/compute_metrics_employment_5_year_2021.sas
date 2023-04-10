*=================================================================;
*Compute county-level unemployment/joblessness metrics;
*=================================================================;

/* computes employment metric for subgroup file on 2021 5 year ACS

3/15/23
*/
options fmtsearch=(lib2018);

libname desktop "S:\KWerner\Metrics";
libname employ "V:\Centers\Ibp\KWerner\Kevin\Mobility\gates-mobility-metrics\09_employment";


 Proc format ;
  Value subgroup_f ( default = 30)
 4 = "White, Non-Hispanic"
 1 = "Black, Non-Hispanic"
 3 = "Other Races and Ethnicities"
 2 = "Hispanic"
 . = "All";
;

run;

%macro compute_metrics_unemployment(microdata_file,metrics_file);
/* creates dataset with number of 25-54 year olds by county */
proc means data=&microdata_file.(where=(25<=age<=54)) noprint completetypes; 
  output out=num_25_thru_54(drop=_type_) sum=num_25_thru_54;
  by statefip county;
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
  by statefip county;
  class subgroup / preloadfmt ;
  format subgroup subgroup_f.;
  var perwt;
run;
proc sort data=num_25_thru_54; by statefip county subgroup; run;
proc sort data=num_employed; by statefip county subgroup; run;
/* merges the two datasets and computes the share employed */
data &metrics_file.;
  merge num_25_thru_54(in=a) num_employed(in=b);
  by statefip county subgroup;
  if not a or not b then put "error: missing a matching obs: " statefip= county= num_25_thru_54= num_employed=;
  else if num_25_thru_54 <=0 then put "warning: no 25-54 yr-olds: " statefip= county= num_25_thru_54= num_employed=;
  else share_employed = num_employed/num_25_thru_54;
run;
%mend compute_metrics_unemployment;

%compute_metrics_unemployment(lib2021.microdata_5_year,employ.metrics_employ_subgroup_2021);
