# Metric template

Brief description

* Years: 06/15/2020 (Data Warehouse record create date)
* Final data name(s): hpsa_metrics_2020-08-31.csv
* Analyst(s): Fred Blavin, Diane Arnos
* Data source(s): HRSA data downloads (https://data.hrsa.gov/data/download)
* Notes: Health Professional Shortage Areas (HPSAs) are specified geographic areas or populations with recognized shortages of health care providers. HPSA scores describe the extent of the shortage in a particular area. For this metric, we are examining HPSA scores for primary care. We only keep currently designated geographic HPSAs and high needs geographic HPSAs ("high needs" referes to patient needs). We keep only geographic designation types because we are interested in shortages of providers for the entire population within a designated geographic area. Designations of geographic areas as HPSAs change over time, so HPSAs that are proposed with withdrawl are not included since they will be removed from the next round of updated data. HPSA score ranges from 0-25. If a county is not in this dataset, they are NOT a designated health professional shortage area (HPSA). Quality indicators for HPSA score are set to once, since scores are constructed by HRSA and there is no missing data.
    * Limitations: Only counties that are designated as HPSA are in the dataset, making the assumption that all other counties have zero values for HPSA score. 
    * Missingness: No missing data
More documentation from HRSA can be found here: https://bhw.hrsa.gov/shortage-designation/hpsa-criteria#scoreautohpsa

Outline the process for creating the data    

1. Import csv file from HRSA website: https://data.hrsa.gov/data/download
3. Only keep relevant variable: designationtype hpsastatus hpsascore hpsaid commonstatecountyfipscode commonstatefipscode
   *hpsascore is the metric variable and ranges from 0-26. If a county is not in this dataset, they are NOT a designated health professional shortage area (HPSA)
4. Using designationtype variable, only keep current designated Geographic HPSAs and high needs geographic HPSA ("high needs" based on patient needs)
   *Assumption: Proposed with Withdrawal HPSAs are NOT included since they will be removed in next round of updates
5. Drop duplicate observations, based on hpsaid, and confirm that all duplicate observations have the same hpsascore value
6. Merge onto full county dataset to obtain missing counties, set HPSA score to zero for counties not in the HPSA dataset.

