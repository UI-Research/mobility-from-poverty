*========================================================================;
*Macro to prepare an IPUMS extract of vacant units for metrics processing;
*========================================================================;
%macro prepare_vacant(input_file,microdata_file,output_file);
*Map PUMAs to counties on the file of vacant households, and make adjustments to weight and dollars;
proc sql; 
 create table vacant as 
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
data vacant;
  set vacant;
  if vacancy in (1,2,3); /*excludes seasonal/occasional/migrartory units*/
  hhwt = hhwt*afact1;
  rent = rent*adjust;
  if valueh ne 9999999 then do;
    *Calculate  monthly payment for first-time homebuyers.               
     Using 3.69% as the effective mortgage rate for DC in 2016, *look up rates on FHFA*
     calculate monthly P & I payment using monthly mortgage rate and compounded interest calculation
     ******; 
    valueh=valueh*adjust;
    loan = .9 * valueh;
    month_mortgage= (6.00 / 12) / 100; /*use 6% for mortage rate for testing*/
    monthly_PI = loan * month_mortgage * ((1+month_mortgage)**360)/(((1+month_mortgage)**360)-1);
    *Calculate PMI and taxes/insurance to add to Monthly_PI to find total monthly payment
    ******;               
    PMI = (.007 * loan ) / 12; **typical annual PMI is .007 of loan amount;
    tax_ins = .25 * monthly_PI; **taxes assumed to be 25% of monthly PI; 
    total_monthly_cost = monthly_PI + PMI + tax_ins; **Sum of monthly payment components;
  end;
  if (county = .) then put "error: no match: " serial= statefip= puma=;
run;

data Rent_ratio;
  set &microdata_file.(keep= rent rentgrs pernum ownershpd statefip county
                      where=(pernum=1 and ownershpd in ( 22 )));
  Ratio_rentgrs_rent = rentgrs / rent;
run;
proc means data=Rent_ratio noprint;
  var Ratio_rentgrs_rent;
  by statefip county;
  output out=Rent_ratio_means (keep=statefip county Ratio_rentgrs_rent) mean=;
run;
proc sort data=vacant;
  by statefip county;
run;
data &output_file.;
  merge vacant(in=a) Rent_ratio_means;
  by statefip county;
  if a;
  rentgrs = rent*Ratio_rentgrs_rent;
run;
%mend prepare_vacant;


%prepare_vacant(lib2018.usa_00032,lib2018.microdata,lib2018.vacant);