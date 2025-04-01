
# clean and transform location data for all eras of garmin data ---------------------

locations_data_from_garmin <- all_activities %>% 
  mutate(date = lubridate::as_date(startTimeGmt)) %>% 
  group_by(date, activityId, activityType, sportType, timeZoneId, startLatitude, startLongitude, locationName, distance) %>% 
  summarise(.groups = "drop") %>% 
  #exclude ineligible data, types, and non-movement data
  filter(!(date==make_date(2020,03,27) & activityId==4703548292), #not a unlikely activity identified previously
         !activityType %in% c("pilates", "yoga", "other"),
         distance != 0
         ) 
  
locations_data_from_garmin %>% count(sportType, activityType) %>% print(n=45)
locations_data_from_garmin %>% count(sportType, activityType, locationName) %>% print(n=55)
locations_data_from_garmin %>% count(locationName) %>% print(n=55)


unknown_locations <- locations_data_from_garmin %>% filter(is.na(locationName)) %>% print(n=21)

## impute values with missing location data ---------------------------------

locations_data_full_garmin_with_imputations <- locations_data_from_garmin %>% 
  # filter(date>=min(unknown_locations$date) & date <=max(unknown_locations$date)+13) %>% #arbitrary date
  arrange(date) %>% 
  
  #impute missing locations from other activities that occurred on the same day
    group_by(date) %>%  
    arrange(date) %>% 
      mutate(across(timeZoneId:locationName, ~ if_else(is.na(.x), first(na.omit(.x)), .x))) %>% 
    ungroup() %>% 
  mutate(
        #impute based on missing location
        locationName = if_else(is.na(locationName) & year(date)==2022 & month(date)==5, "Lilongwe", locationName),
        #impute locations based on the preceding activity (DR 2020 + abuja 2023)
         across(timeZoneId:locationName, ~ if_else(is.na(.x) &
                                                   ((date == "2020-02-21" ) |  (year(date) == 2023 & month(date) == 8)),
                                                   lag(.x), .x)),
        #get second missing 2023 abuja date filled in
        across(timeZoneId:locationName, ~ if_else(is.na(.x) &
                                                    ( (year(date) == 2023 & month(date) == 8)),
                                                  lag(.x), .x)),
    #otherwise impute based on the next value -- if conditional logic is needed--it is not here
    # across(timeZoneId:locationName, ~if_else(is.na(.x), lead(.x), .x))
         ) %>% 
  #simple solution to impute based on next value
  fill(timeZoneId:locationName, .direction = "up") %>% 
  # count(locationName) %>%
print(n=1000)

library(tidygeocoder)

locations_data_garmin_with_imputations <- locations_data_full_garmin_with_imputations  %>%
  group_by(date, activityId, timeZoneId, startLatitude, startLongitude, locationName) %>% 
  summarise(.groups = "drop") %>% 
  rename(Latitude=startLatitude,
         Longitude=startLongitude) %>% 
  #after correcting locations, reverse geocode since city, state, country, are not always provided
  tidygeocoder::reverse_geocode(lat = Latitude, long = Longitude, method = 'osm',    full_results = TRUE) %>% 
  select(date, activityId, timeZoneId, Latitude, Longitude, locationName, city, state, `ISO3166-2-lvl4`, country) %>% 
      mutate(city = case_when(locationName %in% c("Banff", "Alberta") ~ "Banff",
                              locationName == "Blantyre" ~ locationName,
                              locationName %in% c("El Nido", "Palawan") ~ "El Nido",
                              locationName =="Homer" ~ "Homer",
                              # locationName %in% c("Kenai Peninsula County") ~ "Seward",
                              # locationName %in% c("Matanuska-Susitna County") ~ "Palmer",
                              # locationName %in% c("Nome") ~ locationName,
                              # locationName %in% c("Nome") ~ "McCarthy",
                              locationName == "Addis Ababa" ~ locationName,
                              country == "नेपाल"~ locationName,
                              .default = city
                              ),
              state = case_when(
                                country == "नेपाल"~ "Bagmati",
                                .default = state),
             country = case_when(locationName == "Addis Ababa" ~ "Ethiopia",
                                 country == "नेपाल"~ "Nepal",
                                 .default = country)
             ) 
#pre geocode
locations_data_full_garmin_with_imputations %>% count(locationName) %>% print(n=71)
# post geocode
locations_data_garmin_with_imputations %>% count(locationName) %>% print(n=71)


locations_data_garmin_with_imputations %>% count(country, `ISO3166-2-lvl4`, state, locationName, city  ) %>% print(n=80)
# locations_data_garmin_with_imputations %>% count(locationName) %>% print(n=71)

