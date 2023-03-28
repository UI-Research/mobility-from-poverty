*=================================================================;
*Compute county-level digital access metric;
*=================================================================;

/* computes digital access metric for subgroup file on 2021 5 year ACS

3/15/23
*/

libname neighbor "V:\Centers\Ibp\KWerner\Kevin\Mobility\gates-mobility-metrics\06_neighborhoods";
%let filepath = V:\Centers\Ibp\KWerner\Kevin\Mobility\gates-mobility-metrics\06_neighborhoods\metrics_access_subgroup_2021.csv;

%let suppress = 30;

 Proc format ;
  Value subgroup_f ( default = 30)
 4 = "White, Non-Hispanic"
 1 = "Black, Non-Hispanic"
 3 = "Other Races and Ethnicities"
 2 = "Hispanic"
 . = "All";
;

/* create binary */
data access;
 	set lib2021.microdata_5_year;
	if CIHISPEED in (0,.) then digital_access = .; /* missing */
	 else if CIHISPEED = 10 then digital_access = 1; /* has high speed access */
	 else if CIHISPEED = 20 then digital_access = 0; /* does not have high speed access */
run;

/*
proc freq data=access;
where pernum =1;
table digital_access / missing nocol norow nopercent;
weight hhwt;
run;
*/


/* compute number of HHs with access */
proc means data=access  (where=(digital_access = 1 and pernum = 1)) noprint completetypes; 
  output out=number_hhs_access (drop=_type_ _FREQ_) sum=digital_access;
  by statefip county;
  var hhwt;
  class subgroup / preloadfmt ;
  format subgroup subgroup_f.;
run;

/*
proc means data=total_hhs sum;
 var _FREQ_;
run;
*/

/* compute total number of households */
proc means data=access  (where=( pernum = 1)) noprint completetypes; 
  output out=total_hhs (drop=_type_) sum=total_hhs;
  by statefip county;
  var hhwt;
  class subgroup / preloadfmt ;
  format subgroup subgroup_f.;
run;

/* merges the two datasets and computes the share with access */
data access_missing_HI_2021;
  merge number_hhs_access(in=a) total_hhs(in=b);
  by statefip county;
  share_access = digital_access/total_hhs;
  year = 2021;

  /* suppress values under 30 */
 if _FREQ_ >= 0 and _FREQ_ < &suppress then share_access = .;

  new_county = put(county,z3.); 
  state = put(statefip,z2.);
  drop county statefip;
  rename new_county = county;

  /* compute ub and lb */
  inverse_share = 1-share_access;
  interval_share = 1.96*sqrt((inverse_share*share_access)/_FREQ_);
  share_access_lb = share_access - interval_share;
  share_access_ub = share_access + interval_share;

 if share_access = . and _FREQ_ >= &suppress then share_access = 0;
 if share_access_ub = . and _FREQ_ >= &suppress then share_access_ub = 0;
 if share_access_lb = . and _FREQ_ >= &suppress then share_access_lb = 0;
 if subgroup in (1,2,3,4) then subgroup_type = "race-ethnicity";
 else subgroup_type = "all";
  
run;

/* add missing HI county so that there is observation for every county */

data access_2021 (keep = year state county share_access share_access_ub share_access_lb subgroup subgroup_type _FREQ_);
 set access_missing_HI_2021 end=eof;
 output;
 if eof then do;
  year = 2021;
  state = "15";
  county = "005";
  share_access = .;
   subgroup = 1;
   subgroup_type = "race-ethnicity";
  output;
 end;
run;
data access_2021 ;
 set access_2021 end=eof;
 output;
 if eof then do;
  year = 2021;
  state = "15";
  county = "005";
  share_access = .;
   subgroup = 2;
   subgroup_type = "race-ethnicity";
  output;
 end;
run;
data access_2021 ;
 set access_2021 end=eof;
 output;
 if eof then do;
  year = 2021;
  state = "15";
  county = "005";
  share_access = .;
   subgroup = 3;
   subgroup_type = "race-ethnicity";
  output;
 end;
run;
data access_2021 ;
 set access_2021 end=eof;
 output;
 if eof then do;
  year = 2021;
  state = "15";
  county = "005";
  share_access = .;
   subgroup = 4;
   subgroup_type = "race-ethnicity";
  output;
 end;
run;
data access_2021 ;
 set access_2021 end=eof;
 output;
 if eof then do;
  year = 2021;
  state = "15";
  county = "005";
  share_access = .;
   subgroup = .;
   subgroup_type = "race-ethnicity";
  output;
 end;
run;


/* put variables in correct order and create formats*/

PROC FORMAT ;
PICTURE Num    .="NA"
				OTHER = "9.99999";
			 run;
data neighbor.metrics_access_subgroup_2021;
 retain year state county subgroup_type	subgroup share_access share_access_ub share_access_lb ;
 set access_2021;
 format share_access share_access_ub share_access_lb num.;
run;

proc export data = neighbor.metrics_access_subgroup_2021
  outfile = "&filepath"
  replace;
run;

