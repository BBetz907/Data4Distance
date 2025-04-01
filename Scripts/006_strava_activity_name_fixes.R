# load strava activity data; remove unnecessary fields; remove/replace privacy information -----------------------------
# the Strava activity output will be used for all analytic projects that use my strava activity data ----

## load patterns to be concealed using str_replacements
pattern <- c("pattern1_concealed","pattern2_concealed", "pattern3_concealed", "pattern4_concealed") %>% 
  map_chr(~ pluck(Sys.getenv(.x)))  # Extracts as a character vector

## replace strings and remove unnecessary fields
activities <- read_csv("Data/Strava/activities.csv") %>%
  # remove unneceessary fields
  select( -`Activity Description`, -`Activity Private Note`, -Filename, #remove unneccessary data
          -where(~ all(is.na(.))), #remove all columns will all null data
          -`Weather Pressure`:-Media,
          -`Relative Effort...38`:-`From Upload`,
          -`Max Heart Rate...31`, -Commute...10, -`Relative Effort...9`, -`Elapsed Time...16`,
          -contains("Bike"), -contains("Weight"),
          ) %>% 
  #recode activity names
  mutate(`Activity Name` = str_trim(str_replace_all(`Activity Name`, pattern[1], "")),
         `Activity Name` = str_trim(str_replace(`Activity Name`, pattern[2], "club ")),
         `Activity Name` = str_trim(str_replace(`Activity Name`, pattern[3], "dog")),
         `Activity Name` = str_trim(str_replace_all(`Activity Name`, pattern[4], "Coast")),
         #remove spaces
         `Activity Name` = str_replace(`Activity Name`, "\\s\\s", "\\s"),
  #recode date time as date
  `Activity Date` = lubridate::as_date(mdy_hms((`Activity Date`)))
         ) %>% 
  # rename fields to match originals
  rename(`Elapsed Time` =`Elapsed Time...6`,
         `Distance (km)` = `Distance...7`,
         `Distance (m)` = `Distance...18`,
         `Grade Adjusted Distance (m)` = `Grade Adjusted Distance`,
         `Max Heart Rate` = `Max Heart Rate...8`) %>% 
  glimpse()

