*set options to print "%include" statements in log (source2), show statements executed by macros (mprint),
 warn if merged datasets have same variables (msglevel=i), show resolved values of macro varsiables (symbolgen);
options source2 mprint msglevel=i symbolgen;

%let localDir=V:\Centers\Ibp\KWerner\Kevin\Mobility\Paul\Test;
%let networkDir=V:\Centers\Ibp\KWerner\Kevin\Mobility\Paul\Test;

options nofmterr;

libname libmain "&localDir";
libname old  "&localDir.\old";
libname lib2018 "&localDir.\2018";
libname old2018  "&localDir.\2018\old";
libname desktop "C:\Users\kwerner\Desktop\Metrics";
libname lib2014 "&localDir.\2014";

proc format;
  value nzp
  low-<0='neg'
  0='zero'
  0<-high='pos'
  ;
  value valueh
  low-<0='neg'
  0='0'
  9999999='9999999'
  other='pos'
  ;
value fips
01='Alabama'
02='Alaska'
04='Arizona'
05='Arkansas'
06='California'
08='Colorado'
09='Connecticut'
10='Delaware'
11='District of Columbia'
12='Florida'
13='Georgia'
15='Hawaii'
16='Idaho'
17='Illinois'
18='Indiana'
19='Iowa'
20='Kansas'
21='Kentucky'
22='Louisiana'
23='Maine'
24='Maryland'
25='Massachusetts'
26='Michigan'
27='Minnesota'
28='Mississippi'
29='Missouri'
30='Montana'
31='Nebraska'
32='Nevada'
33='New Hampshire'
34='New Jersey'
35='New Mexico'
36='New York'
37='North Carolina'
38='North Dakota'
39='Ohio'
40='Oklahoma'
41='Oregon'
42='Pennsylvania'
44='Rhode Island'
45='South Carolina'
46='South Dakota'
47='Tennessee'
48='Texas'
49='Utah'
50='Vermont'
51='Virginia'
53='Washington'
54='West Virginia'
55='Wisconsin'
56='Wyoming'
;

value s_race
1='White'
2='Black'
3='Non-Hispanic Other'
4='Hispanic';
run;
