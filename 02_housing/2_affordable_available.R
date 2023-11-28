###################################################################

# ACS Code: Housing metric, non-subgroup
# Amy Rogin (2023-2024) 
# Using IPUMS extract for ACS 2022
# Based on processes developed by Paul Johnson and Kevin Werner in SAS
# and code by Tina Chelidze in R for 2022-2023
# Process:
# (1) Housekeeping
# (2) Import microdata (PUMA Place combination already done)
# (3) Create a Vacant unit dataframe (vacant units will not be accounted for when we isolate households in Steps 4 & 5)
#     Note that to get vacant unit data, need to pull a separate extract from IPUMS; see instructions below.
#       (3a) Calculate the monthly payment for the vacant units for a given first-time homebuyer:
#       (3b) Add PMI, taxes, and insurance estimates, to get total monthly cost of vacant units for ownership
#               This "total_monthly_cost" variable will be used to calculate affordability in Step 6
#       (3c) Now create accurate gross rent variable for vacant units for rent: 
#       (3d) For all microdata where PERNUM=1 and OWNERSHP=2, generate avg ratio of monthly cost 
#             vs advertised price of renting. e.g. ratio = RENTGRS/RENT (calculate per place).
#       (3e) In the vacant file, update RENTGRS to be more representative of what actual cost would be (RENTGRS = RENT*ratio). 
#               This "RENTGRS" variable will be used to calculate affordability in Step 6
# (4) Import HUD county Income Levels for each FMR and population for FMR 
#           (population will be used for weighting)
#       (4a) Merge the 2 files
#       (4b) Bring in county_place crosswalk
#       (4c) Merge FMR file with crosswalk on county
#       (4d) Create place_level_income_limits (weight by FMR population in collapse)
# (5) Generate households_2021: 30%, 50% and 80% AMI (indicator of HH affordable at each of these levels)
# (6) Merge Vacant with place_level_income_limits
#       (6a) create same 30%, 50%, and 80% AMI affordability indicators
# (7) Create the housing metric
#       (7a) Summarize households_2021 and vacant both by place
#       (7b) Merge them by place
#       (7c) Calculate share_affordable_30/50/80AMI
# (8) Create Data Quality marker
# (9) Clean and export

###################################################################