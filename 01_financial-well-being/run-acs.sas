/*
** This program runs all of the PSID family extraction programs
** It writes the output as though they had been run separately--that is the log and lst files are
** written to the correct places.
*/
%include 'sas\sasbatch.inc';
%include 'sas\config.inc';

%sasbatch(1_initial);                          /*  */
%sasbatch(2_puma_to_county);                          /*  */


%sasbatch(access_to_preschool_5_year);           /*  */
%sasbatch(finalize_metrics_income_5_year);