%macro scanlog (infile);
  options nodate nonumber noxwait;

  data files;
    infile "&infile..log" dsd dlm='09'x truncover;
    input line $200.;
    length filenm $200.;
    filenm="&infile..log";

    if index(line,'fatal') then cnt1+1;
    if substr(line,1,5)='ERROR' then cnt2+1;
    if substr(line,1,7)='WARNING' then cnt3+1;
    if index(line,'uninitialized') then cnt4+1;
    if index(line,'MERGE statement has more than') then cnt5+1;
    if index(line,'values have been converted') then cnt6+1;
    if index(line,'Note: Missing') then cnt7+1;
    if index(line,'Note: Invalid argument') then cnt8+1;
    if index(line,'W.D format was too small') then cnt9+1;
    if index(line,'has 0 observations') then cnt10+1;
    if index(line,'variables not in') then cnt11+1;
    if index(line,'variables have conflicting') then cnt12+1;
    if index(line,'unequal') then cnt13+1;
    if index(line,'Division by zero detected') then cnt14+1;
    if index(line,'operations could not be performed') then cnt15+1;
    if index(line,'duplicate key values were deleted') then cnt16+1;
  run;

  /*
  ** create a data file with the maximum number of each type of error
  */
  proc univariate data=files noprint;
    by filenm;
    var cnt1-cnt16;
    output out=stat1 max=max1-max16;
  run;

  /*
  ** convert from one row with n variables
  ** to n rows with one variable
  ** keep only observations with nonzero maxN
  */
  proc transpose data=stat1 out=stat2(where=(col1>0));
    by filenm;
    var max1-max16;
  run;

  /*
  ** assign a meaningful description for each error type
  */
  data final;
    set stat2;      /* output of proc transpose */

    length desc $100.;
    if lowcase(_name_)='max1' then desc='fatal';
    if lowcase(_name_)='max2' then desc='ERROR';
    if lowcase(_name_)='max3' then desc='WARNING:';
    if lowcase(_name_)='max4' then desc='uninitialized';
    if lowcase(_name_)='max5' then desc='Merge statement has more than one data set with repeats of BY values';
    if lowcase(_name_)='max6' then desc='values have been converted';
    if lowcase(_name_)='max7' then desc='Note: Missing';
    if lowcase(_name_)='max8' then desc='Note: Invalid argument';
    if lowcase(_name_)='max9' then desc='W.D format was too small';
    if lowcase(_name_)='max10' then desc='has 0 observations';
    if lowcase(_name_)='max11' then desc='variables not in';
    if lowcase(_name_)='max12' then desc='variables have conflicting attributes';
    if lowcase(_name_)='max13' then desc='unequal';
    if lowcase(_name_)='max14' then desc='Division by zero detected';
    if lowcase(_name_)='max15' then desc='Mathematical operation could not be performed';
    if lowcase(_name_)='max16' then desc='observations with duplicate key values were deleted';
    drop _name_ _label_;
  run;  /* final data step */


  /*
  ** print the report
  */
  proc print data=final;
    title2 "final";
  run;
%mend scanlog;

%macro scanError(infile);
  filename ddin "&infile..log";

  /* Let SAS sleep for 10 seconds to let the prior step finish with the log */
  data _null_;
    SLEPT=sleep (10);
  RUN;

  data _null_;
    infile ddin pad;
    input oline $char244.;
    length oline $ 244;

    if substr(oline,1,5)='ERROR' then put "&infile " oline;

    x=index(oline,"SAS System stopped");
    if x>0 then put "&infile " oline;

    x=index(oline,"Syntax error");
    if x>0 then put "&infile " oline;

    x=index(oline,"observations");
    if x>0 then put "&infile " oline;

    x=index(oline,"uninitialized");
    if x>0 then put "&infile " oline;

  run;
%mend scanError;


%macro sasbatch(program);
  options source source2 nocenter date notes number pageno=1 nomprint nosymbolgen FORMCHAR="|----|+|---+=|-/\<>*" missing=".";
  title;

  Proc printto log="&program..log" print="&program..lst" new;
  run;

  %include "&program..sas";

  proc printto;
  run;

  title;

  /* clean up sas work space */
  proc datasets library=work memtype=data kill;
  run;

  /*
  ** write warnings and errors to log
  */
  %scanError(&program);

  /*
  ** write warnings and error report to lst
  */
  %scanLog(&program);

%mend sasbatch;

