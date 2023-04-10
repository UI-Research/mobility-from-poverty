/*
This program computers the percentage of full time workers
that are in poverty in Ramsey, MN using the 2018 5-year ACS.

Kevin Werner

10/19/21
*/

libname desktop "C:\Users\kwerner\Desktop\Metrics";

options fmtsearch=(lib2018);


 Proc format;
  Value subgroup_f ( default = 30)
 4 = "White, Non-Hispanic"
 1 = "Black, Non-Hispanic"
 3 = "Other Races and Ethnicities"
 2 = "Hispanic"
;

run;


*create dataset with just Ramsey;

data ramsey_mn_1;
 set lib2018.microdata_5_year;
 where statefip = 27 and county = 123;
 if age < 18 then child = 1;
  else child = 0;
run;

*get number of children for poverty thresholds. NOTE: did not end up needing this variable;
proc sort data=ramsey_mn_1; by sample serial famunit; run;
data number_children (keep = sample serial famunit num_kids);
 set ramsey_mn_1;
 by sample serial famunit;
 retain num_kids;
 if first.famunit then do;
  num_kids = 0;
 end;
 num_kids + child;
 if last.famunit then output;
run;
data ramsey_mn_2;
 merge ramsey_mn_1 number_children ;
 by sample serial famunit;
 if famsize = num_kids then num_kids = famsize - 1; /* for pov thresholds units cannot have only children */
run;

*import poverty guidelines 
(from https://aspe.hhs.gov/topics/poverty-economic-mobility/poverty-guidelines/prior-hhs-poverty-guidelines-federal-register-references);
proc import datafile="V:\Centers\Ibp\KWerner\Kevin\Mobility\Paul\pov_guidelines.csv" out=pov_guidelines (keep = multyear famsize guideline)
  dbms=csv replace;
  getnames=yes;
  guessingrows=100;
  datarow=2;
run;

proc sort data=pov_guidelines; by multyear famsize; run;
proc sort data=ramsey_mn_2; by multyear famsize; run;

*merge poverty guidelines and create other needed variables;
data ramsey_mn_3;
 merge ramsey_mn_2 pov_guidelines;
 by multyear famsize;
 if sample = . then delete;
 *create individual guideline to go on everyone's record;
 if multyear = 2018 then indv_guideline = 12140;
 else if multyear = 2017 then indv_guideline = 12060;
 else if multyear = 2016 then indv_guideline = 11880;
 else if multyear = 2015 then indv_guideline = 11770;
 else if multyear = 2014 then indv_guideline = 11670;

 if UHRSWORK >= 30 and WKSWORK2 >= 3 then full_time = 1;
  else full_time = 0;

 if age >= 18 and age < 65 then adult = 1;
  else adult = 0;

 *tabulating poverty;
 if FTOTINC < guideline then fam_poor = 1;
  else fam_poor = 0;
 if INCTOT < indv_guideline then indv_poor = 1;
  else indv_poor = 0;

run;



********create output dataset by PUMA and for county overall;
*total FT workers;
proc sort data=ramsey_mn_3; by statefip county; run;
proc means data=ramsey_mn_3 (where = (full_time = 1 and adult = 1)) noprint ; 
  output out=ramsey_ft (drop=_type_) sum=total_ft;
  by statefip county ;
  var perwt;
  class PUMA;
run;
*total FT and fam poor;
proc means data=ramsey_mn_3 (where = (full_time = 1 and fam_poor = 1 and adult = 1)) noprint ; 
  output out=ramsey_ft_fam_poor (drop=_type_ _FREQ_) sum=total_ft_fam_poor;
  by statefip county ;
  var perwt;
  class PUMA;
run;
/*total FT and indv poor;
proc means data=ramsey_mn_3 (where = (full_time = 1 and indv_poor = 1 and adult = 1)) noprint ; 
  output out=ramsey_ft_indv_poor (drop=_type_ _FREQ_) sum=total_ft_indv_poor;
  by statefip county ;
  var perwt;
  class PUMA;
run;
*/
*create final dataset by PUMA through merge;
data ramsey_PUMA;
 merge ramsey_ft ramsey_ft_fam_poor /*ramsey_ft_indv_poor*/;
 by statefip county PUMA;
 pct_ft_fam_poor = total_ft_fam_poor/total_ft;
 *pct_ft_indv_poor = total_ft_indv_poor/total_ft;
 rename _FREQ_ = unwt_ft_adults; 
run;
*export as csv;
proc export data = ramsey_PUMA
  outfile = "V:\Centers\Ibp\KWerner\Kevin\Mobility\gates-mobility-metrics\09_employment\ramsey_puma.csv"
  replace;
run;


********create output dataset by race;
*total FT workers;
proc means data=ramsey_mn_3 (where = (full_time = 1 and adult = 1)) noprint ; 
  output out=ramsey_ft2 (drop=_type_) sum=total_ft;
  by statefip county ;
  var perwt;
  class subgroup /preloadfmt ;
  format subgroup subgroup_f.; 
run;
*total FT and fam poor;
proc means data=ramsey_mn_3 (where = (full_time = 1 and fam_poor = 1 and adult = 1)) noprint ; 
  output out=ramsey_ft_fam_poor2 (drop=_type_ _FREQ_) sum=total_ft_fam_poor;
  by statefip county ;
  var perwt;
  class subgroup /preloadfmt ;
  format subgroup subgroup_f.; 
run;
/*total FT and indv poor;
proc means data=ramsey_mn_3 (where = (full_time = 1 and indv_poor = 1 and adult = 1)) noprint ; 
  output out=ramsey_ft_indv_poor2 (drop=_type_ _FREQ_) sum=total_ft_indv_poor;
  by statefip county ;
  var perwt;
  class subgroup /preloadfmt ;
  format subgroup subgroup_f.; 
run;
*/
*create final dataset by race through merge;
data ramsey_race;
 merge ramsey_ft2 ramsey_ft_fam_poor2 /*ramsey_ft_indv_poor2*/;
 by statefip county subgroup;
 pct_ft_fam_poor = total_ft_fam_poor/total_ft;
 *pct_ft_indv_poor = total_ft_indv_poor/total_ft;
 rename _FREQ_ = unwt_ft_adults; 
run;
*export as csv;
proc export data = ramsey_race
  outfile = "V:\Centers\Ibp\KWerner\Kevin\Mobility\gates-mobility-metrics\09_employment\ramsey_race.csv"
  replace;
run;

