* Note that the directories and IPUMS extracts used in this code mean that the code will not run automatically for external users. This code can be reviewed to determine the process and chronology for contructing the ACS-based Mobility Metrics.


proc import datafile="&networkDir.\geocorr2014_puma_to_county.csv" out=puma_to_county dbms=csv replace;
  getnames=yes;
  guessingrows=100;
  datarow=2;
run;
  
data libmain.puma_to_county;
  set puma_to_county(rename=(county=countytemp));
  length statefip 3;
  length puma 6;
  length county 4;
  statefip=state;
  puma=puma12;
  county=mod(countytemp,1000);/*the last 3-digits are the county code (first 2 are state)*/
  drop state puma12 countytemp;
*Drop records where the weight adjustment is 0 (this only happens for county #5 in Hawaii, which is a 
 very small part of PUMA 100);
  if afact=0 then delete;
  if statefip = 51 and county = 19 then pop10 = 68676 + 6222; /* this is combining county 51515 with 51019 because 51515 was folded in 51019 */
  if statefip = 51 and county = 19 then afact = 0.562 + 0.051; /* this is combining county 51515 with 51019 because 51515 was folded in 51019 */
  if statefip = 51 and county = 515 then delete;
  if statefip = 2 and county = 270 then county = 158;
  if statefip = 46 and county = 113 then county = 102;
run;

/* KW COMMENT: Changed from sort by statefip puma to sort by statefip county */
proc sort data=libmain.puma_to_county;
  by statefip county;
run;

*Create a file that assigns a weight to each county based on 2010 population;
proc means data=libmain.puma_to_county noprint;
  var pop10;
  output out=totpop sum=totpop;
run;
proc means data=libmain.puma_to_county noprint nway;
  var pop10;
  by statefip county;
  output out=countypop sum=countypop;
run;
data libmain.countywgts;
  if _N_=1 then set totpop(keep=totpop);
  retain totpop;
  set countypop (keep=statefip county countypop);
  countywgt=countypop/totpop;
run;
