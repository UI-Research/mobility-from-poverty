*=========================================================;
*Macro to prepare an IPUMS extract for metrics processing;
*=========================================================;

/*

The input files USA_00027 and puma_to_county are created by the preceeding SAS programs,
1_init.sas and 2_puma_to_county

USA_00027 is on Box in Metrics Database/ACS-based metrics/PUMS-based/data/2018.
It will need to be downloaded and unzipped. 

USA_00019 is on Box in Metrics Database/ACS-based metrics/PUMS-based/data/2018.
It will need to be downloaded and unzipped. 

*/

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
 left join libmain.puma_to_county b 
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
*Adjust dollar amounts to account for inflation;
*KW: Set people who live in county 515 in state 51 to live county 019 instead (Bedford city was absorbed into Bedford county);
*KW: change two more counties as well ;
data &output_file.;
  set add_num_of_counties;
  if (county = .) then put "error: no match: " serial= statefip= puma=;
  hhwt = hhwt*afact1;
  perwt = perwt*afact1;
  hhincome=hhincome*adjust;
  rentgrs=rentgrs*adjust;
  owncost=owncost*adjust;
  if statefip = 51 and county = 515 then county = 19;
  if statefip = 2 and county = 270 then county = 158;
  if statefip = 46 and county = 113 then county = 102;
run;

*Sort into order most useful for calculating metrics;
proc sort data=&output_file.;
  by statefip county;
run;
%mend prepare_microdata;

/* this is used for all of the one-year metrics besides preschool */
%prepare_microdata(lib2021.main_2021,lib2021.microdata);

/* this should be run to get the 2014 housing data 
%prepare_microdata(lib2014.usa_00024,lib2014.microdata);*/

