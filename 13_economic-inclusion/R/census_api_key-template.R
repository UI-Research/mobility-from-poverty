# Add key to .Renviron
Sys.setenv(CENSUS_KEY = "")
# Reload .Renviron
readRenviron("~/.Renviron")
# Check to see that the expected key is output in your R console
Sys.getenv("CENSUS_KEY")
