# clean data to associate shoes with activities, when Garmin was primarily used for activity tracking and records -----------

## load gear/activity data ----------------------------------------------------------

# Path to your JSON file
json_file_gear <- "Data/Garmin/DI_CONNECT/DI-Connect-Fitness/bourke.betz@gmail.com_gear.json"


# Load JSON file into a list
json_gear <- fromJSON(json_file_gear)

# Convert each list column into a DataFrame
df_list <- lapply(json_gear, function(x) as.data.frame(x))

# Assign each DataFrame a name dynamically
for (name in names(df_list)) {
  assign(name, df_list[[name]], envir = .GlobalEnv)
  print(paste("Extracted:", name))
}


## munge gear/activity data -------------------------------------------------
# gearActivityTypeDTOS 
# gearDTOS %>% semi_join(gearActivityTypeDTOS) # gearActivityTypeDTOS only contains default gear

# gearDTOS contains all gear
# filter to include only running shoes
running_gear_garmin <- gearDTOS %>% 
  filter(str_detect(customMakeModel,"^Brooks|^Hoka|^Salomon|^Nike|^zamb")) %>% 
  select(-uuid, -userProfilePk, -notified, -updateDate) %>% 
  mutate(customMakeModel = recode(customMakeModel, "zamberlain" = "Zamberlan Yeren GTX"),
         customMakeModel = str_replace(customMakeModel, "Hoka One One|Hoka", "HOKA ONE ONE"),
         displayName=case_when(is.na(displayName) ~ customMakeModel, 
                               customMakeModel == "Brooks Cascadia" ~ str_c("Brooks", displayName, sep = " "),
                               str_detect(customMakeModel, "Arahi|Clifton") ~ customMakeModel,
                               .default = displayName)) %>% 
  print()

running_gear_garmin %>% count(customMakeModel, displayName)


# investigate gearActivityDTOs
class(gearActivityDTOs)
glimpse(gearActivityDTOs)
gearActivityDTOs$`18339749`

# gearActivityDTOs contains a list of activities (by activityID) for each piece of gear
gearActivityDTOs

# Convert each list column from gearActivityDTOs into a DataFrame
df_list_DTOs <- lapply(json_gear$gearActivityDTOs, function(x) as.data.frame(x))
# Union these into one large table the
dfDTOs <- bind_rows(df_list_DTOs) %>% glimpse()


# Filter dfDTOs from gearActivityDTOs to include only running_gear
running_activityid_gear_garmin <- dfDTOs %>% 
  semi_join(running_gear_garmin, join_by(gearPk)) %>% 
  glimpse()

# Filter dfDTOs from gearActivityDTOs to include only running_gear + expand
running_activityid_gear_full_garmin <- dfDTOs %>% 
  inner_join(running_gear_garmin, join_by(gearPk)) %>% 
  glimpse()

running_activityid_gear_full_garmin %>% summary(dateBegin)


# use the running gear data and running activity IDs, to create a data frame containing: shoe, activity date, activity ID ---------------
# This will be used in Tableau to supplement STRAVA shoe data for activities between 2019 April and 2020 May

## load activity data from first era of garmin data----------------------------------------------------------

# Path to  JSON file with pre-2021 data. Strava has gear information
json_file_activities <- "Data/Garmin/DI_CONNECT/DI-Connect-Fitness/bourke.betz@gmail.com_1001_summarizedActivities.json"

# Load JSON file into a list
df_list_activities_garmin <- fromJSON(json_file_activities) %>% 
  lapply(., function(x) as.data.frame(x)) # Convert each list column into a DataFrame


## munge activity data ------------------------
activities_garmin <- df_list_activities_garmin$summarizedActivitiesExport %>% 
  select(activityId, name, contains("type"), contains("Time"), duration, distance, startLatitude, startLongitude, locationName) %>% 
  mutate(across(contains("Time") & !starts_with("time"), ~lubridate::as_datetime(./1000)), #recode datetime fields
         distance_km = distance/100000, #recalculate distance
         distance_miles = distance_km*0.621371) 

activities_garmin %>% arrange((beginTimestamp)) %>% glimpse()
activities_garmin %>% count(sportType, activityType)

# Garmin April 2019-May 2020, 
# Define the cutoff date
strava_supremacy_cutoff_date <- as.POSIXct("2020-06-01 00:00:00")

running_activities_garmin <- activities_garmin %>% semi_join(running_activityid_gear_garmin) %>% 
  arrange(startTimeGmt) %>% 
  filter(startTimeGmt<strava_supremacy_cutoff_date) %>%
  glimpse()

running_activities_garmin %>% count(sportType, activityType) %>% glimpse()
running_activities_garmin %>% summary(distance_miles)

running_activities_garmin %>% count(locationName)

#evaluate
shoes_garmin <- running_activities_garmin %>% 
  full_join(running_activityid_gear_garmin) %>% 
  full_join(running_gear_garmin) %>%  
  mutate(date = lubridate::as_date(startTimeGmt)) %>% 
  # filter(date==make_date(2021,08,23)) %>% 
  print()

shoes_garmin %>% group_by(displayName) %>% summarise(first_wear=min(startTimeGmt),
                                                     last_wear=max(startTimeGmt), .groups = "drop")

running_gear_data_from_garmin <- shoes_garmin %>% group_by(date, displayName, distance_miles, name, activityId) %>% 
  summarise(.groups = "drop") %>% 
  filter(!(date==make_date(2020,03,27) & displayName=="Brooks Levitate")) %>% 
  group_by(displayName, date, activityId) %>% summarise(.groups = "drop") %>% 
  print(n=145)
running_gear_data_from_garmin %>% glimpse()

running_gear_data_from_garmin %>% count(date) %>% filter(n>1)
running_gear_data_from_garmin %>% count(displayName, date) %>% filter(n>1) %>% select(-n)




# code below is accomplished in Tableau but could be accomplished here --------------------

#get(transforms the text string to a reference to the actual df)


# assign shoes to activities from before i registered with strava--merge with non-strava data?
# Runkeeper June 2016 - March 20219, 
# Strava June 2020 onwards

# see Tableau ----- numbers check out


# replace (
#   //2nd pair of Clifton 9 based on known purchase date
#   if NOT ISNULL([Display Name]) THEN [Display Name]
#   //ELSEIF CONTAINS([Activity Gear], "La Sport") THEN [Activity Gear]
#   ELSEIF  CONTAINS([Activity Gear], "HOKA Clifton 9") AND [Activity Date]>MAKEDATE(2024,06,28) THEN  [Activity Gear (full names)] + ".1"
#   
#   //1st pair of Clifton 1 based on hypothesized purchase date - ran in them on June 2, 2017; August 5, 2017, and Sept 9, 2017 - could have been as early as Oct 1
#   ELSEIF [Activity Gear (full names)] = "Brooks Adrenaline GTS" AND ([Activity Date]>= MAKEDATE(2016, 11, 24))  and [Activity Date] < MAKEDATE(2018,04,01) THEN "HOKA Clifton 1"
#   
#   //Brooks Levitate --> changeover use Garmin data instead
#   ELSEIF [Activity Gear (full names)] = "Brooks Adrenaline GTS" AND [Activity Date]>=MAKEDATE(2019,04,15) and [Activity Date]<MAKEDATE(2020,06,01) THEN "Brooks Levitate"
#   
#   //defaults to Stava data for other info
#   ELSEIF CONTAINS([Activity Gear], "HOKA") or CONTAINS([Activity Gear (full names)], "Brooks") or CONTAINS([Activity Gear (full names)], "Zamberlan") or CONTAINS([Activity Gear (full names)], "SpeedSpikes") THEN
#   [Activity Gear (full names)] 
#   
#   ///default to Brooks Levitate where Strave data are missing before 
#   ELSEIF ISNULL([Activity Gear (full names)]) and [Activity Date]>=MAKEDATE(2020,04,15) and [Activity Date]<MAKEDATE(2020,06,01) THEN "Brooks Levitate"
#   
#   ELSEIF [Activity ID] = 5238670023 THEN "Brooks Adrenaline GTS"
#   ELSEIF [Activity ID] = 5835475618 THEN "HOKA ONE ONE Arahi3"
#   ELSEIF [Activity ID] = 5839518285 THEN "HOKA ONE ONE Arahi3"
#   
#   ELSE [Activity Gear (full names)]
#   //Hoka Rincon arrived March 27, 2020
#   
#   //Hoka Clfiton 6 arrived June 6, 2020
#   ///ELSEIF ISNULL([Activity Gear]) and YEAR([Activity Date])<2020 THEN "HOKA Clifton 6"
#   END,
#   "HOKA ONE ONE", "HOKA")

#git repository