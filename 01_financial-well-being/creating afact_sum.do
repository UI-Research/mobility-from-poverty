* Generating afact_product sum by county
** Copied Kevin's data 

gen afact_product= afact * afact2
bysort countyfip: egen afact_sum=total(afact_product)
