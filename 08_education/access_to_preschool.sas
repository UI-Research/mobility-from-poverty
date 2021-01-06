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

%let filepath = V:\Centers\Ibp\KWerner\Kevin\Mobility\gates-mobility-metrics\08_education\metrics_preschool.csv;

/* 

Please download the file USA_00012.dat from Box, and unzip in the filename folder. 

*/

filename ASCIIDAT "C:\Users\kwerner\Desktop\Metrics\usa_00012.dat";
libname desktop "C:\Users\kwerner\Desktop\Metrics";
libname edu "V:\Centers\Ibp\KWerner\Kevin\Mobility\gates-mobility-metrics\08_education";


proc format cntlout = desktop.usa_00012_f;

value YEAR_f
  1850 = "1850"
  1860 = "1860"
  1870 = "1870"
  1880 = "1880"
  1900 = "1900"
  1910 = "1910"
  1920 = "1920"
  1930 = "1930"
  1940 = "1940"
  1950 = "1950"
  1960 = "1960"
  1970 = "1970"
  1980 = "1980"
  1990 = "1990"
  2000 = "2000"
  2001 = "2001"
  2002 = "2002"
  2003 = "2003"
  2004 = "2004"
  2005 = "2005"
  2006 = "2006"
  2007 = "2007"
  2008 = "2008"
  2009 = "2009"
  2010 = "2010"
  2011 = "2011"
  2012 = "2012"
  2013 = "2013"
  2014 = "2014"
  2015 = "2015"
  2016 = "2016"
  2017 = "2017"
  2018 = "2018"
;

value SAMPLE_f
  201804 = "2014-2018, PRCS 5-year"
  201803 = "2014-2018, ACS 5-year"
  201802 = "2018 PRCS"
  201801 = "2018 ACS"
  201704 = "2013-2017, PRCS 5-year"
  201703 = "2013-2017, ACS 5-year"
  201702 = "2017 PRCS"
  201701 = "2017 ACS"
  201604 = "2012-2016, PRCS 5-year"
  201603 = "2012-2016, ACS 5-year"
  201602 = "2016 PRCS"
  201601 = "2016 ACS"
  201504 = "2011-2015, PRCS 5-year"
  201503 = "2011-2015, ACS 5-year"
  201502 = "2015 PRCS"
  201501 = "2015 ACS"
  201404 = "2010-2014, PRCS 5-year"
  201403 = "2010-2014, ACS 5-year"
  201402 = "2014 PRCS"
  201401 = "2014 ACS"
  201306 = "2009-2013, PRCS 5-year"
  201305 = "2009-2013, ACS 5-year"
  201304 = "2011-2013, PRCS 3-year"
  201303 = "2011-2013, ACS 3-year"
  201302 = "2013 PRCS"
  201301 = "2013 ACS"
  201206 = "2008-2012, PRCS 5-year"
  201205 = "2008-2012, ACS 5-year"
  201204 = "2010-2012, PRCS 3-year"
  201203 = "2010-2012, ACS 3-year"
  201202 = "2012 PRCS"
  201201 = "2012 ACS"
  201106 = "2007-2011, PRCS 5-year"
  201105 = "2007-2011, ACS 5-year"
  201104 = "2009-2011, PRCS 3-year"
  201103 = "2009-2011, ACS 3-year"
  201102 = "2011 PRCS"
  201101 = "2011 ACS"
  201008 = "2010 Puerto Rico 10%"
  201007 = "2010 10%"
  201006 = "2006-2010, PRCS 5-year"
  201005 = "2006-2010, ACS 5-year"
  201004 = "2008-2010, PRCS 3-year"
  201003 = "2008-2010, ACS 3-year"
  201002 = "2010 PRCS"
  201001 = "2010 ACS"
  200906 = "2005-2009, PRCS 5-year"
  200905 = "2005-2009, ACS 5-year"
  200904 = "2007-2009, PRCS 3-year"
  200903 = "2007-2009, ACS 3-year"
  200902 = "2009 PRCS"
  200901 = "2009 ACS"
  200804 = "2006-2008, PRCS 3-year"
  200803 = "2006-2008, ACS 3-year"
  200802 = "2008 PRCS"
  200801 = "2008 ACS"
  200704 = "2005-2007, PRCS 3-year"
  200703 = "2005-2007, ACS 3-year"
  200702 = "2007 PRCS"
  200701 = "2007 ACS"
  200602 = "2006 PRCS"
  200601 = "2006 ACS"
  200502 = "2005 PRCS"
  200501 = "2005 ACS"
  200401 = "2004 ACS"
  200301 = "2003 ACS"
  200201 = "2002 ACS"
  200101 = "2001 ACS"
  200008 = "2000 Puerto Rico 1%"
  200007 = "2000 1%"
  200006 = "2000 Puerto Rico 1% sample (old version)"
  200005 = "2000 Puerto Rico 5%"
  200004 = "2000 ACS"
  200003 = "2000 Unweighted 1%"
  200002 = "2000 1% sample (old version)"
  200001 = "2000 5%"
  199007 = "1990 Puerto Rico 1%"
  199006 = "1990 Puerto Rico 5%"
  199005 = "1990 Labor Market Area"
  199004 = "1990 Elderly"
  199003 = "1990 Unweighted 1%"
  199002 = "1990 1%"
  199001 = "1990 5%"
  198007 = "1980 Puerto Rico 1%"
  198006 = "1980 Puerto Rico 5%"
  198005 = "1980 Detailed metro/non-metro"
  198004 = "1980 Labor Market Area"
  198003 = "1980 Urban/Rural"
  198002 = "1980 1%"
  198001 = "1980 5%"
  197009 = "1970 Puerto Rico Neighborhood"
  197008 = "1970 Puerto Rico Municipio"
  197007 = "1970 Puerto Rico State"
  197006 = "1970 Form 2 Neighborhood"
  197005 = "1970 Form 1 Neighborhood"
  197004 = "1970 Form 2 Metro"
  197003 = "1970 Form 1 Metro"
  197002 = "1970 Form 2 State"
  197001 = "1970 Form 1 State"
  196002 = "1960 5%"
  196001 = "1960 1%"
  195001 = "1950 1%"
  194002 = "1940 100% database"
  194001 = "1940 1%"
  193004 = "1930 100% database"
  193003 = "1930 Puerto Rico"
  193002 = "1930 5%"
  193001 = "1930 1%"
  192003 = "1920 100% database"
  192002 = "1920 Puerto Rico sample"
  192001 = "1920 1%"
  191004 = "1910 100% database"
  191003 = "1910 1.4% sample with oversamples"
  191002 = "1910 1%"
  191001 = "1910 Puerto Rico"
  190004 = "1900 100% database"
  190003 = "1900 1% sample with oversamples"
  190002 = "1900 1%"
  190001 = "1900 5%"
  188003 = "1880 100% database"
  188002 = "1880 10%"
  188001 = "1880 1%"
  187003 = "1870 100% database"
  187002 = "1870 1% sample with black oversample"
  187001 = "1870 1%"
  186003 = "1860 100% database"
  186002 = "1860 1% sample with black oversample"
  186001 = "1860 1%"
  185002 = "1850 100% database"
  185001 = "1850 1%"
;

value STATEFIP_f
  01 = "Alabama"
  02 = "Alaska"
  04 = "Arizona"
  05 = "Arkansas"
  06 = "California"
  08 = "Colorado"
  09 = "Connecticut"
  10 = "Delaware"
  11 = "District of Columbia"
  12 = "Florida"
  13 = "Georgia"
  15 = "Hawaii"
  16 = "Idaho"
  17 = "Illinois"
  18 = "Indiana"
  19 = "Iowa"
  20 = "Kansas"
  21 = "Kentucky"
  22 = "Louisiana"
  23 = "Maine"
  24 = "Maryland"
  25 = "Massachusetts"
  26 = "Michigan"
  27 = "Minnesota"
  28 = "Mississippi"
  29 = "Missouri"
  30 = "Montana"
  31 = "Nebraska"
  32 = "Nevada"
  33 = "New Hampshire"
  34 = "New Jersey"
  35 = "New Mexico"
  36 = "New York"
  37 = "North Carolina"
  38 = "North Dakota"
  39 = "Ohio"
  40 = "Oklahoma"
  41 = "Oregon"
  42 = "Pennsylvania"
  44 = "Rhode Island"
  45 = "South Carolina"
  46 = "South Dakota"
  47 = "Tennessee"
  48 = "Texas"
  49 = "Utah"
  50 = "Vermont"
  51 = "Virginia"
  53 = "Washington"
  54 = "West Virginia"
  55 = "Wisconsin"
  56 = "Wyoming"
  61 = "Maine-New Hampshire-Vermont"
  62 = "Massachusetts-Rhode Island"
  63 = "Minnesota-Iowa-Missouri-Kansas-Nebraska-S.Dakota-N.Dakota"
  64 = "Maryland-Delaware"
  65 = "Montana-Idaho-Wyoming"
  66 = "Utah-Nevada"
  67 = "Arizona-New Mexico"
  68 = "Alaska-Hawaii"
  72 = "Puerto Rico"
  97 = "Military/Mil. Reservation"
  99 = "State not identified"
;

value GQ_f
  0 = "Vacant unit"
  1 = "Households under 1970 definition"
  2 = "Additional households under 1990 definition"
  3 = "Group quarters--Institutions"
  4 = "Other group quarters"
  5 = "Additional households under 2000 definition"
  6 = "Fragment"
;

value AGE_f
  000 = "Less than 1 year old"
  001 = "1"
  002 = "2"
  003 = "3"
  004 = "4"
  005 = "5"
  006 = "6"
  007 = "7"
  008 = "8"
  009 = "9"
  010 = "10"
  011 = "11"
  012 = "12"
  013 = "13"
  014 = "14"
  015 = "15"
  016 = "16"
  017 = "17"
  018 = "18"
  019 = "19"
  020 = "20"
  021 = "21"
  022 = "22"
  023 = "23"
  024 = "24"
  025 = "25"
  026 = "26"
  027 = "27"
  028 = "28"
  029 = "29"
  030 = "30"
  031 = "31"
  032 = "32"
  033 = "33"
  034 = "34"
  035 = "35"
  036 = "36"
  037 = "37"
  038 = "38"
  039 = "39"
  040 = "40"
  041 = "41"
  042 = "42"
  043 = "43"
  044 = "44"
  045 = "45"
  046 = "46"
  047 = "47"
  048 = "48"
  049 = "49"
  050 = "50"
  051 = "51"
  052 = "52"
  053 = "53"
  054 = "54"
  055 = "55"
  056 = "56"
  057 = "57"
  058 = "58"
  059 = "59"
  060 = "60"
  061 = "61"
  062 = "62"
  063 = "63"
  064 = "64"
  065 = "65"
  066 = "66"
  067 = "67"
  068 = "68"
  069 = "69"
  070 = "70"
  071 = "71"
  072 = "72"
  073 = "73"
  074 = "74"
  075 = "75"
  076 = "76"
  077 = "77"
  078 = "78"
  079 = "79"
  080 = "80"
  081 = "81"
  082 = "82"
  083 = "83"
  084 = "84"
  085 = "85"
  086 = "86"
  087 = "87"
  088 = "88"
  089 = "89"
  090 = "90 (90+ in 1980 and 1990)"
  091 = "91"
  092 = "92"
  093 = "93"
  094 = "94"
  095 = "95"
  096 = "96"
  097 = "97"
  098 = "98"
  099 = "99"
  100 = "100 (100+ in 1960-1970)"
  101 = "101"
  102 = "102"
  103 = "103"
  104 = "104"
  105 = "105"
  106 = "106"
  107 = "107"
  108 = "108"
  109 = "109"
  110 = "110"
  111 = "111"
  112 = "112 (112+ in the 1980 internal data)"
  113 = "113"
  114 = "114"
  115 = "115 (115+ in the 1990 internal data)"
  116 = "116"
  117 = "117"
  118 = "118"
  119 = "119"
  120 = "120"
  121 = "121"
  122 = "122"
  123 = "123"
  124 = "124"
  125 = "125"
  126 = "126"
  129 = "129"
  130 = "130"
  135 = "135"
;

value GRADEATT_f
  0 = "N/A"
  1 = "Nursery school/preschool"
  2 = "Kindergarten"
  3 = "Grade 1 to grade 4"
  4 = "Grade 5 to grade 8"
  5 = "Grade 9 to grade 12"
  6 = "College undergraduate"
  7 = "Graduate or professional school"
;

value GRADEATTD_f
  00 = "N/A"
  10 = "Nursery school/preschool"
  20 = "Kindergarten"
  30 = "Grade 1 to grade 4"
  31 = "Grade 1"
  32 = "Grade 2"
  33 = "Grade 3"
  34 = "Grade 4"
  40 = "Grade 5 to grade 8"
  41 = "Grade 5"
  42 = "Grade 6"
  43 = "Grade 7"
  44 = "Grade 8"
  50 = "Grade 9 to grade 12"
  51 = "Grade 9"
  52 = "Grade 10"
  53 = "Grade 11"
  54 = "Grade 12"
  60 = "College undergraduate"
  61 = "First year of college"
  62 = "Second year of college"
  63 = "Third year of college"
  64 = "Fourth year of college"
  70 = "Graduate or professional school"
  71 = "Fifth year of college"
  72 = "Sixth year of college"
  73 = "Seventh year of college"
  74 = "Eighth year of college"
;

run;


data raw_preschool;
infile ASCIIDAT pad missover lrecl=97;

input
  YEAR        1-4
  SAMPLE      5-10
  SERIAL      11-18
  CBSERIAL    19-31
  HHWT        32-41 .2
  CLUSTER     42-54
  STATEFIP    55-56
  COUNTYFIP   57-59
  PUMA        60-64
  STRATA      65-76
  GQ          77-77
  PERNUM      78-81
  PERWT       82-91 .2
  AGE         92-94
  GRADEATT    95-95
  GRADEATTD   96-97
;

label
  YEAR      = "Census year"
  SAMPLE    = "IPUMS sample identifier"
  SERIAL    = "Household serial number"
  CBSERIAL  = "Original Census Bureau household serial number"
  HHWT      = "Household weight"
  CLUSTER   = "Household cluster for variance estimation"
  STATEFIP  = "State (FIPS code)"
  COUNTYFIP = "County (FIPS code)"
  PUMA      = "Public Use Microdata Area"
  STRATA    = "Household strata for variance estimation"
  GQ        = "Group quarters status"
  PERNUM    = "Person number in sample unit"
  PERWT     = "Person weight"
  AGE       = "Age"
  GRADEATT  = "Grade level attending [general version]"
  GRADEATTD = "Grade level attending [detailed version]"
;

format
  YEAR       YEAR_f.
  SAMPLE     SAMPLE_f.
  STATEFIP   STATEFIP_f.
  GQ         GQ_f.
  AGE        AGE_f.
  GRADEATT   GRADEATT_f.
  GRADEATTD  GRADEATTD_f.
;

format
  CBSERIAL   13.
  HHWT       11.2
  CLUSTER    13.
  STRATA     12.
  PERWT      11.2
;

run;




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


%prepare_microdata(raw_preschool, main);



/************** Start actual coding for the preschool metric ****************/



%macro compute_metrics_preschool(microdata_file,metrics_file);
proc sort data=&microdata_file.; by statefip county; run;

/* outputs a file with only children 3-4 */
proc means data=&microdata_file.(where=(age in (3,4))) noprint; 
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
 year = 2018;
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

data edu.metrics_preschool;
 set data_missing_HI end=eof;
 output;
 if eof then do;
  year = 2018;
  state = "15";
  county = "005";
  share_in_preschool = "";
  share_in_preschool_ub = "";
  share_in_preschool_lb = "";
  output;
 end;
run;


/* sort final data set and order variables*/

data edu.metrics_preschool;
 retain year state county share_in_preschool share_in_preschool_ub share_in_preschool_lb;
 set edu.metrics_preschool;
run;

proc sort data=edu.metrics_preschool; by year state county; run;



/* export as csv */

proc export data = edu.metrics_preschool
  outfile = "&filepath"
  replace;
run;
