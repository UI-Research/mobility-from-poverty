*=================================================================;
*Compute county-level unemployment/joblessness metrics;
*=================================================================;

libname employ "V:\Centers\Ibp\KWerner\Kevin\Mobility\gates-mobility-metrics\09_employment";
%macro compute_metrics_unemployment(microdata_file,metrics_file);
/* creates dataset with number of 25-54 year olds by county */
proc means data=&microdata_file.(where=(25<=age<=54)) noprint; 
  output out=num_25_thru_54(drop=_type_) sum=num_25_thru_54;
  by statefip county;
  var perwt;
run;
/* creates dataset with number of employed 25-54 year olds by county */
proc means data=&microdata_file.(where=((25<=age<=54) and empstat=1)) noprint; 
  output out=num_employed(drop=_type_ _freq_) sum=num_employed;
  by statefip county;
  var perwt;
run;
/* merges the two datasets and computes the share employed */
data &metrics_file.;
  merge num_25_thru_54(in=a) num_employed(in=b);
  by statefip county;
  if not a or not b then put "error: missing a matching obs: " statefip= county= num_25_thru_54= num_employed=;
  else if num_25_thru_54 <=0 then put "warning: no 25-54 yr-olds: " statefip= county= num_25_thru_54= num_employed=;
  else share_employed = num_employed/num_25_thru_54;
run;
%mend compute_metrics_unemployment;

%compute_metrics_unemployment(lib2018.microdata,employ.metrics_unemployment);
proc means data=employ.metrics_unemployment;
run;
