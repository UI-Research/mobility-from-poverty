/******************************

This program calculates the share of 3 and 4 year olds in pre school.

It is a copy of "Access_to_preschool_5_year" but is written to run on multiple SAS datasets downloaded from
IPUMS, rather than one CSV downloaded from IPUMS. Downloading from IPUMS as a SAS dataset allows the user
to avoid having to do all of the infiling and formatting.

Programmed by Kevin Werner

1/11/22

******************************/

/*
   NOTE: You need to edit the `libname` command to specify the path to the directory
   where the data file is located. For example: "C:\ipums_directory".
   Edit the `filename` command similarly to include the full path (the directory and the data file name).
*/

/*%let filepath = V:\Centers\Ibp\KWerner\Kevin\Mobility\gates-mobility-metrics\08_education\metrics_preschool_subgroup.csv;*/

/* 

Please download the file USA_00017.dat from Box, and unzip in the filename folder. 

*/


/************** create county indicator (copied from Paul) ****************/

proc freq data = x.raw_5_2015__2011;
 table PUMA;
run;

libname x "V:\Centers\Ibp\KWerner\Kevin\Mobility\Paul\5_year";

data x.raw_5_2015_no_2011;
 set x.raw_5_2015;
 if MULTYEAR = 2011 then delete;
run;

data x.raw_5_2015__2011;
 set x.raw_5_2015;
 if MULTYEAR ne 2011 then delete;
run;

%macro prepare_microdata(input_file,output_file,puma_to_use);

*Map PUMAs to counties (this consolidates records for multi-PUMAs counties, and expands records for PUMAs that span counties);
proc sql; 
 create table add_county as 
 select  
    a.* 
   ,b.county as county 
   ,b.afact as afact1  
   ,b.afact2 as afact2
 from x.&input_file a  
 left join x.&puma_to_use b 
 on (a.statefip = b.statefip and a.puma = b.puma) 
;  
quit;

*Add an indicator of whether the puma-to-county match resulted in the creation of additional records (i.e. did
 the PUMA span counties?);
proc sort data=add_county;
  by serial pernum;
run;
proc means data=add_county noprint;
  by serial pernum;
  output out=num_of_counties_in_puma n=num_of_counties_in_puma;
run;
data add_num_of_counties;
  merge add_county num_of_counties_in_puma(keep=serial pernum num_of_counties_in_puma);
  by serial pernum;
  if first.pernum then puma_county_num=1;
  else puma_county_num+1;
run;

*Print error message for any record that did not have a match in the PUMA-to_county file;
*Adjust weight to acount for PUMA-to-county mapping (this only affects PUMAs that span county).;
*KW: Set people who live in county 515 in state 51 to live county 019 instead (Bedford city was absorbed into Bedford county);
data x.&output_file;
  set add_num_of_counties;
  if (county = .) then put "error: no match: " serial= statefip= puma=;
  hhwt = hhwt*afact1;
  perwt = perwt*afact1;
  if statefip = 51 and county = 515 then county = 19;
  if statefip = 2 and county = 270 then county = 158;
  if statefip = 46 and county = 113 then county = 102;
run;

*Sort into order most useful for calculating metrics;
proc sort data=&output_file.;
  by statefip county;
run;
%mend prepare_microdata;

%prepare_microdata(raw_5_2015__2011, main_2015__2011,puma_to_county_2000); /*2011 uses different PUMAs, 
	so the whole process has to be repeated with a different county to PUMA dataset */
%prepare_microdata(raw_5_2015_no_2011, main_2015_no_2011,puma_to_county);
%prepare_microdata(raw_5_2016, main_2016,puma_to_county);
%prepare_microdata(raw_5_2017, main_2017,puma_to_county);
%prepare_microdata(raw_5_2018, main_2018,puma_to_county);
%prepare_microdata(raw_5_2019, main_2019,puma_to_county);

*append the two 2015 datasets back together;
data main_2015_all;
 set main_2015__2011 main_2015_no_2011;
run;


/************** Start actual coding for the preschool metric ****************/
%macro race_code(dataset);

data x.&dataset; 
 set x.&dataset;
   /* create race categories */
   /* values for RACE:
	1	White	
	2	Black/African American/Negro	
	3	American Indian or Alaska Native
	4	Chinese
	5	Japanese	
	6	Other Asian or Pacific Islander
	7	Other race, nec	
	8	Two major races	
	9	Three or more major races	

  	values for HISPAN:
  	0	Not Hispanic
	1	Mexican
	2	Puerto Rican·
	3	Cuban
	4	Other
	9	Not Reported
  */

  if hispan = 0 then do;
   if race = 1 then subgroup = 4 /* white */;
   else if race = 2 then subgroup = 1 /* black */;
   else if race in (3,4,5,6,7,8,9) then subgroup = 3 /* other */;
   else subgroup = .;
  end;
  else if hispan in (1,2,3,4) then subgroup = 2 /* hispanic */;
  else subgroup = .;

  
 run;

 Proc format;
  Value subgroup_f
 4 = "White, Non Hispanic"
 1 = "Black, Non Hispanic"
 3 = "Other Races and Ethnicities"
 2 = "Hispanic"
;

run;
%mend race_code;
%race_code(main_2015_all);
%race_code(main_2016);
%race_code(main_2017);
%race_code(main_2018);
%race_code(main_2019);


%macro compute_metrics_preschool(microdata_file,metrics_file);
proc sort data=&microdata_file.; by statefip county subgroup; run;

/* outputs a file with only children 3-4 */
proc means data=&microdata_file.(where=(age in (3,4))) noprint completetypes; 
  output out=num_3_and_4(drop=_type_) sum=num_3_and_4;
  by statefip county ;
  class subgroup /preloadfmt ;
  var perwt;
  format subgroup subgroup_f.; 
run;

data num_3_and_4;
 set num_3_and_4;
 if subgroup = . then delete;
run;

/* outputs a file with only children 3-4 AND in pre school */
/* gradeatt values from IPUMS:
0		N/A
1		Nursery school/preschool
2		Kindergarten
3		Grade 1 to grade 4
4		Grade 5 to grade 8
5		Grade 9 to grade 12
6		College undergraduate
7		Graduate or professional school
*/
proc means data=&microdata_file.(where=(age in (3,4) and gradeatt=1)) noprint completetypes; 
  output out=num_in_preschool(drop=_type_ _freq_) sum=num_in_preschool;
  by statefip county ;
  class subgroup /preloadfmt ;
  var perwt;
  format subgroup subgroup_f.;
run;

data num_in_preschool;
 set num_in_preschool;
 if subgroup = . then delete;
run;

/* combines the two files to get share in pre school */
data &metrics_file.;
  merge num_3_and_4(in=a) num_in_preschool(in=b);
  by statefip county subgroup;
  if not a or not b then put "error: missing a matching obs: " statefip= county= num_3_and_4= num_in_preschool=;
  else if num_3_and_4 <=0 then put "warning: no 3 or 4 yr-olds: " statefip= county= num_3_and_4= num_in_preschool=;
  else share_in_preschool = num_in_preschool/num_3_and_4;
run;
%mend compute_metrics_preschool;

%compute_metrics_preschool(main_2019,preschool_2019);
%compute_metrics_preschool(main_2018,preschool_2018);
%compute_metrics_preschool(main_2017,preschool_2017);
%compute_metrics_preschool(main_2016,preschool_2016);
%compute_metrics_preschool(main_2015_all,preschool_2015);


/* create confidence interval and correctly format variables */
%let suppress = 30;
%macro final_processing(input,missing_HI_data,output,year);
data &missing_HI_data. (keep = year county state share_in_preschool share_in_preschool_ub share_in_preschool_lb _FREQ_ subgroup subgroup_type)  ;
 set &input.;
 year = &year;

  /* suppress values less than 30 */
 if _FREQ_ >= 0 and _FREQ_ < &suppress then share_in_preschool = .;

 not_in_pre = 1 - share_in_preschool;
 interval = 1.96*sqrt((not_in_pre*share_in_preschool)/_FREQ_);
 share_in_preschool_ub = share_in_preschool + interval;
 share_in_preschool_lb = share_in_preschool - interval;
 if share_in_preschool_ub > 1 then share_in_preschool_ub = 1;
 if share_in_preschool_lb ne . and share_in_preschool_lb < 0 then share_in_preschool_lb = 0;

 new_county = put(county,z3.); 
 state = put(statefip,z2.);
 drop county statefip;
 rename new_county = county;
 subgroup_type = "race-ethnicity";
run;

/* add missing HI county so that there is observation for every county */

data &output;
 set &missing_HI_data end=eof;
 output;
 if eof then do;
  year = &year;
  state = "15";
  county = "005";
  subgroup_type = "race-ethnicity";
  subgroup = 1;
  share_in_preschool = "";
  share_in_preschool_ub = "";
  share_in_preschool_lb = "";
  _FREQ_ = .;
  output;
 end;
run;
data &output;
 set &output end=eof;
 output;
 if eof then do;
  year =  &year;
  state = "15";
  county = "005";
  subgroup_type = "race-ethnicity";
  subgroup = 2;
  share_in_preschool = "";
  share_in_preschool_ub = "";
  share_in_preschool_lb = "";
  _FREQ_ = .;
  output;
 end;
run;
data &output;
 set &output end=eof;
 output;
 if eof then do;
  year =  &year;
  state = "15";
  county = "005";
  subgroup_type = "race-ethnicity";
  subgroup = 3;
  share_in_preschool = "";
  share_in_preschool_ub = "";
  share_in_preschool_lb = "";
  _FREQ_ = .;
  output;
 end;
run;
data &output;
 set &output end=eof;
 output;
 if eof then do;
  year =  &year;
  state = "15";
  county = "005";
  subgroup_type = "race-ethnicity";
  subgroup = 4;
  share_in_preschool = "";
  share_in_preschool_ub = "";
  share_in_preschool_lb = "";
  _FREQ_ = .;
  output;
 end;
run;


/* sort final data set and order variables*/

data &output;
 retain year state county subgroup_type subgroup share_in_preschool share_in_preschool_ub share_in_preschool_lb;
 set &output;
 if share_in_preschool = . and _FREQ_ >= &suppress then share_in_preschool = 0;
 if share_in_preschool_ub = . and _FREQ_ >= &suppress then share_in_preschool_ub = 0;
 if share_in_preschool_lb = . and _FREQ_ >= &suppress then share_in_preschool_lb = 0;


run;

proc sort data=&output; by year state county subgroup; run;

%mend final_processing;
%final_processing(preschool_2019,missing_HI_2019,output_2019,2019);
%final_processing(preschool_2018,missing_HI_2018,output_2018,2018);
%final_processing(preschool_2017,missing_HI_2017,output_2017,2017);
%final_processing(preschool_2016,missing_HI_2016,output_2016,2016);
%final_processing(preschool_2015,missing_HI_2015,output_2015,2015);


/* export as csv */

%macro export(metric,year);

proc export data = &metric.
  outfile = "V:\Centers\Ibp\KWerner\Kevin\Mobility\gates-mobility-metrics\08_education\preschool_5_year&year..csv"
  replace;
run;

%mend export;
%export(output_2019,_2019);
%export(output_2018,_2018);
%export(output_2017,_2017);
%export(output_2016,_2016);
%export(output_2015,_2015);
