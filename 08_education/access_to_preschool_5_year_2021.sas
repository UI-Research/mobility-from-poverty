/******************************

This program calculates the share of 3 and 4 year olds in pre school for the subgroupd file using the 2021 5 year ACS.

Note that this uses a SEPERATE raw file than the rest of the ACS metrics
because people in group quarters are included.

Programmed by Kevin Werner

3/14/23

******************************/

/*
   NOTE: You need to edit the `libname` command to specify the path to the directory
   where the data file is located. For example: "C:\ipums_directory".
   Edit the `filename` command similarly to include the full path (the directory and the data file name).
*/



/* 

Please download the file USA_00071.dat from Box, and unzip in the filename folder. 

*/

libname desktop "S:\KWerner\Metrics";
libname edu "V:\Centers\Ibp\KWerner\Kevin\Mobility\gates-mobility-metrics\08_education";


/************** create county indicator (copied from earlier code) ****************/



%macro prepare_microdata(input_file,output_file);

*Map PUMAs to counties (this expands records for PUMAs that span counties);
proc sql; 
 create table add_county as 
 select  
    a.* 
   ,b.county as county 
   ,b.afact as afact1  
   ,b.afact2 as afact2
 from &input_file. a  
 left join edu.puma_to_county b 
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
data &output_file.;
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


%prepare_microdata(desktop.usa_00071, main);



/************** Start actual coding for the preschool metric ****************/

data main; 
 set main;
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
 . = "All"
;

run;

%let suppress = 30;

%let preschool_filepath = V:\Centers\Ibp\KWerner\Kevin\Mobility\gates-mobility-metrics\08_education\metrics_pre_subgroup_2021.csv;

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

/* combines the two files to get share in pre school */
data &metrics_file.;
  merge num_3_and_4(in=a) num_in_preschool(in=b);
  by statefip county subgroup;
  if not a or not b then put "error: missing a matching obs: " statefip= county= num_3_and_4= num_in_preschool=;
  else if num_3_and_4 <=0 then put "warning: no 3 or 4 yr-olds: " statefip= county= num_3_and_4= num_in_preschool=;
  else share_in_preschool = num_in_preschool/num_3_and_4;
run;
%mend compute_metrics_preschool;

%compute_metrics_preschool(main,metrics_preschool_v2);


/* create confidence interval and correctly format variables */

data data_missing_HI (keep = year county state share_in_preschool share_in_preschool_ub share_in_preschool_lb _FREQ_ subgroup subgroup_type)  ;
 set metrics_preschool_v2;
 year = 2021;

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
 if subgroup in (1,2,3,4) then subgroup_type = "race-ethnicity";
 else subgroup_type = "all";
run;

/* add missing HI county so that there is observation for every county */

data edu.metrics_preschool_subgroup_2021;
 set data_missing_HI end=eof;
 output;
 if eof then do;
  year = 2021;
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
data edu.metrics_preschool_subgroup_2021;
 set edu.metrics_preschool_subgroup_2021 end=eof;
 output;
 if eof then do;
  year = 2021;
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
data edu.metrics_preschool_subgroup_2021;
 set edu.metrics_preschool_subgroup_2021 end=eof;
 output;
 if eof then do;
  year = 2021;
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
data edu.metrics_preschool_subgroup_2021;
 set edu.metrics_preschool_subgroup_2021 end=eof;
 output;
 if eof then do;
  year = 2021;
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
data edu.metrics_preschool_subgroup_2021;
 set edu.metrics_preschool_subgroup_2021 end=eof;
 output;
 if eof then do;
  year = 2021;
  state = "15";
  county = "005";
  subgroup_type = "rall";
  subgroup = .;
  share_in_preschool = "";
  share_in_preschool_ub = "";
  share_in_preschool_lb = "";
  _FREQ_ = .;
  output;
 end;
run;


/* sort final data set and order variables and create format*/

PROC FORMAT ;
PICTURE Num    .="NA"
				OTHER = "9.99999";
			 run;

data edu.metrics_pre_subgroup_2021;
 retain year state county subgroup_type subgroup share_in_preschool share_in_preschool_ub share_in_preschool_lb;
 set edu.metrics_preschool_subgroup_2021;
 if share_in_preschool = . and _FREQ_ >= &suppress then share_in_preschool = 0;
 if share_in_preschool_ub = . and _FREQ_ >= &suppress then share_in_preschool_ub = 0;
 if share_in_preschool_lb = . and _FREQ_ >= &suppress then share_in_preschool_lb = 0;
 format share_in_preschool num. share_in_preschool_ub num. share_in_preschool_lb num.;

run;

proc sort data=edu.metrics_pre_subgroup_2021; by year state county subgroup; run;



/* export as csv */

proc export data = edu.metrics_pre_subgroup_2021
  outfile = "&preschool_filepath"
  replace;
run;


