*=================================================================;
*Compute county-level college-readiness metrics;
*=================================================================;
libname edu "V:\Centers\Ibp\KWerner\Kevin\Mobility\gates-mobility-metrics\08_education";

%macro compute_metrics_college(microdata_file,metrics_file);
proc means data=&microdata_file.(where=(age in (19,20))) noprint; 
  output out=num_19_and_20(drop=_type_) sum=num_19_and_20;
  by statefip county;
  var perwt;
run;
proc means data=&microdata_file.(where=(age in (19,20) and 62<=educd<=116)) noprint; 
  output out=num_with_HS_degree(drop=_type_ _freq_) sum=num_with_HS_degree;
  by statefip county;
  var perwt;
run;
data &metrics_file.;
  merge num_19_and_20(in=a) num_with_HS_degree(in=b);
  by statefip county;
  if not a or not b then put "error: missing a matching obs: " statefip= county= num_19_and_20= num_with_HS_degree=;
  else if num_19_and_20 <=0 then put "warning: no 19 or 20 yr-olds: " statefip= county= num_19_and_20= num_with_HS_degree=;
  else share_with_HSdegree = num_with_HS_degree/num_19_and_20;
run;
%mend compute_metrics_college;

%compute_metrics_college(lib2018.microdata,edu.metrics_college);
proc means data=edu.metrics_college;
run;
