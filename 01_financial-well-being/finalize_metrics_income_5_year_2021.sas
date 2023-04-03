/*************

this code creates the income metrics for the 2021 subgroup file. 

Kevin Werner

3/15/23

NOTE: per email from Greg on 9/10/20, I have removed the confidence interval code.

*************/

%let filepath = V:\Centers\Ibp\KWerner\Kevin\Mobility\gates-mobility-metrics\01_financial-well-being\metrics_income_subgroup_2021.csv;

%let suppress = 30;

/* this runs on the microdata file output by 3_prepate_microdata_5_year_2021 */

options fmtsearch=(lib2018);

 Proc format;
  Value subgroup_f (MULTILABEL)
 4 = "White, Non-Hispanic"
 1 = "Black, Non-Hispanic"
 3 = "Other Races and Ethnicities"
 2 = "Hispanic"
 . = "All";
;

run;


/******************* income metric *********************/

proc sort data=lib2021.microdata_5_year; by  statefip county subgroup; run;

/* get the percentiles */
proc means data=lib2021.microdata_5_year(where=(pernum=1)) noprint completetypes; 
  output out=income(drop=_type_) p80=pctl_80 p50=pctl_50 p20=pctl_20;
  by statefip county;
  var hhincome;
  weight hhwt;
  class subgroup /PRELOADFMT;
  format subgroup subgroup_f.; 
run;

/* replacing missing with 0 if not actually missing */
data income;
 set income;
 year = 2021;
 new_county = put(county,z3.); 
 state = put(statefip,z2.);
 drop county statefip;
 rename new_county = county;

   /* suppress values less than 30 */
 if _FREQ_ >= 0 and _FREQ_ < &suppress then pctl_80 = .;
 if _FREQ_ >= 0 and _FREQ_ < &suppress then pctl_50 = .;
 if _FREQ_ >= 0 and _FREQ_ < &suppress then pctl_20 = .;

 if pctl_80 = . and _FREQ_ >= &suppress then pctl_80 = 0;
 if pctl_50 = . and _FREQ_ >= &suppress then pctl_50 = 0;
 if pctl_20 = . and _FREQ_ >= &suppress then pctl_20 = 0;

run;


/* add missing HI county so that there is observation for every county */

data income;
 set income end=eof;
 output;
 if eof then do;
  year = 2021;
  state = "15";
  county = "005";
   subgroup_type = "race-ethnicity";
  pctl_20 = .;
  pctl_50 = .;
  pctl_80 = .;
  _FREQ_ = .;
  do subgroup = 1 to 4;
   output;
  end;
  subgroup_type = "all";
  subgroup = .;
  output;
 end;
run;


/* sort final data set and order variables. also create format to turn . into NA*/

PROC FORMAT ;
PICTURE Num    .="NA"
				OTHER = "000000000000.00";
			
			 run;

data income (drop = single_race);
 retain year state county subgroup_type subgroup pctl_20 pctl_50 pctl_80;
 set income;
 if subgroup in (1,2,3,4) then subgroup_type = "race-ethnicity";
 else subgroup_type = "all";
 format pctl_20 pctl_50 pctl_80 num.;
run;

proc sort data=income; by year state county subgroup; run;

/* export as csv */

proc export data = income
  outfile = "&filepath"
  replace;
run;
