# load additional data from a second era of Garmin -----------------------------
json_file_activities2 <- "Data/Garmin/DI_CONNECT/DI-Connect-Fitness/bourke.betz@gmail.com_0_summarizedActivities.json"

list.files(path='Data/Garmin/DI_CONNECT/DI-Connect-Fitness/', pattern = "summarizedActivities.json$")

df_list_activities2 <- fromJSON(json_file_activities2) %>% 
  lapply(., function(x) as.data.frame(x)) # Convert each list column into a DataFrame



# munge activity data 2 with with earlier era ------------------------
activities2 <- df_list_activities2$summarizedActivitiesExport %>% 
  select(activityId, name, contains("type"), contains("Time"), duration, distance, startLatitude, startLongitude, locationName) %>% 
  mutate(across(contains("Time") & !starts_with("time"), ~lubridate::as_datetime(./1000)), #recode datetime fields
         distance_km = distance/100000, #recalculate distance
         distance_miles = distance_km*0.621371) 

# compare_df_cols(activities2, activities_garmin)

all_activities <- bind_rows(activities2, activities_garmin)
min(activities2$startTimeGmt)
max((activities2$startTimeGmt))