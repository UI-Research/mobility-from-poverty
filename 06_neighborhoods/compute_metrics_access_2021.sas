*=================================================================;
*Compute county-level digital access metric;
*=================================================================;

libname neighbor "V:\Centers\Ibp\KWerner\Kevin\Mobility\gates-mobility-metrics\06_neighborhoods";
%let filepath = V:\Centers\Ibp\KWerner\Kevin\Mobility\gates-mobility-metrics\06_neighborhoods\metrics_access_2021.csv;

/* create binary */
data access;
 	set lib2021.microdata;
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
proc means data=access  (where=(digital_access = 1 and pernum = 1)) noprint; 
  output out=number_hhs_access (drop=_type_ _FREQ_) sum=digital_access;
  by statefip county;
  var hhwt;
run;

/*
proc means data=total_hhs sum;
 var _FREQ_;
run;
*/

/* compute total number of households */
proc means data=access  (where=( pernum = 1)) noprint; 
  output out=total_hhs (drop=_type_) sum=total_hhs;
  by statefip county;
  var hhwt;
run;

/* merges the two datasets and computes the share with access */
data access_missing_HI_2021;
  merge number_hhs_access(in=a) total_hhs(in=b);
  by statefip county;
  share_access = digital_access/total_hhs;
  year = 2021;

  new_county = put(county,z3.); 
  state = put(statefip,z2.);
  drop county statefip;
  rename new_county = county;

  /* compute ub and lb */
  inverse_share = 1-share_access;
  interval_share = 1.96*sqrt((inverse_share*share_access)/_FREQ_);
  share_access_lb = share_access - interval_share;
  share_access_ub = share_access + interval_share;
  
run;

/* add missing HI county so that there is observation for every county */

data access_2021 (keep = year state county share_access share_access_ub share_access_lb);
 set access_missing_HI_2021 end=eof;
 output;
 if eof then do;
  year = 2021;
  state = "15";
  county = "005";
  share_access = .;
  output;
 end;
run;

/* put variables in correct order */
data access_2021;
 retain year state county;
 set access_2021;
run;

proc export data = access_2021
  outfile = "&filepath"
  replace;
run;

