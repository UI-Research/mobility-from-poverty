# Neonatal Health

This metric captures the share of low birthweight infants out of all births.

* Final data name(s): neonatal_health.csv
* Analyst(s): Emily M. Johnston
* Data source(s): Natality on CDC WONDER Online Database, for years 2016-2018 available September 2019.
* Year(s): 2018
* Notes:
    * Low birthweight is defined as less than 2,500 grams
    * County refers to county of residence
    * Counties with populations under 100,000 persons are grouped into pooled "Unidentified Counties" in the CDC WONDER data
    * lbw_flag indicates "Unidentified Counties" and data for these counties reflect the pooled share low birthweight for all counties in the state with populations under 100,000 and are not county-specific

Process for creating the data    
   1. Download data from CDC WONDER 
      *County-Level counts of:
         *Births
         *Births with nonmissing birthweight data
         *Low birthweight births
      *See CDC_WONDER_query_neonatal_health.doc for detailed instructions
   2. Merge CDC WONDER data with crosswalk to create county level file
   3. Assign counties missing from CDC WONDER data the values for their state's "Unidentified Counties" in CDC WONDER data   
   4. Construct share low birthweight
      *Divide the number of low birthweight births in a county by the number of births with nonmissing birthweight data
   5. Calculate 95 percent confidence intervals
      *See CDC_WONDER_standaerd_errors.doc for detailed instructions


