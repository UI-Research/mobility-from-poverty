/*************

This code reads in the family structure metrics created by Paul, adds confidence intervals,
put it in the right format, and outputs it as a csv

Kevin Werner

12/1/20

*************/

/*

This code uses the SAS dataset output from Paul's compute_metric_famstruc
as input.

*/

options fmtsearch=(lib2018);

/* add rows for the missing HI county */
data all_structure;
 set family.metrics_famstruc_subgroup end=eof;
 output;
 if eof then do;
  statefip = 15;
  county = 5;
  subgroup = 1;
  famstruc_2par_married = .;
  famstruc_2par_unmarried = .;
  famstruc_1par_plusadults = .;
  famstruc_1par_noadults = .;
  famstruc_0par_2adults = .;
  famstruc_0par_other = .;
    _FREQ_ = .;
  perwt = .;
  output;
 end;
run;

data all_structure;
 set all_structure end=eof;
 output;
 if eof then do;
  statefip = 15;
  county = 5;
  subgroup = 2;
  famstruc_2par_married = .;
  famstruc_2par_unmarried = .;
  famstruc_1par_plusadults = .;
  famstruc_1par_noadults = .;
  famstruc_0par_2adults = .;
  famstruc_0par_other = .;
    _FREQ_ = .;
  perwt = .;
  output;
 end;
run;

data all_structure;
 set all_structure end=eof;
 output;
 if eof then do;
  statefip = 15;
  county = 5;
  subgroup = 3;
  famstruc_2par_married = .;
  famstruc_2par_unmarried = .;
  famstruc_1par_plusadults = .;
  famstruc_1par_noadults = .;
  famstruc_0par_2adults = .;
  famstruc_0par_other = .;
    _FREQ_ = .;
  perwt = .;
  output;
 end;
run;

data all_structure;
 set all_structure end=eof;
 output;
 if eof then do;
  statefip = 15;
  county = 5;
  subgroup = 4;
  famstruc_2par_married = .;
  famstruc_2par_unmarried = .;
  famstruc_1par_plusadults = .;
  famstruc_1par_noadults = .;
  famstruc_0par_2adults = .;
  famstruc_0par_other = .;
    _FREQ_ = .;
  perwt = .;
  output;
 end;
run;

proc sort data=all_structure; by statefip county subgroup; run;


/* create confidence interval using macro for each metric.
  creates one data set per metric */

%macro fam_struc(structure= );
data &structure. (keep = year county state subgroup subgroup_type &structure &structure._ub &structure._lb _FREQ_) ;
 set all_structure;
 year = 2018;
 subgroup_type = "race-ethnicity";
 inverse_&structure = 1 - &structure;
 interval = 1.96*sqrt((inverse_&structure*&structure)/_FREQ_);
 &structure._ub = &structure + interval;
 &structure._lb = &structure - interval;
 if &structure._ub > 1 then &structure._ub =1;
 if &structure._lb < 0 then &structure._lb =0; 

 new_county = put(county,z3.); 
 state = put(statefip,z2.);
 drop county statefip;
 rename new_county = county;

 if &structure = . and _FREQ_ > 0 then &structure = 0;
 if &structure._ub = . and _FREQ_ > 0 then &structure._ub = 0;
 if &structure._lb = . and _FREQ_ > 0 then &structure._lb = 0;
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

/* put columns in correct order */

data all_structure_merged;
 retain year state county subgroup_type subgroup;
 set all_structure_merged;
run;

proc sort data=all_structure_merged; by year state county subgroup; run;

/* export as csv */

proc export data = all_structure_merged
  outfile = "&family_filepath"
  replace;
run;
