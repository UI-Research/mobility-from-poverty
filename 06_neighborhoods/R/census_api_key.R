# Add key to .Renviron
Sys.setenv(CENSUS_KEY = "b76598caee3135caf0d02f35006b220f6f962278")
# Reload .Renviron
#readRenviron("~/.Renviron")
# Check to see that the expected key is output in your R console
Sys.getenv("CENSUS_KEY")
