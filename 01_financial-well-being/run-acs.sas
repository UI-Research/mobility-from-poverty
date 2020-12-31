/*
** This program runs all of the PSID family extraction programs
** It writes the output as though they had been run separately--that is the log and lst files are
** written to the correct places.
*/
%include 'sas\sasbatch.inc';
%include 'sas\config.inc';

/* prep */
%sasbatch(1_initial);                          /*  */
%sasbatch(2_puma_to_county);                          /*  */
%sasbatch(3_prepare_microdata_5_year);           /*  */

/* 01_financial-well-being */
%sasbatch(finalize_metrics_income_5_year);

/* 03_family */
*%sasbatch(..\03_family\compute_metrics_famstruc_5_year);
*%sasbatch(..\03_family\finalize_metrics_famstruc_5_year);

/* 08_education */
*%sasbatch(..\08_education\access_to_preschool_5_year);           /*  */
*%sasbatch(..\08_education\compute_metrics_college_5_year);
*%sasbatch(..\08_education\finalize_metrics_college_5_year);

/* 09_employment */
*%sasbatch(..\09_employment\compute_metrics_employment_5_year);
*%sasbatch(..\09_employment\finalize_metrics_employment_5_year);




/* */
*%sasbatch(..\09_employment\data_quality_5_year);

