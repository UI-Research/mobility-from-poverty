/*************
This code reads in the family structure metrics created by Paul, adds confidence intervals,
put it in the right format, and outputs it as a csv
Kevin Werner
7/28/20
*************/

/*
This code uses the SAS dataset output from Paul's compute_metric_famstruc
as input.
*/

%let filepath = V:\Centers\Ibp\KWerner\Kevin\Mobility\gates-mobility-metrics\03_family\metrics_famstruc.csv;

libname paul "V:\Centers\Ibp\KWerner\Kevin\Mobility\gates-mobility-metrics\03_family";


/* create confidence interval using macro for each metric.
	creates one data set per metric */

%macro fam_struc(structure= );
data &structure.(keep = year county state &structure &structure._ub &structure._lb) ;
 set paul.metrics_famstruc;
 year = 2018;
 inverse_&structure = 1 - &structure;
 interval = 1.96*sqrt((inverse_&structure*&structure)/_FREQ_);
 &structure._ub = &structure + interval;
 &structure._lb = &structure - interval;
 if &structure._ub > 1 then &structure._ub = 1;
 if &structure._lb < 0 then &structure._lb = 0; 

 new_county = put(county,z3.); 
 state = put(statefip,z2.);
 drop county statefip;
 rename new_county = county;
run;
%mend fam_struc;
%fam_struc(structure = famstruc_2par_married)
%fam_struc(structure = famstruc_2par_unmarried)
%fam_struc(structure = famstruc_1par_plusadults)
%fam_struc(structure = famstruc_1par_noadults)
%fam_struc(structure = famstruc_0par_2adults)
%fam_struc(structure = famstruc_0par_other)

/* merge all datasets into one */

data all_structure_miss_HI;
 merge famstruc_2par_married famstruc_2par_unmarried famstruc_1par_plusadults famstruc_1par_noadults famstruc_0par_2adults famstruc_0par_other;
 by state county;
run;

data all_structure;
 set all_structure_miss_HI end=eof;
 output;
 if eof then do;
  year = 2018;
  state = "15";
  county = "005";
  famstruc_2par_married = .;
  famstruc_2par_married_ub = .;
  famstruc_2par_married_lb = .;

  famstruc_2par_unmarried = .;
  famstruc_2par_unmarried_ub = .;
  famstruc_2par_unmarried_lb = .;

  famstruc_1par_plusadults = .;
  famstruc_1par_plusadults_ub = .;
  famstruc_1par_plusadults_lb = .;

  famstruc_1par_noadults = .;
  famstruc_1par_noadults_ub = .;
  famstruc_1par_noadults_lb = .;

  famstruc_0par_2adults = .;
  famstruc_0par_2adults_ub = .;	
  famstruc_0par_2adults_lb = .;

  famstruc_0par_other = .;
  famstruc_0par_other_ub = .;
  famstruc_0par_other_lb = .;

  output;
 end;
run;

/* put columns in correct order */

data all_structure;
 retain year state county;
 set all_structure;
run;

proc sort data=all_structure; by year state county; run;

/* export as csv */

proc export data = all_structure
  outfile = "&filepath"
  replace;
run;
