%let project = K:\Ibp\AWilliams\analyses\gates-mobility-metrics\;
libname desktop "K:\Ibp\AWilliams\analyses\gates-mobility-metrics";

/* financial well-being */
%let localDir=&project.01_financial-well-being;
%let networkDir=&project.01_financial-well-being;
%let filepath = &project.01_financial-well-being\metrics_income_subgroup.csv;

/* 03 family */
libname family "&project.03_family";
%let family_filepath = &project.03_family\metrics_famstruc_subgroup.csv;
libname paul "&project.03_family";

/* 08 education */
filename ASCIIDAT "&project.08_education\2018\usa_00017.dat";
libname DTed "&project.08_education\2018\Metrics";
libname edu "&project.08_education";

%let preschool_filepath = &project.metrics_preschool_subgroup.csv;
%let college_filepath = &project.08_education\metrics_college_subgroup.csv;


/* 9 employment */
libname employ "&project.09_employment";
%let employ_filepath = &project.09_employment\metrics_employment_subgroup.csv;
libname paul "&project.09_employment";

