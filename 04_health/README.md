# Metric template

Brief description

* Final data name(s): hpsa_data.dta
* Analyst(s): Fred Blavin
* Data source(s): HRSA data downloads (https://data.hrsa.gov/data/download)
* Year(s): 06/15/2020 (Data Warehouse record create date)
* Notes: HPSA score ranges from 0-26. If a county is not in this dataset, they are NOT a designated health professional shortage area (HPSA)
    * Limitations
    * Missingness

Outline the process for creating the data    

1. download raw data here: : https://data.hrsa.gov/data/download
2. Import excel file into Stata
3. Only keep relevant variable: designationtype hpsastatus hpsascore hpsaid commonstatecountyfipscode commonstatefipscode
   *hpsascore is the metric variable and ranges from 0-26. If a county is not in this dataset, they are NOT a designated health professional shortage area (HPSA)
4. Using designationtype variable, only keep current designated Geographic HPSAs and high needs geographic HPSA ("high needs" based on patient needs)
   *Assumption: Proposed with Withdrawal HPSAs are NOT included since they will be removed in next round of updates
5. Drop duplicate observations, based on hpsaid, and confirm that all duplicate observations have the same hpsascore value

