/*************

This code reads in the family structure metrics created compute_metrics_famstruc_5_year_2021, adds confidence intervals,
put it in the right format, and outputs it as a csv

Kevin Werner

3/15/23

*************/


options fmtsearch=(lib2018);

%let suppress = 30;

%let filepath = V:\Centers\Ibp\KWerner\Kevin\Mobility\gates-mobility-metrics\03_family\metrics_famstruc_subgroup_2021.csv;

/* add rows for the missing HI county */
data all_structure;
 set family.metrics_famstruc_subgroup_2021 end=eof;
 output;
 if eof then do;
  statefip = 15;
  county = 5;
  famstruc_2par_married = .;
  famstruc_2par_unmarried = .;
  famstruc_1par_plusadults = .;
  famstruc_1par_noadults = .;
  famstruc_0par_2adults = .;
  famstruc_0par_other = .;
    _FREQ_ = .;
  perwt = .;
  do subgroup = 1 to 4;
   output;
  end;
  subgroup = .;
  output;
 end;
run;


proc sort data=all_structure; by statefip county subgroup; run;


/* create confidence interval using macro for each metric.
  creates one data set per metric */

%macro fam_struc(structure= );
data &structure. (keep = year county state subgroup subgroup_type &structure &structure._ub &structure._lb _FREQ_) ;
 set all_structure;
 year = 2021;
 if subgroup in (1,2,3,4) then subgroup_type = "race-ethnicity";
 else subgroup_type = "all";

  /* suppress values less than 30 */
 if _FREQ_ >= 0 and _FREQ_ < &suppress then &structure = .;

 inverse_&structure = 1 - &structure;
 interval = 1.96*sqrt((inverse_&structure*&structure)/_FREQ_);
 &structure._ub = &structure + interval;
 &structure._lb = &structure - interval;
 if &structure._ub > 1 then &structure._ub =1;
 if &structure._lb ne . and &structure._lb < 0 then &structure._lb =0; 

 new_county = put(county,z3.); 
 state = put(statefip,z2.);
 drop county statefip;
 rename new_county = county;

 if &structure = . and _FREQ_ >= &suppress then &structure = 0;
 if &structure._ub = . and _FREQ_ >= &suppress then &structure._ub = 0;
 if &structure._lb = . and _FREQ_ >= &suppress then &structure._lb = 0;


run;
%mend fam_struc;
%fam_struc(structure = famstruc_2par_married)
%fam_struc(structure = famstruc_2par_unmarried)
%fam_struc(structure = famstruc_1par_plusadults)
%fam_struc(structure = famstruc_1par_noadults)
%fam_struc(structure = famstruc_0par_2adults)
%fam_struc(structure = famstruc_0par_other)

/* merge all datasets into one */

data all_structure_merged;
 merge famstruc_2par_married famstruc_2par_unmarried famstruc_1par_plusadults famstruc_1par_noadults famstruc_0par_2adults famstruc_0par_other;
 by state county subgroup;
run;

/* put columns in correct order and create formats */

PROC FORMAT ;
PICTURE Num    .="NA"
				OTHER = "9.99999";
			 run;

data all_structure_merged;
 retain year state county subgroup_type subgroup;
 set all_structure_merged;
 format famstruc_2par_married	famstruc_2par_married_ub	famstruc_2par_married_lb	famstruc_2par_unmarried	famstruc_2par_unmarried_ub	
	famstruc_2par_unmarried_lb	famstruc_1par_plusadults	famstruc_1par_plusadults_ub	famstruc_1par_plusadults_lb	famstruc_1par_noadults	
	famstruc_1par_noadults_ub	famstruc_1par_noadults_lb	famstruc_0par_2adults	famstruc_0par_2adults_ub	famstruc_0par_2adults_lb	
	famstruc_0par_other	famstruc_0par_other_ub	famstruc_0par_other_lb num.;

run;

proc sort data=all_structure_merged; by year state county subgroup; run;

/* export as csv */

proc export data = all_structure_merged
  outfile = "&filepath"
  replace;
run;