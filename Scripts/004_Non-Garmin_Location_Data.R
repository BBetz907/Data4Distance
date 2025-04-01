#obtain location data from Strava and googlesheets which contain Runkeeper data that was migrated to Strava before deletion ---------

activities_strava <- read_csv("Data/Strava/activities.csv", col_select = c(2:4)) %>% janitor::clean_names() %>% 
  rename_with(~ str_remove(.x, "^activity_"), starts_with("activity_")) %>%
  mutate(date = lubridate::as_date(mdy_hms(date))) %>%
  arrange(date) %>% 
  glimpse()

pre_garmin_date <- lubridate::ymd(min(locations_data_garmin_with_imputations$date))
activities_pregarmin <- activities_strava %>%   filter(date < pre_garmin_date)
activities_postgarmin <- activities_strava %>%   filter(date >= pre_garmin_date)


activities_strava %>% print(n=200)

# access google sheets -------------------------------------------
library(glamr)
library(googlesheets4)
library(googledrive)

# set_email("bourke.betz@gmail.com")
# googledrive::drive_auth()
googlesheets4::gs4_auth(scopes = "https://www.googleapis.com/auth/spreadsheets.readonly")

sheet_url <- "https://docs.google.com/spreadsheets/d/1_JzfoWlqhxHzk5utUXboWfCRdlpH54vjGYXePwhH3WI/edit?gid=0#gid=0"

sheet <- drive_get("missing locations from garmin")
sheet_url <- sheet$id

locations_pregarmin <- googlesheets4::read_sheet(ss = sheet_url, sheet = "prehistoric locations", 
                          col_types = "Dcccc") 

locations_missing <- googlesheets4::read_sheet(ss = sheet_url, sheet = "missing locations", 
                                              col_types = "Dcccc")
         

# join on date for missing data

## first batch - odd locations ----------------------------------
activities_other_locations <- activities_pregarmin %>% right_join(locations_pregarmin) %>% #keep only other locations, pre-garmin history
  print(n=77) %>% 
  # note: right join since runkeeper activities missing in garmin data. Left unnecessary because of steps below
  tidygeocoder::geocode(city = city, country = country, full_results = TRUE) %>%  #run geocode to get coordinates
  select(date, lat, long) %>% 
  tidygeocoder::reverse_geocode(lat = lat, long = long, method = 'osm',    full_results = TRUE) %>%   #run in reverse to get same format as previous
  select(date, lat, long, city, state, `ISO3166-2-lvl4`, country) %>% 
  rename(Latitude=lat, Longitude=long) %>% 
    arrange(date) %>% 
  select(-city) %>% #drop city, join with original to get best value for city name
  inner_join(locations_pregarmin, join_by("date"),) %>%  
      mutate(country = country.x,
                       locationName = if_else(is.na(location), city, location), 
                       #recode Hope Alaska and Fraser BC
                       state = case_when(date=='2016-05-15' ~ "Alaska", 
                                         city == "Fraser" & country == "Canada" ~ "British Columbia",
                                         .default = state.x),                  
         `ISO3166-2-lvl4` = case_when(date=='2016-05-15' ~ "US-AK",
                                      city == "Fraser" & country == "Canada" ~ "CA-BC",
                                      .default = `ISO3166-2-lvl4`),
         Latitude = case_when(date=='2016-05-15'~ 60.92403538043785, 
                              city == "Fraser" & country == "Canada" ~ 59.718035316950306,
                              .default = Latitude),
         
         Longitude  = case_when(date=='2016-05-15' ~ -149.62063130700915, 
                              city == "Fraser" & country == "Canada" ~ -135.0437597223703,
                              .default = Longitude),
                  ) %>% 
  select(-ends_with(".y"), -ends_with(".x"), -location) %>% 
  print(n=75)

## second batch - pre-garmin missing data from two alaska starting points ----------------------------------
activities_alaska_locations <- activities_pregarmin %>% anti_join(locations_pregarmin) %>% #keep only locations presumed to be anchorage
  mutate(Latitude = case_when(
                              date <  ymd("2018-06-18") ~ 61.208904586987046,  #parkstrip placeholder
                              date >= ymd("2018-06-18") ~ 61.193211422787485,  #prov placeholder
        ),
         Longitude = case_when(
                              date <  ymd("2018-06-18") ~ -149.9227792096598, #parkstrip placeholder
                              date >= ymd("2018-06-18") ~ -149.8163730426424, #prov placeholder
    ),
  ) %>%  
  #after correcting locations, reverse geocode since city, state, country, are not always provided
  tidygeocoder::reverse_geocode(lat = Latitude, long = Longitude, method = 'osm',    full_results = TRUE) %>% 
  select(date, Latitude, Longitude, city, state, `ISO3166-2-lvl4`, country) %>% 
  print(n=150)

## third batch - post garmin missing data ----------------------------------
activities_missing_locations <- activities_postgarmin %>% right_join(locations_missing) %>%  #manual activities where info is missing
  mutate(street = case_when(location == "Transcorp Hilton" ~ "1 Aguiyi Ironsi St",
                             location == "Beacon Hill" ~ "1660 S Columbian Way",
                             location == "Old Soldiers HOme" ~ "140 Rock Creek Church Rd NW")) %>% 
  rename(locationName=location) %>% 
  tidygeocoder::geocode(street = street, city=city, country=country, full_results=TRUE) %>% #run geocode to get coordinates
  select(date, lat, long, locationName) %>% 
  tidygeocoder::reverse_geocode(lat = lat, long = long, method = 'osm',    full_results = TRUE) %>%   #run in reverse to get same format as previous
  select(date, lat, long, city, state, `ISO3166-2-lvl4`, country, locationName) %>% 
  rename(Latitude=lat, Longitude=long) %>% 
  group_by_all() %>% summarise() %>% ungroup() %>% 
  print()

#identify all the above data frames to be concatenated from above 004 and 003
df_names_activity_locations <- ls(pattern = "^activities_.+locations$|locations_data_garmin_with_imputations")

initial_location_activity_data_garmin_runkeeper_strava <- bind_rows(mget(df_names_activity_locations)) %>% 
#add back unique ID elements
# location_activity_data_garmin_runkeeper_strava <- location_activity_data_garmin_runkeeper_strava %>%
  mutate(activityId = if_else(is.na(activityId), 20000000001 + row_number(), activityId),
         locationName = if_else(is.na(locationName), city, locationName))

# nchar(max(location_activity_data_garmin_runkeeper_strava$activityId))
# nchar(20000000001)

# location_activity_data_garmin_runkeeper_strava %>% filter(is.na(country)) %>% count(country, state, city, Latitude, Longitude, date) %>% print(n=67)
