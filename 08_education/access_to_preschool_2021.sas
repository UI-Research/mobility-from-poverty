/******************************

This program calculates the share of 3 and 4 year olds in pre school.

People in group quarters are inclucded.

Programmed by Kevin Werner

7/27/20

******************************/

/*
   NOTE: You need to edit the `libname` command to specify the path to the directory
   where the data file is located. For example: "C:\ipums_directory".
   Edit the `filename` command similarly to include the full path (the directory and the data file name).
*/

%let filepath = V:\Centers\Ibp\KWerner\Kevin\Mobility\gates-mobility-metrics\08_education\metrics_preschool_2021.csv;

/* 

Please download the file USA_00012.dat from Box, and unzip in the filename folder. 

*/

libname desktop "S:\KWerner\Metrics";
libname edu "V:\Centers\Ibp\KWerner\Kevin\Mobility\gates-mobility-metrics\08_education";

/************** create county indicator (copied from Paul) ****************/


%macro prepare_microdata(input_file,output_file);

*Map PUMAs to counties (this consolidates records for multi-PUMAs counties, and expands records for PUMAs that span counties);
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


%prepare_microdata(desktop.usa_00073, main);



/************** Start actual coding for the preschool metric ****************/



%macro compute_metrics_preschool(microdata_file,metrics_file);
proc sort data=&microdata_file.; by statefip county; run;

/* outputs a file with only children 3-4 (added 4/7/23: and those NOT in kindergarten */
proc means data=&microdata_file.(where=(age in (3,4) and gradeatt ne 2)) noprint; 
  output out=num_3_and_4(drop=_type_) sum=num_3_and_4;
  by statefip county;
  var perwt;
run;

/* outputs a file with only children 3-4 AND in pre school */
proc means data=&microdata_file.(where=(age in (3,4) and gradeatt=1)) noprint; 
  output out=num_in_preschool(drop=_type_ _freq_) sum=num_in_preschool;
  by statefip county;
  var perwt;
run;

/* combines the two files to get share in pre school */
data &metrics_file.;
  merge num_3_and_4(in=a) num_in_preschool(in=b);
  by statefip county;
  if not a or not b then put "error: missing a matching obs: " statefip= county= num_3_and_4= num_in_preschool=;
  else if num_3_and_4 <=0 then put "warning: no 3 or 4 yr-olds: " statefip= county= num_3_and_4= num_in_preschool=;
  else share_in_preschool = num_in_preschool/num_3_and_4;
run;
%mend compute_metrics_preschool;

%compute_metrics_preschool(main,metrics_preschool_v2);


/* create confidence interval and correctly format variables */

data data_missing_HI (keep = year county state share_in_preschool share_in_preschool_ub share_in_preschool_lb _FREQ_)  ;
 set metrics_preschool_v2;
 year = 2021;
 not_in_pre = 1 - share_in_preschool;
 interval = 1.96*sqrt((not_in_pre*share_in_preschool)/_FREQ_);
 share_in_preschool_ub = share_in_preschool + interval;
 share_in_preschool_lb = share_in_preschool - interval;

 if share_in_preschool_ub > 1 then share_in_preschool_ub = 1;
 if share_in_preschool_lb < 0 then share_in_preschool_lb = 0;

 new_county = put(county,z3.); 
 state = put(statefip,z2.);
 drop county statefip;
 rename new_county = county;
run;

/* add missing HI county so that there is observation for every county */

data edu.metrics_preschool_2021;
 set data_missing_HI end=eof;
 output;
 if eof then do;
  year = 2021;
  state = "15";
  county = "005";
  share_in_preschool = "";
  share_in_preschool_ub = "";
  share_in_preschool_lb = "";
  output;
 end;
run;


/* sort final data set and order variables*/

PROC FORMAT ;
PICTURE Num    .="NA"
				OTHER = "9.99999";
			 run;

data edu.metrics_preschool_2021;
 retain year state county share_in_preschool share_in_preschool_ub share_in_preschool_lb;
 set edu.metrics_preschool_2021;
 format share_in_preschool share_in_preschool_ub share_in_preschool_lb num.; 
run;

proc sort data=edu.metrics_preschool_2021; by year state county; run;



/* export as csv */

proc export data = edu.metrics_preschool_2021
  outfile = "&filepath"
  replace;
run;

proc freq data = main;
 where statefip = 1 and county = 1 and age in (3,4);
 table gradeatt;
run;
