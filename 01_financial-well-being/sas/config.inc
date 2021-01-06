%let project = V:\Centers\Ibp\KWerner\Kevin\Mobility\gates-mobility-metrics\;
libname desktop "C:\Users\kwerner\Desktop\Metrics";

/* financial well-being */
%let localDir=&project.01_financial-well-being;
%let networkDir=&project.01_financial-well-being;
%let filepath = &project.01_financial-well-being\metrics_income_subgroup.csv;

/* 03 family */
libname family "&project.03_family";
%let family_filepath = &project.03_family\metrics_famstruc_subgroup.csv;
libname paul "&project.03_family";

/* 08 education */
filename ASCIIDAT "C:\Users\kwerner\Desktop\Metrics\usa_00017.dat";
libname DTed "C:\Users\kwerner\Desktop\Metrics";
libname edu "&project.08_education";

%let preschool_filepath = &project.08_education\metrics_preschool_subgroup.csv;
%let college_filepath = &project.08_education\metrics_college_subgroup.csv;


/* 9 employment */
libname employ "&project.09_employment";
%let employ_filepath = &project.09_employment\metrics_employment_subgroup.csv;
libname paul "&project.09_employment";

