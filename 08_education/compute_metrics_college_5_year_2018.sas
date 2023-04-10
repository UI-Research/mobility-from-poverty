*=================================================================;
*Compute county-level college-readiness metrics;
*=================================================================;

options fmtsearch=(lib2018);

 Proc format;
  Value subgroup_f ( default = 30)
 4 = "White, Non-Hispanic"
 1 = "Black, Non-Hispanic"
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
/* educd values from IPUMS:
000		N/A or no schooling
001		N/A
002		No schooling completed
010		Nursery school to grade 4
011		Nursery school, preschool
012		Kindergarten
013		Grade 1, 2, 3, or 4
014		Grade 1
015		Grade 2
016		Grade 3
017		Grade 4
020		Grade 5, 6, 7, or 8
021		Grade 5 or 6
022		Grade 5
023		Grade 6
024		Grade 7 or 8
025		Grade 7
026		Grade 8
030		Grade 9
040		Grade 10
050		Grade 11
060		Grade 12
061		12th grade, no diploma
062		High school graduate or GED
063		Regular high school diploma
064		GED or alternative credential
065		Some college, but less than 1 year
070		1 year of college
071		1 or more years of college credit, no degree
080		2 years of college
081		Associate's degree, type not specified
082		Associate's degree, occupational program
083		Associate's degree, academic program
090		3 years of college
100		4 years of college
101		Bachelor's degree
110		5+ years of college
111		6 years of college (6+ in 1960-1970)
112		7 years of college
113		8+ years of college
114		Master's degree
115		Professional degree beyond a bachelor's degree
116		Doctoral degree
999		Missing
*/
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
proc means data=edu.metrics_college_subgroup;
run;
