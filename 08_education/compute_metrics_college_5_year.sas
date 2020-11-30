*=================================================================;
*Compute county-level college-readiness metrics;
*=================================================================;

options fmtsearch=(lib2018);
libname edu "V:\Centers\Ibp\KWerner\Kevin\Mobility\gates-mobility-metrics\08_education";

 Proc format;
  Value subgroup_f
 4 = "White, Non Hispanic"
 1 = "Black, Non Hispanic"
 3 = "Other Races and Ethnicities"
 2 = "Hispanic"
;

run;

%macro compute_metrics_college(microdata_file,metrics_file);
proc means data=&microdata_file.(where=(age in (19,20))) noprint completetypes; 
  output out=num_19_and_20(drop=_type_) sum=num_19_and_20;
  by statefip county;
  class subgroup /preloadfmt ;
  format subgroup subgroup_f.;
  var perwt;
run;
proc means data=&microdata_file.(where=(age in (19,20) and 62<=educd<=116)) noprint completetypes; 
  output out=num_with_HS_degree(drop=_type_ _freq_) sum=num_with_HS_degree;
  by statefip county;
  class subgroup  /preloadfmt ;
  format subgroup subgroup_f.;
  var perwt;
run;
proc sort data=num_19_and_20; by statefip county subgroup; run;
proc sort data=num_with_HS_degree; by statefip county subgroup; run;
data &metrics_file.;
  merge num_19_and_20(in=a) num_with_HS_degree(in=b);
  by statefip county subgroup;
  if not a or not b then put "error: missing a matching obs: " statefip= county= num_19_and_20= num_with_HS_degree=;
  else if num_19_and_20 <=0 then put "warning: no 19 or 20 yr-olds: " statefip= county= num_19_and_20= num_with_HS_degree=;
  else share_with_HSdegree = num_with_HS_degree/num_19_and_20;
  if subgroup = . then delete;
run;
%mend compute_metrics_college;

%compute_metrics_college(lib2018.microdata_5_year,edu.metrics_college_subgroup);
proc means data=edu.metrics_college_5_year;
run;
