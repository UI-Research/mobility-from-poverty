*=================================================================;
*Compute county-level family-structure-and-stability metrics;
*=================================================================;

%let max_hhsize = 20; /*maximum number of persons that can be in a household*/
options fmtsearch=(lib2018);

 Proc format;
  Value subgroup_f ( default = 30)
 4 = "White, Non-Hispanic"
 1 = "Black, Non-Hispanic"
 3 = "Other Races and Ethnicities"
 2 = "Hispanic"
;
run;

%macro compute_metrics_famstruc(microdata_file,metrics_file);
*order file so all household members are together.  PUMA_county_num is
 included in sort because households in PUMAs that spanned counties 
 were replicated when the mapping from county to PUMA was done.;
proc sort data=&microdata_file. out=microdata;
  by puma_county_num serial pernum;
run;
*Create a file of children (anyone <= 17) with information about each childs
 family structure.  This is done by first reading in all persons from the
 household (storing the needed info in temporary arrays).  Then a do loop
 goes through all the persons lookiong for a child.  WHen one is found, 
 another do loop goes through all the persons looking for parents and non-parent
 adults.  This allows creation of the "famstruc_" variables, and the child is output;
data children;
  set microdata;
  by puma_county_num serial pernum;
  array age_array(&max_hhsize.) _temporary_;
  array marst_array(&max_hhsize.) _temporary_;
  array momloc_array(&max_hhsize.) _temporary_;
  array poploc_array(&max_hhsize.) _temporary_;
  array momloc2_array(&max_hhsize.) _temporary_;
  array poploc2_array(&max_hhsize.) _temporary_;
  if pernum > &max_hhsize. then put "error: more than &max_hhsize. persons: " serial= pernum=;
  age_array(pernum)=age;
  marst_array(pernum)=marst;
  momloc_array(pernum)=momloc;
  poploc_array(pernum)=poploc;
  momloc2_array(pernum)=momloc2;
  poploc2_array(pernum)=poploc2;
  if last.serial then do;
    do i=1 to numprec; /*go though household looking for children*/
    if age_array(i) <= 17 then do; /*found a child*/
      child=i;
    num_nonparent_adults=0;
      num_married_parents=0;
      num_unmarried_parents=0;
      do j=1 to numprec; /*go through household looking for parents and non-parent adults*/
        if j=momloc_array(child) or j=poploc_array(child) or
         j=momloc2_array(child) or j=poploc2_array(child) then do;/*found a parent*/
              if marst_array(j)=1 then num_married_parents+1;
        else num_unmarried_parents+1;
      end;
      else if age>17 then num_nonparent_adults+1;/*found a non-parent adult*/
    end;/*end looking for parents and nonparent adults*/
    /*determine family structure and output this child*/
        famstruc_2par_married=0;
    famstruc_2par_unmarried=0;
    famstruc_1par_plusadults=0;
    famstruc_1par_noadults=0;
    famstruc_0par_2adults=0;
    famstruc_0par_other=0;
    if num_married_parents=2 then famstruc_2par_married=perwt;
    else if num_unmarried_parents=2 then famstruc_2par_unmarried=perwt;
    else if num_unmarried_parents=1 then do;
      if num_nonparent_adults > 0 then famstruc_1par_plusadults=perwt;
      else famstruc_1par_noadults=perwt;
    end;
    else if num_nonparent_adults > 1 then famstruc_0par_2adults=perwt;
    else famstruc_0par_other=perwt;
    output;
        keep statefip county puma_county_num serial child perwt 
             num_nonparent_adults num_married_parents num_unmarried_parents
             famstruc_2par_married famstruc_2par_unmarried
             famstruc_1par_plusadults famstruc_1par_noadults
       famstruc_0par_2adults famstruc_0par_other subgroup
      ;
    end;/*end processing this child*/
  end;/*end looking for children*/
  end;/*end processing this household*/
run;
*Use the file of children to compute the metrics;
proc sort data=children; by statefip county ; run;
proc means data=children noprint nway completetypes; 
  output out=children_summed(drop=_type_) sum=;
  by statefip county ;
  class subgroup /preloadfmt ;
  format subgroup subgroup_f.;
  var perwt famstruc_2par_married famstruc_2par_unmarried
      famstruc_1par_plusadults famstruc_1par_noadults
      famstruc_0par_2adults famstruc_0par_other;
run;
data &metrics_file.;
  set children_summed;
  famstruc_2par_married = famstruc_2par_married/perwt;
  famstruc_2par_unmarried = famstruc_2par_unmarried/perwt;
  famstruc_1par_plusadults = famstruc_1par_plusadults/perwt;
  famstruc_1par_noadults = famstruc_1par_noadults/perwt;
  famstruc_0par_2adults = famstruc_0par_2adults/perwt;
  famstruc_0par_other = famstruc_0par_other/perwt;
  if subgroup = . then delete;
run;
%mend compute_metrics_famstruc;

%compute_metrics_famstruc(lib2018.microdata_5_year,family.metrics_famstruc_subgroup);
