/******************************

This program calculates the share of 3 and 4 year olds in pre school.

Note that this uses a SEPERATE raw file than the rest of the ACS metrics
because people in group quarters are included.

Programmed by Kevin Werner

12/1/20

******************************/

/*
   NOTE: You need to edit the `libname` command to specify the path to the directory
   where the data file is located. For example: "C:\ipums_directory".
   Edit the `filename` command similarly to include the full path (the directory and the data file name).
*/

/*%let filepath = V:\Centers\Ibp\KWerner\Kevin\Mobility\gates-mobility-metrics\08_education\metrics_preschool_subgroup.csv;*/

/* 

Please download the file USA_00017.dat from Box, and unzip in the filename folder. 

*/

proc format cntlout = DTed.usa_00017_f;

value YEAR_f
  1850 = "1850"
  1860 = "1860"
  1870 = "1870"
  1880 = "1880"
  1900 = "1900"
  1910 = "1910"
  1920 = "1920"
  1930 = "1930"
  1940 = "1940"
  1950 = "1950"
  1960 = "1960"
  1970 = "1970"
  1980 = "1980"
  1990 = "1990"
  2000 = "2000"
  2001 = "2001"
  2002 = "2002"
  2003 = "2003"
  2004 = "2004"
  2005 = "2005"
  2006 = "2006"
  2007 = "2007"
  2008 = "2008"
  2009 = "2009"
  2010 = "2010"
  2011 = "2011"
  2012 = "2012"
  2013 = "2013"
  2014 = "2014"
  2015 = "2015"
  2016 = "2016"
  2017 = "2017"
  2018 = "2018"
  2019 = "2019"
;

value SAMPLE_f
  201902 = "2019 PRCS"
  201901 = "2019 ACS"
  201804 = "2014-2018, PRCS 5-year"
  201803 = "2014-2018, ACS 5-year"
  201802 = "2018 PRCS"
  201801 = "2018 ACS"
  201704 = "2013-2017, PRCS 5-year"
  201703 = "2013-2017, ACS 5-year"
  201702 = "2017 PRCS"
  201701 = "2017 ACS"
  201604 = "2012-2016, PRCS 5-year"
  201603 = "2012-2016, ACS 5-year"
  201602 = "2016 PRCS"
  201601 = "2016 ACS"
  201504 = "2011-2015, PRCS 5-year"
  201503 = "2011-2015, ACS 5-year"
  201502 = "2015 PRCS"
  201501 = "2015 ACS"
  201404 = "2010-2014, PRCS 5-year"
  201403 = "2010-2014, ACS 5-year"
  201402 = "2014 PRCS"
  201401 = "2014 ACS"
  201306 = "2009-2013, PRCS 5-year"
  201305 = "2009-2013, ACS 5-year"
  201304 = "2011-2013, PRCS 3-year"
  201303 = "2011-2013, ACS 3-year"
  201302 = "2013 PRCS"
  201301 = "2013 ACS"
  201206 = "2008-2012, PRCS 5-year"
  201205 = "2008-2012, ACS 5-year"
  201204 = "2010-2012, PRCS 3-year"
  201203 = "2010-2012, ACS 3-year"
  201202 = "2012 PRCS"
  201201 = "2012 ACS"
  201106 = "2007-2011, PRCS 5-year"
  201105 = "2007-2011, ACS 5-year"
  201104 = "2009-2011, PRCS 3-year"
  201103 = "2009-2011, ACS 3-year"
  201102 = "2011 PRCS"
  201101 = "2011 ACS"
  201008 = "2010 Puerto Rico 10%"
  201007 = "2010 10%"
  201006 = "2006-2010, PRCS 5-year"
  201005 = "2006-2010, ACS 5-year"
  201004 = "2008-2010, PRCS 3-year"
  201003 = "2008-2010, ACS 3-year"
  201002 = "2010 PRCS"
  201001 = "2010 ACS"
  200906 = "2005-2009, PRCS 5-year"
  200905 = "2005-2009, ACS 5-year"
  200904 = "2007-2009, PRCS 3-year"
  200903 = "2007-2009, ACS 3-year"
  200902 = "2009 PRCS"
  200901 = "2009 ACS"
  200804 = "2006-2008, PRCS 3-year"
  200803 = "2006-2008, ACS 3-year"
  200802 = "2008 PRCS"
  200801 = "2008 ACS"
  200704 = "2005-2007, PRCS 3-year"
  200703 = "2005-2007, ACS 3-year"
  200702 = "2007 PRCS"
  200701 = "2007 ACS"
  200602 = "2006 PRCS"
  200601 = "2006 ACS"
  200502 = "2005 PRCS"
  200501 = "2005 ACS"
  200401 = "2004 ACS"
  200301 = "2003 ACS"
  200201 = "2002 ACS"
  200101 = "2001 ACS"
  200008 = "2000 Puerto Rico 1%"
  200007 = "2000 1%"
  200006 = "2000 Puerto Rico 1% sample (old version)"
  200005 = "2000 Puerto Rico 5%"
  200004 = "2000 ACS"
  200003 = "2000 Unweighted 1%"
  200002 = "2000 1% sample (old version)"
  200001 = "2000 5%"
  199007 = "1990 Puerto Rico 1%"
  199006 = "1990 Puerto Rico 5%"
  199005 = "1990 Labor Market Area"
  199004 = "1990 Elderly"
  199003 = "1990 Unweighted 1%"
  199002 = "1990 1%"
  199001 = "1990 5%"
  198007 = "1980 Puerto Rico 1%"
  198006 = "1980 Puerto Rico 5%"
  198005 = "1980 Detailed metro/non-metro"
  198004 = "1980 Labor Market Area"
  198003 = "1980 Urban/Rural"
  198002 = "1980 1%"
  198001 = "1980 5%"
  197009 = "1970 Puerto Rico Neighborhood"
  197008 = "1970 Puerto Rico Municipio"
  197007 = "1970 Puerto Rico State"
  197006 = "1970 Form 2 Neighborhood"
  197005 = "1970 Form 1 Neighborhood"
  197004 = "1970 Form 2 Metro"
  197003 = "1970 Form 1 Metro"
  197002 = "1970 Form 2 State"
  197001 = "1970 Form 1 State"
  196002 = "1960 5%"
  196001 = "1960 1%"
  195001 = "1950 1%"
  194002 = "1940 100% database"
  194001 = "1940 1%"
  193004 = "1930 100% database"
  193003 = "1930 Puerto Rico"
  193002 = "1930 5%"
  193001 = "1930 1%"
  192003 = "1920 100% database"
  192002 = "1920 Puerto Rico sample"
  192001 = "1920 1%"
  191004 = "1910 100% database"
  191003 = "1910 1.4% sample with oversamples"
  191002 = "1910 1%"
  191001 = "1910 Puerto Rico"
  190004 = "1900 100% database"
  190003 = "1900 1% sample with oversamples"
  190002 = "1900 1%"
  190001 = "1900 5%"
  188003 = "1880 100% database"
  188002 = "1880 10%"
  188001 = "1880 1%"
  187003 = "1870 100% database"
  187002 = "1870 1% sample with black oversample"
  187001 = "1870 1%"
  186003 = "1860 100% database"
  186002 = "1860 1% sample with black oversample"
  186001 = "1860 1%"
  185002 = "1850 100% database"
  185001 = "1850 1%"
;

value STATEFIP_f
  01 = "Alabama"
  02 = "Alaska"
  04 = "Arizona"
  05 = "Arkansas"
  06 = "California"
  08 = "Colorado"
  09 = "Connecticut"
  10 = "Delaware"
  11 = "District of Columbia"
  12 = "Florida"
  13 = "Georgia"
  15 = "Hawaii"
  16 = "Idaho"
  17 = "Illinois"
  18 = "Indiana"
  19 = "Iowa"
  20 = "Kansas"
  21 = "Kentucky"
  22 = "Louisiana"
  23 = "Maine"
  24 = "Maryland"
  25 = "Massachusetts"
  26 = "Michigan"
  27 = "Minnesota"
  28 = "Mississippi"
  29 = "Missouri"
  30 = "Montana"
  31 = "Nebraska"
  32 = "Nevada"
  33 = "New Hampshire"
  34 = "New Jersey"
  35 = "New Mexico"
  36 = "New York"
  37 = "North Carolina"
  38 = "North Dakota"
  39 = "Ohio"
  40 = "Oklahoma"
  41 = "Oregon"
  42 = "Pennsylvania"
  44 = "Rhode Island"
  45 = "South Carolina"
  46 = "South Dakota"
  47 = "Tennessee"
  48 = "Texas"
  49 = "Utah"
  50 = "Vermont"
  51 = "Virginia"
  53 = "Washington"
  54 = "West Virginia"
  55 = "Wisconsin"
  56 = "Wyoming"
  61 = "Maine-New Hampshire-Vermont"
  62 = "Massachusetts-Rhode Island"
  63 = "Minnesota-Iowa-Missouri-Kansas-Nebraska-S.Dakota-N.Dakota"
  64 = "Maryland-Delaware"
  65 = "Montana-Idaho-Wyoming"
  66 = "Utah-Nevada"
  67 = "Arizona-New Mexico"
  68 = "Alaska-Hawaii"
  72 = "Puerto Rico"
  97 = "Military/Mil. Reservation"
  99 = "State not identified"
;

value GQ_f
  0 = "Vacant unit"
  1 = "Households under 1970 definition"
  2 = "Additional households under 1990 definition"
  3 = "Group quarters--Institutions"
  4 = "Other group quarters"
  5 = "Additional households under 2000 definition"
  6 = "Fragment"
;

value MOMRULE_f
  00 = "No mother link"
  11 = "Direct link, clarity level 1"
  12 = "Direct link, clarity level 2"
  13 = "Direct link, clarity level 3"
  14 = "Direct link, clarity level 4"
  15 = "Direct link, clarity level 5"
  16 = "Direct link, clarity level 6"
  17 = "Direct link, clarity level 7"
  18 = "Direct link, clarity level 8"
  21 = "Second level link, clarity level 1"
  22 = "Second level link, clarity level 2"
  23 = "Second level link, clarity level 3"
  24 = "Second level link, clarity level 4"
  25 = "Second level link, clarity level 5"
  26 = "Second level link, clarity level 6"
  27 = "Second level link, clarity level 7"
  28 = "Second level link, clarity level 8"
  31 = "Third level link, clarity level 1"
  32 = "Third level link, clarity level 2"
  33 = "Third level link, clarity level 3"
  34 = "Third level link, clarity level 4"
  35 = "Third level link, clarity level 5"
  36 = "Third level link, clarity level 6"
  37 = "Third level link, clarity level 7"
  38 = "Third level link, clarity level 8"
;

value POPRULE_f
  00 = "No father link"
  11 = "Direct link, clarity level 1"
  12 = "Direct link, clarity level 2"
  13 = "Direct link, clarity level 3"
  14 = "Direct link, clarity level 4"
  15 = "Direct link, clarity level 5"
  16 = "Direct link, clarity level 6"
  17 = "Direct link, clarity level 7"
  18 = "Direct link, clarity level 8"
  21 = "Second level link, clarity level 1"
  22 = "Second level link, clarity level 2"
  23 = "Second level link, clarity level 3"
  24 = "Second level link, clarity level 4"
  25 = "Second level link, clarity level 5"
  26 = "Second level link, clarity level 6"
  27 = "Second level link, clarity level 7"
  28 = "Second level link, clarity level 8"
  31 = "Third level link, clarity level 1"
  32 = "Third level link, clarity level 2"
  33 = "Third level link, clarity level 3"
  34 = "Third level link, clarity level 4"
  35 = "Third level link, clarity level 5"
  36 = "Third level link, clarity level 6"
  37 = "Third level link, clarity level 7"
  38 = "Third level link, clarity level 8"
;

value RELATE_f
  01 = "Head/Householder"
  02 = "Spouse"
  03 = "Child"
  04 = "Child-in-law"
  05 = "Parent"
  06 = "Parent-in-Law"
  07 = "Sibling"
  08 = "Sibling-in-Law"
  09 = "Grandchild"
  10 = "Other relatives"
  11 = "Partner, friend, visitor"
  12 = "Other non-relatives"
  13 = "Institutional inmates"
;

value RELATED_f
  0101 = "Head/Householder"
  0201 = "Spouse"
  0202 = "2nd/3rd Wife (Polygamous)"
  0301 = "Child"
  0302 = "Adopted Child"
  0303 = "Stepchild"
  0304 = "Adopted, n.s."
  0401 = "Child-in-law"
  0402 = "Step Child-in-law"
  0501 = "Parent"
  0502 = "Stepparent"
  0601 = "Parent-in-Law"
  0602 = "Stepparent-in-law"
  0701 = "Sibling"
  0702 = "Step/Half/Adopted Sibling"
  0801 = "Sibling-in-Law"
  0802 = "Step/Half Sibling-in-law"
  0901 = "Grandchild"
  0902 = "Adopted Grandchild"
  0903 = "Step Grandchild"
  0904 = "Grandchild-in-law"
  1000 = "Other relatives:"
  1001 = "Other Relatives"
  1011 = "Grandparent"
  1012 = "Step Grandparent"
  1013 = "Grandparent-in-law"
  1021 = "Aunt or Uncle"
  1022 = "Aunt,Uncle-in-law"
  1031 = "Nephew, Niece"
  1032 = "Neph/Niece-in-law"
  1033 = "Step/Adopted Nephew/Niece"
  1034 = "Grand Niece/Nephew"
  1041 = "Cousin"
  1042 = "Cousin-in-law"
  1051 = "Great Grandchild"
  1061 = "Other relatives, nec"
  1100 = "Partner, Friend, Visitor"
  1110 = "Partner/friend"
  1111 = "Friend"
  1112 = "Partner"
  1113 = "Partner/roommate"
  1114 = "Unmarried Partner"
  1115 = "Housemate/Roomate"
  1120 = "Relative of partner"
  1130 = "Concubine/Mistress"
  1131 = "Visitor"
  1132 = "Companion and family of companion"
  1139 = "Allocated partner/friend/visitor"
  1200 = "Other non-relatives"
  1201 = "Roomers/boarders/lodgers"
  1202 = "Boarders"
  1203 = "Lodgers"
  1204 = "Roomer"
  1205 = "Tenant"
  1206 = "Foster child"
  1210 = "Employees:"
  1211 = "Servant"
  1212 = "Housekeeper"
  1213 = "Maid"
  1214 = "Cook"
  1215 = "Nurse"
  1216 = "Other probable domestic employee"
  1217 = "Other employee"
  1219 = "Relative of employee"
  1221 = "Military"
  1222 = "Students"
  1223 = "Members of religious orders"
  1230 = "Other non-relatives"
  1239 = "Allocated other non-relative"
  1240 = "Roomers/boarders/lodgers and foster children"
  1241 = "Roomers/boarders/lodgers"
  1242 = "Foster children"
  1250 = "Employees"
  1251 = "Domestic employees"
  1252 = "Non-domestic employees"
  1253 = "Relative of employee"
  1260 = "Other non-relatives (1990 includes employees)"
  1270 = "Non-inmate 1990"
  1281 = "Head of group quarters"
  1282 = "Employees of group quarters"
  1283 = "Relative of head, staff, or employee group quarters"
  1284 = "Other non-inmate 1940-1959"
  1291 = "Military"
  1292 = "College dormitories"
  1293 = "Residents of rooming houses"
  1294 = "Other non-inmate 1980 (includes employees and non-inmates in"
  1295 = "Other non-inmates 1960-1970 (includes employees)"
  1296 = "Non-inmates in institutions"
  1301 = "Institutional inmates"
  9996 = "Unclassifiable"
  9997 = "Unknown"
  9998 = "Illegible"
  9999 = "Missing"
;

value SEX_f
  1 = "Male"
  2 = "Female"
;

value AGE_f
  000 = "Less than 1 year old"
  001 = "1"
  002 = "2"
  003 = "3"
  004 = "4"
  005 = "5"
  006 = "6"
  007 = "7"
  008 = "8"
  009 = "9"
  010 = "10"
  011 = "11"
  012 = "12"
  013 = "13"
  014 = "14"
  015 = "15"
  016 = "16"
  017 = "17"
  018 = "18"
  019 = "19"
  020 = "20"
  021 = "21"
  022 = "22"
  023 = "23"
  024 = "24"
  025 = "25"
  026 = "26"
  027 = "27"
  028 = "28"
  029 = "29"
  030 = "30"
  031 = "31"
  032 = "32"
  033 = "33"
  034 = "34"
  035 = "35"
  036 = "36"
  037 = "37"
  038 = "38"
  039 = "39"
  040 = "40"
  041 = "41"
  042 = "42"
  043 = "43"
  044 = "44"
  045 = "45"
  046 = "46"
  047 = "47"
  048 = "48"
  049 = "49"
  050 = "50"
  051 = "51"
  052 = "52"
  053 = "53"
  054 = "54"
  055 = "55"
  056 = "56"
  057 = "57"
  058 = "58"
  059 = "59"
  060 = "60"
  061 = "61"
  062 = "62"
  063 = "63"
  064 = "64"
  065 = "65"
  066 = "66"
  067 = "67"
  068 = "68"
  069 = "69"
  070 = "70"
  071 = "71"
  072 = "72"
  073 = "73"
  074 = "74"
  075 = "75"
  076 = "76"
  077 = "77"
  078 = "78"
  079 = "79"
  080 = "80"
  081 = "81"
  082 = "82"
  083 = "83"
  084 = "84"
  085 = "85"
  086 = "86"
  087 = "87"
  088 = "88"
  089 = "89"
  090 = "90 (90+ in 1980 and 1990)"
  091 = "91"
  092 = "92"
  093 = "93"
  094 = "94"
  095 = "95"
  096 = "96"
  097 = "97"
  098 = "98"
  099 = "99"
  100 = "100 (100+ in 1960-1970)"
  101 = "101"
  102 = "102"
  103 = "103"
  104 = "104"
  105 = "105"
  106 = "106"
  107 = "107"
  108 = "108"
  109 = "109"
  110 = "110"
  111 = "111"
  112 = "112 (112+ in the 1980 internal data)"
  113 = "113"
  114 = "114"
  115 = "115 (115+ in the 1990 internal data)"
  116 = "116"
  117 = "117"
  118 = "118"
  119 = "119"
  120 = "120"
  121 = "121"
  122 = "122"
  123 = "123"
  124 = "124"
  125 = "125"
  126 = "126"
  129 = "129"
  130 = "130"
  135 = "135"
;

value MARST_f
  1 = "Married, spouse present"
  2 = "Married, spouse absent"
  3 = "Separated"
  4 = "Divorced"
  5 = "Widowed"
  6 = "Never married/single"
;

value RACE_f
  1 = "White"
  2 = "Black/African American/Negro"
  3 = "American Indian or Alaska Native"
  4 = "Chinese"
  5 = "Japanese"
  6 = "Other Asian or Pacific Islander"
  7 = "Other race, nec"
  8 = "Two major races"
  9 = "Three or more major races"
;

value RACED_f
  100 = "White"
  110 = "Spanish write_in"
  120 = "Blank (white) (1850)"
  130 = "Portuguese"
  140 = "Mexican (1930)"
  150 = "Puerto Rican (1910 Hawaii)"
  200 = "Black/African American/Negro"
  210 = "Mulatto"
  300 = "American Indian/Alaska Native"
  302 = "Apache"
  303 = "Blackfoot"
  304 = "Cherokee"
  305 = "Cheyenne"
  306 = "Chickasaw"
  307 = "Chippewa"
  308 = "Choctaw"
  309 = "Comanche"
  310 = "Creek"
  311 = "Crow"
  312 = "Iroquois"
  313 = "Kiowa"
  314 = "Lumbee"
  315 = "Navajo"
  316 = "Osage"
  317 = "Paiute"
  318 = "Pima"
  319 = "Potawatomi"
  320 = "Pueblo"
  321 = "Seminole"
  322 = "Shoshone"
  323 = "Sioux"
  324 = "Tlingit (Tlingit_Haida, 2000/ACS)"
  325 = "Tohono O Odham"
  326 = "All other tribes (1990)"
  328 = "Hopi"
  329 = "Central American Indian"
  330 = "Spanish American Indian"
  350 = "Delaware"
  351 = "Latin American Indian"
  352 = "Puget Sound Salish"
  353 = "Yakama"
  354 = "Yaqui"
  355 = "Colville"
  356 = "Houma"
  357 = "Menominee"
  358 = "Yuman"
  359 = "South American Indian"
  360 = "Mexican American Indian"
  361 = "Other Amer. Indian tribe (2000,ACS)"
  362 = "2+ Amer. Indian tribes (2000,ACS)"
  370 = "Alaskan Athabaskan"
  371 = "Aleut"
  372 = "Eskimo"
  373 = "Alaskan mixed"
  374 = "Inupiat"
  375 = "Yup'ik"
  379 = "Other Alaska Native tribe(s) (2000,ACS)"
  398 = "Both Am. Ind. and Alaska Native (2000,ACS)"
  399 = "Tribe not specified"
  400 = "Chinese"
  410 = "Taiwanese"
  420 = "Chinese and Taiwanese"
  500 = "Japanese"
  600 = "Filipino"
  610 = "Asian Indian (Hindu 1920_1940)"
  620 = "Korean"
  630 = "Hawaiian"
  631 = "Hawaiian and Asian (1900,1920)"
  632 = "Hawaiian and European (1900,1920)"
  634 = "Hawaiian mixed"
  640 = "Vietnamese"
  641 = "Bhutanese"
  642 = "Mongolian"
  643 = "Nepalese"
  650 = "Other Asian or Pacific Islander (1920,1980)"
  651 = "Asian only (CPS)"
  652 = "Pacific Islander only (CPS)"
  653 = "Asian or Pacific Islander, n.s. (1990 Internal Census files)"
  660 = "Cambodian"
  661 = "Hmong"
  662 = "Laotian"
  663 = "Thai"
  664 = "Bangladeshi"
  665 = "Burmese"
  666 = "Indonesian"
  667 = "Malaysian"
  668 = "Okinawan"
  669 = "Pakistani"
  670 = "Sri Lankan"
  671 = "Other Asian, n.e.c."
  672 = "Asian, not specified"
  673 = "Chinese and Japanese"
  674 = "Chinese and Filipino"
  675 = "Chinese and Vietnamese"
  676 = "Chinese and Asian write_in"
  677 = "Japanese and Filipino"
  678 = "Asian Indian and Asian write_in"
  679 = "Other Asian race combinations"
  680 = "Samoan"
  681 = "Tahitian"
  682 = "Tongan"
  683 = "Other Polynesian (1990)"
  684 = "1+ other Polynesian races (2000,ACS)"
  685 = "Guamanian/Chamorro"
  686 = "Northern Mariana Islander"
  687 = "Palauan"
  688 = "Other Micronesian (1990)"
  689 = "1+ other Micronesian races (2000,ACS)"
  690 = "Fijian"
  691 = "Other Melanesian (1990)"
  692 = "1+ other Melanesian races (2000,ACS)"
  698 = "2+ PI races from 2+ PI regions"
  699 = "Pacific Islander, n.s."
  700 = "Other race, n.e.c."
  801 = "White and Black"
  802 = "White and AIAN"
  810 = "White and Asian"
  811 = "White and Chinese"
  812 = "White and Japanese"
  813 = "White and Filipino"
  814 = "White and Asian Indian"
  815 = "White and Korean"
  816 = "White and Vietnamese"
  817 = "White and Asian write_in"
  818 = "White and other Asian race(s)"
  819 = "White and two or more Asian groups"
  820 = "White and PI"
  821 = "White and Native Hawaiian"
  822 = "White and Samoan"
  823 = "White and Guamanian"
  824 = "White and PI write_in"
  825 = "White and other PI race(s)"
  826 = "White and other race write_in"
  827 = "White and other race, n.e.c."
  830 = "Black and AIAN"
  831 = "Black and Asian"
  832 = "Black and Chinese"
  833 = "Black and Japanese"
  834 = "Black and Filipino"
  835 = "Black and Asian Indian"
  836 = "Black and Korean"
  837 = "Black and Asian write_in"
  838 = "Black and other Asian race(s)"
  840 = "Black and PI"
  841 = "Black and PI write_in"
  842 = "Black and other PI race(s)"
  845 = "Black and other race write_in"
  850 = "AIAN and Asian"
  851 = "AIAN and Filipino (2000 1%)"
  852 = "AIAN and Asian Indian"
  853 = "AIAN and Asian write_in (2000 1%)"
  854 = "AIAN and other Asian race(s)"
  855 = "AIAN and PI"
  856 = "AIAN and other race write_in"
  860 = "Asian and PI"
  861 = "Chinese and Hawaiian"
  862 = "Chinese, Filipino, Hawaiian (2000 1%)"
  863 = "Japanese and Hawaiian (2000 1%)"
  864 = "Filipino and Hawaiian"
  865 = "Filipino and PI write_in"
  866 = "Asian Indian and PI write_in (2000 1%)"
  867 = "Asian write_in and PI write_in"
  868 = "Other Asian race(s) and PI race(s)"
  869 = "Japanese and Korean (ACS)"
  880 = "Asian and other race write_in"
  881 = "Chinese and other race write_in"
  882 = "Japanese and other race write_in"
  883 = "Filipino and other race write_in"
  884 = "Asian Indian and other race write_in"
  885 = "Asian write_in and other race write_in"
  886 = "Other Asian race(s) and other race write_in"
  887 = "Chinese and Korean"
  890 = "PI and other race write_in:"
  891 = "PI write_in and other race write_in"
  892 = "Other PI race(s) and other race write_in"
  893 = "Native Hawaiian or PI other race(s)"
  899 = "API and other race write_in"
  901 = "White, Black, AIAN"
  902 = "White, Black, Asian"
  903 = "White, Black, PI"
  904 = "White, Black, other race write_in"
  905 = "White, AIAN, Asian"
  906 = "White, AIAN, PI"
  907 = "White, AIAN, other race write_in"
  910 = "White, Asian, PI"
  911 = "White, Chinese, Hawaiian"
  912 = "White, Chinese, Filipino, Hawaiian (2000 1%)"
  913 = "White, Japanese, Hawaiian (2000 1%)"
  914 = "White, Filipino, Hawaiian"
  915 = "Other White, Asian race(s), PI race(s)"
  916 = "White, AIAN and Filipino"
  917 = "White, Black, and Filipino"
  920 = "White, Asian, other race write_in"
  921 = "White, Filipino, other race write_in (2000 1%)"
  922 = "White, Asian write_in, other race write_in (2000 1%)"
  923 = "Other White, Asian race(s), other race write_in (2000 1%)"
  925 = "White, PI, other race write_in"
  930 = "Black, AIAN, Asian"
  931 = "Black, AIAN, PI"
  932 = "Black, AIAN, other race write_in"
  933 = "Black, Asian, PI"
  934 = "Black, Asian, other race write_in"
  935 = "Black, PI, other race write_in"
  940 = "AIAN, Asian, PI"
  941 = "AIAN, Asian, other race write_in"
  942 = "AIAN, PI, other race write_in"
  943 = "Asian, PI, other race write_in"
  944 = "Asian (Chinese, Japanese, Korean, Vietnamese); and Native Hawaiian or PI; and Other"
  949 = "2 or 3 races (CPS)"
  950 = "White, Black, AIAN, Asian"
  951 = "White, Black, AIAN, PI"
  952 = "White, Black, AIAN, other race write_in"
  953 = "White, Black, Asian, PI"
  954 = "White, Black, Asian, other race write_in"
  955 = "White, Black, PI, other race write_in"
  960 = "White, AIAN, Asian, PI"
  961 = "White, AIAN, Asian, other race write_in"
  962 = "White, AIAN, PI, other race write_in"
  963 = "White, Asian, PI, other race write_in"
  964 = "White, Chinese, Japanese, Native Hawaiian"
  970 = "Black, AIAN, Asian, PI"
  971 = "Black, AIAN, Asian, other race write_in"
  972 = "Black, AIAN, PI, other race write_in"
  973 = "Black, Asian, PI, other race write_in"
  974 = "AIAN, Asian, PI, other race write_in"
  975 = "AIAN, Asian, PI, Hawaiian other race write_in"
  976 = "Two specified Asian  (Chinese and other Asian, Chinese and Japanese, Japanese and other Asian, Korea"
        "n and other Asian); Native Hawaiian/PI; and Other Race"
  980 = "White, Black, AIAN, Asian, PI"
  981 = "White, Black, AIAN, Asian, other race write_in"
  982 = "White, Black, AIAN, PI, other race write_in"
  983 = "White, Black, Asian, PI, other race write_in"
  984 = "White, AIAN, Asian, PI, other race write_in"
  985 = "Black, AIAN, Asian, PI, other race write_in"
  986 = "Black, AIAN, Asian, PI, Hawaiian, other race write_in"
  989 = "4 or 5 races (CPS)"
  990 = "White, Black, AIAN, Asian, PI, other race write_in"
  991 = "White race; Some other race; Black or African American race and/or American Indian and Alaska Native"
        " race and/or Asian groups and/or Native Hawaiian and Other Pacific Islander groups"
  996 = "2+ races, n.e.c. (CPS)"
;

value HISPAN_f
  0 = "Not Hispanic"
  1 = "Mexican"
  2 = "Puerto Rican"
  3 = "Cuban"
  4 = "Other"
  9 = "Not Reported"
;

value HISPAND_f
  000 = "Not Hispanic"
  100 = "Mexican"
  102 = "Mexican American"
  103 = "Mexicano/Mexicana"
  104 = "Chicano/Chicana"
  105 = "La Raza"
  106 = "Mexican American Indian"
  107 = "Mexico"
  200 = "Puerto Rican"
  300 = "Cuban"
  401 = "Central American Indian"
  402 = "Canal Zone"
  411 = "Costa Rican"
  412 = "Guatemalan"
  413 = "Honduran"
  414 = "Nicaraguan"
  415 = "Panamanian"
  416 = "Salvadoran"
  417 = "Central American, n.e.c."
  420 = "Argentinean"
  421 = "Bolivian"
  422 = "Chilean"
  423 = "Colombian"
  424 = "Ecuadorian"
  425 = "Paraguayan"
  426 = "Peruvian"
  427 = "Uruguayan"
  428 = "Venezuelan"
  429 = "South American Indian"
  430 = "Criollo"
  431 = "South American, n.e.c."
  450 = "Spaniard"
  451 = "Andalusian"
  452 = "Asturian"
  453 = "Castillian"
  454 = "Catalonian"
  455 = "Balearic Islander"
  456 = "Gallego"
  457 = "Valencian"
  458 = "Canarian"
  459 = "Spanish Basque"
  460 = "Dominican"
  465 = "Latin American"
  470 = "Hispanic"
  480 = "Spanish"
  490 = "Californio"
  491 = "Tejano"
  492 = "Nuevo Mexicano"
  493 = "Spanish American"
  494 = "Spanish American Indian"
  495 = "Meso American Indian"
  496 = "Mestizo"
  498 = "Other, n.s."
  499 = "Other, n.e.c."
  900 = "Not Reported"
;

value CITIZEN_f
  0 = "N/A"
  1 = "Born abroad of American parents"
  2 = "Naturalized citizen"
  3 = "Not a citizen"
  4 = "Not a citizen, but has received first papers"
  5 = "Foreign born, citizenship status not reported"
;

value SCHOOL_f
  0 = "N/A"
  1 = "No, not in school"
  2 = "Yes, in school"
  9 = "Missing"
;

value EDUC_f
  00 = "N/A or no schooling"
  01 = "Nursery school to grade 4"
  02 = "Grade 5, 6, 7, or 8"
  03 = "Grade 9"
  04 = "Grade 10"
  05 = "Grade 11"
  06 = "Grade 12"
  07 = "1 year of college"
  08 = "2 years of college"
  09 = "3 years of college"
  10 = "4 years of college"
  11 = "5+ years of college"
;

value EDUCD_f
  000 = "N/A or no schooling"
  001 = "N/A"
  002 = "No schooling completed"
  010 = "Nursery school to grade 4"
  011 = "Nursery school, preschool"
  012 = "Kindergarten"
  013 = "Grade 1, 2, 3, or 4"
  014 = "Grade 1"
  015 = "Grade 2"
  016 = "Grade 3"
  017 = "Grade 4"
  020 = "Grade 5, 6, 7, or 8"
  021 = "Grade 5 or 6"
  022 = "Grade 5"
  023 = "Grade 6"
  024 = "Grade 7 or 8"
  025 = "Grade 7"
  026 = "Grade 8"
  030 = "Grade 9"
  040 = "Grade 10"
  050 = "Grade 11"
  060 = "Grade 12"
  061 = "12th grade, no diploma"
  062 = "High school graduate or GED"
  063 = "Regular high school diploma"
  064 = "GED or alternative credential"
  065 = "Some college, but less than 1 year"
  070 = "1 year of college"
  071 = "1 or more years of college credit, no degree"
  080 = "2 years of college"
  081 = "Associate's degree, type not specified"
  082 = "Associate's degree, occupational program"
  083 = "Associate's degree, academic program"
  090 = "3 years of college"
  100 = "4 years of college"
  101 = "Bachelor's degree"
  110 = "5+ years of college"
  111 = "6 years of college (6+ in 1960-1970)"
  112 = "7 years of college"
  113 = "8+ years of college"
  114 = "Master's degree"
  115 = "Professional degree beyond a bachelor's degree"
  116 = "Doctoral degree"
  999 = "Missing"
;

value GRADEATT_f
  0 = "N/A"
  1 = "Nursery school/preschool"
  2 = "Kindergarten"
  3 = "Grade 1 to grade 4"
  4 = "Grade 5 to grade 8"
  5 = "Grade 9 to grade 12"
  6 = "College undergraduate"
  7 = "Graduate or professional school"
;

value GRADEATTD_f
  00 = "N/A"
  10 = "Nursery school/preschool"
  20 = "Kindergarten"
  30 = "Grade 1 to grade 4"
  31 = "Grade 1"
  32 = "Grade 2"
  33 = "Grade 3"
  34 = "Grade 4"
  40 = "Grade 5 to grade 8"
  41 = "Grade 5"
  42 = "Grade 6"
  43 = "Grade 7"
  44 = "Grade 8"
  50 = "Grade 9 to grade 12"
  51 = "Grade 9"
  52 = "Grade 10"
  53 = "Grade 11"
  54 = "Grade 12"
  60 = "College undergraduate"
  61 = "First year of college"
  62 = "Second year of college"
  63 = "Third year of college"
  64 = "Fourth year of college"
  70 = "Graduate or professional school"
  71 = "Fifth year of college"
  72 = "Sixth year of college"
  73 = "Seventh year of college"
  74 = "Eighth year of college"
;

value EMPSTAT_f
  0 = "N/A"
  1 = "Employed"
  2 = "Unemployed"
  3 = "Not in labor force"
;

value EMPSTATD_f
  00 = "N/A"
  10 = "At work"
  11 = "At work, public emerg"
  12 = "Has job, not working"
  13 = "Armed forces"
  14 = "Armed forces--at work"
  15 = "Armed forces--not at work but with job"
  20 = "Unemployed"
  21 = "Unemp, exper worker"
  22 = "Unemp, new worker"
  30 = "Not in Labor Force"
  31 = "NILF, housework"
  32 = "NILF, unable to work"
  33 = "NILF, school"
  34 = "NILF, other"
;

run;

data raw_preschool;
infile ASCIIDAT pad missover lrecl=154;

input
  YEAR        1-4
  MULTYEAR    5-8
  SAMPLE      9-14
  SERIAL      15-22
  CBSERIAL    23-35
  NUMPREC     36-37
  HHWT        38-47 .2
  CLUSTER     48-60
  ADJUST      61-67 .6
  STATEFIP    68-69
  PUMA        70-74
  STRATA      75-86
  GQ          87-87
  HHINCOME    88-94
  PERNUM      95-98
  PERWT       99-108 .2
  MOMLOC      109-110
  MOMRULE     111-112
  POPLOC      113-114
  POPRULE     115-116
  SPLOC       117-118
  MOMLOC2     119-120
  POPLOC2     121-122
  RELATE      123-124
  RELATED     125-128
  SEX         129-129
  AGE         130-132
  MARST       133-133
  RACE        134-134
  RACED       135-137
  HISPAN      138-138
  HISPAND     139-141
  CITIZEN     142-142
  SCHOOL      143-143
  EDUC        144-145
  EDUCD       146-148
  GRADEATT    149-149
  GRADEATTD   150-151
  EMPSTAT     152-152
  EMPSTATD    153-154
;

label
  YEAR      = "Census year"
  MULTYEAR  = "Actual year of survey, multi-year ACS/PRCS"
  SAMPLE    = "IPUMS sample identifier"
  SERIAL    = "Household serial number"
  CBSERIAL  = "Original Census Bureau household serial number"
  NUMPREC   = "Number of person records following"
  HHWT      = "Household weight"
  CLUSTER   = "Household cluster for variance estimation"
  ADJUST    = "Adjustment factor, ACS/PRCS"
  STATEFIP  = "State (FIPS code)"
  PUMA      = "Public Use Microdata Area"
  STRATA    = "Household strata for variance estimation"
  GQ        = "Group quarters status"
  HHINCOME  = "Total household income"
  PERNUM    = "Person number in sample unit"
  PERWT     = "Person weight"
  MOMLOC    = "Mother's location in the household"
  MOMRULE   = "Rule for linking mother (new)"
  POPLOC    = "Father's location in the household"
  POPRULE   = "Rule for linking father (new)"
  SPLOC     = "Spouse's location in household"
  MOMLOC2   = "Second mother's location in the household"
  POPLOC2   = "Second father's location in the household"
  RELATE    = "Relationship to household head [general version]"
  RELATED   = "Relationship to household head [detailed version]"
  SEX       = "Sex"
  AGE       = "Age"
  MARST     = "Marital status"
  RACE      = "Race [general version]"
  RACED     = "Race [detailed version]"
  HISPAN    = "Hispanic origin [general version]"
  HISPAND   = "Hispanic origin [detailed version]"
  CITIZEN   = "Citizenship status"
  SCHOOL    = "School attendance"
  EDUC      = "Educational attainment [general version]"
  EDUCD     = "Educational attainment [detailed version]"
  GRADEATT  = "Grade level attending [general version]"
  GRADEATTD = "Grade level attending [detailed version]"
  EMPSTAT   = "Employment status [general version]"
  EMPSTATD  = "Employment status [detailed version]"
;

format
  YEAR       YEAR_f.
  SAMPLE     SAMPLE_f.
  STATEFIP   STATEFIP_f.
  GQ         GQ_f.
  MOMRULE    MOMRULE_f.
  POPRULE    POPRULE_f.
  RELATE     RELATE_f.
  RELATED    RELATED_f.
  SEX        SEX_f.
  AGE        AGE_f.
  MARST      MARST_f.
  RACE       RACE_f.
  RACED      RACED_f.
  HISPAN     HISPAN_f.
  HISPAND    HISPAND_f.
  CITIZEN    CITIZEN_f.
  SCHOOL     SCHOOL_f.
  EDUC       EDUC_f.
  EDUCD      EDUCD_f.
  GRADEATT   GRADEATT_f.
  GRADEATTD  GRADEATTD_f.
  EMPSTAT    EMPSTAT_f.
  EMPSTATD   EMPSTATD_f.
;

format
  CBSERIAL   13.
  HHWT       11.2
  CLUSTER    13.
  STRATA     12.
  PERWT      11.2
;

run;

/************** create county indicator (copied from Paul) ****************/



%macro prepare_microdata(input_file,output_file);

*Map PUMAs to counties (this consolidates records for multi-PUMAs counties, and expands records for PUMAs that span counties);
proc sql; 
 create table add_county as 
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

*Add an indicator of whether the puma-to-county match resulted in the creation of additional records (i.e. did
 the PUMA span counties?);
proc sort data=add_county;
  by serial pernum;
run;
proc means data=add_county noprint;
  by serial pernum;
  output out=num_of_counties_in_puma n=num_of_counties_in_puma;
run;
data add_num_of_counties;
  merge add_county num_of_counties_in_puma(keep=serial pernum num_of_counties_in_puma);
  by serial pernum;
  if first.pernum then puma_county_num=1;
  else puma_county_num+1;
run;

*Print error message for any record that did not have a match in the PUMA-to_county file;
*Adjust weight to acount for PUMA-to-county mapping (this only affects PUMAs that span county).;
*KW: Set people who live in county 515 in state 51 to live county 019 instead (Bedford city was absorbed into Bedford county);
data &output_file.;
  set add_num_of_counties;
  if (county = .) then put "error: no match: " serial= statefip= puma=;
  hhwt = hhwt*afact1;
  perwt = perwt*afact1;
  if statefip = 51 and county = 515 then county = 19;
  if statefip = 2 and county = 270 then county = 158;
  if statefip = 46 and county = 113 then county = 102;
run;

*Sort into order most useful for calculating metrics;
proc sort data=&output_file.;
  by statefip county;
run;
%mend prepare_microdata;


%prepare_microdata(raw_preschool, main);



/************** Start actual coding for the preschool metric ****************/

data main; 
 set main;
   /* create race categories */
   /* values for RACE:
	1	White	
	2	Black/African American/Negro	
	3	American Indian or Alaska Native
	4	Chinese
	5	Japanese	
	6	Other Asian or Pacific Islander
	7	Other race, nec	
	8	Two major races	
	9	Three or more major races	

  	values for HISPAN:
  	0	Not Hispanic
	1	Mexican
	2	Puerto Rican·
	3	Cuban
	4	Other
	9	Not Reported
  */

  if hispan = 0 then do;
   if race = 1 then subgroup = 4 /* white */;
   else if race = 2 then subgroup = 1 /* black */;
   else if race in (3,4,5,6,7,8,9) then subgroup = 3 /* other */;
   else subgroup = .;
  end;
  else if hispan in (1,2,3,4) then subgroup = 2 /* hispanic */;
  else subgroup = .;

  
 run;

 Proc format;
  Value subgroup_f
 4 = "White, Non Hispanic"
 1 = "Black, Non Hispanic"
 3 = "Other Races and Ethnicities"
 2 = "Hispanic"
;

run;

%macro compute_metrics_preschool(microdata_file,metrics_file);
proc sort data=&microdata_file.; by statefip county subgroup; run;

/* outputs a file with only children 3-4 */
proc means data=&microdata_file.(where=(age in (3,4))) noprint completetypes; 
  output out=num_3_and_4(drop=_type_) sum=num_3_and_4;
  by statefip county ;
  class subgroup /preloadfmt ;
  var perwt;
  format subgroup subgroup_f.; 
run;

data num_3_and_4;
 set num_3_and_4;
 if subgroup = . then delete;
run;

/* outputs a file with only children 3-4 AND in pre school */
/* gradeatt values from IPUMS:
0		N/A
1		Nursery school/preschool
2		Kindergarten
3		Grade 1 to grade 4
4		Grade 5 to grade 8
5		Grade 9 to grade 12
6		College undergraduate
7		Graduate or professional school
*/
proc means data=&microdata_file.(where=(age in (3,4) and gradeatt=1)) noprint completetypes; 
  output out=num_in_preschool(drop=_type_ _freq_) sum=num_in_preschool;
  by statefip county ;
  class subgroup /preloadfmt ;
  var perwt;
  format subgroup subgroup_f.;
run;

data num_in_preschool;
 set num_in_preschool;
 if subgroup = . then delete;
run;

/* combines the two files to get share in pre school */
data &metrics_file.;
  merge num_3_and_4(in=a) num_in_preschool(in=b);
  by statefip county subgroup;
  if not a or not b then put "error: missing a matching obs: " statefip= county= num_3_and_4= num_in_preschool=;
  else if num_3_and_4 <=0 then put "warning: no 3 or 4 yr-olds: " statefip= county= num_3_and_4= num_in_preschool=;
  else share_in_preschool = num_in_preschool/num_3_and_4;
run;
%mend compute_metrics_preschool;

%compute_metrics_preschool(main,metrics_preschool_v2);


/* create confidence interval and correctly format variables */

data data_missing_HI (keep = year county state share_in_preschool share_in_preschool_ub share_in_preschool_lb _FREQ_ subgroup subgroup_type)  ;
 set metrics_preschool_v2;
 year = 2018;
 not_in_pre = 1 - share_in_preschool;
 interval = 1.96*sqrt((not_in_pre*share_in_preschool)/_FREQ_);
 share_in_preschool_ub = share_in_preschool + interval;
 share_in_preschool_lb = share_in_preschool - interval;
 if share_in_preschool_ub > 1 then share_in_preschool_ub = 1;
 if share_in_preschool_lb < 0 then share_in_preschool_lb = 0;

 new_county = put(county,z3.); 
 state = put(statefip,z2.);
 drop county statefip;
 rename new_county = county;
 subgroup_type = "race-ethnicity";
run;

/* add missing HI county so that there is observation for every county */

data edu.metrics_preschool_subgroup;
 set data_missing_HI end=eof;
 output;
 if eof then do;
  year = 2018;
  state = "15";
  county = "005";
  subgroup_type = "race-ethnicity";
  subgroup = 1;
  share_in_preschool = "";
  share_in_preschool_ub = "";
  share_in_preschool_lb = "";
  _FREQ_ = .;
  output;
 end;
run;
data edu.metrics_preschool_subgroup;
 set edu.metrics_preschool_subgroup end=eof;
 output;
 if eof then do;
  year = 2018;
  state = "15";
  county = "005";
  subgroup_type = "race-ethnicity";
  subgroup = 2;
  share_in_preschool = "";
  share_in_preschool_ub = "";
  share_in_preschool_lb = "";
  _FREQ_ = .;
  output;
 end;
run;
data edu.metrics_preschool_subgroup;
 set edu.metrics_preschool_subgroup end=eof;
 output;
 if eof then do;
  year = 2018;
  state = "15";
  county = "005";
  subgroup_type = "race-ethnicity";
  subgroup = 3;
  share_in_preschool = "";
  share_in_preschool_ub = "";
  share_in_preschool_lb = "";
  _FREQ_ = .;
  output;
 end;
run;
data edu.metrics_preschool_subgroup;
 set edu.metrics_preschool_subgroup end=eof;
 output;
 if eof then do;
  year = 2018;
  state = "15";
  county = "005";
  subgroup_type = "race-ethnicity";
  subgroup = 4;
  share_in_preschool = "";
  share_in_preschool_ub = "";
  share_in_preschool_lb = "";
  _FREQ_ = .;
  output;
 end;
run;


/* sort final data set and order variables*/

data edu.metrics_preschool_subgroup;
 retain year state county subgroup_type subgroup share_in_preschool share_in_preschool_ub share_in_preschool_lb;
 set edu.metrics_preschool_subgroup;
 if share_in_preschool = . and _FREQ_ > 0 then share_in_preschool = 0;
 if share_in_preschool_ub = . and _FREQ_ > 0 then share_in_preschool_ub = 0;
 if share_in_preschool_lb = . and _FREQ_ > 0 then share_in_preschool_lb = 0;
run;

proc sort data=edu.metrics_preschool_subgroup; by year state county subgroup; run;



/* export as csv */

proc export data = edu.metrics_preschool_subgroup
  outfile = "&preschool_filepath"
  replace;
run;


