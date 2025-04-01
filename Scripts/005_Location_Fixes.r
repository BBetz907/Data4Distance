# transform coordinates to protect privacy -------------------

## load hidden constants, randomly generated from environment ----------

set.seed(Sys.getenv("COORD_SEED", unset = 12345))  # Set seed from env variable (fallback for testing)
min_val <- as.numeric(Sys.getenv("range_min"))
max_val <- as.numeric(Sys.getenv("range_max"))
lat <- as.numeric(Sys.getenv("lat"))
long <- as.numeric(Sys.getenv("long"))
conversion <- as.numeric(Sys.getenv("conversion"))
fixed <- as.numeric(Sys.getenv("fixed"))
multiplier <- as.numeric(Sys.getenv("multiplier"))


## transform constants --------------------------
## transform Lat
random_lat <- runif(12, min_val, max_val) / conversion
### radomize + / -
random_lat_indices <- sample(1:length(random_lat), length(random_lat) / 2)
### Make some the selected values negative
random_lat[random_lat_indices] <- random_lat[random_lat_indices] * -1

## transform Long
random_long <- runif(12, min_val, max_val) / conversion
### radomize + / -
  random_long_indices <- sample(1:length(random_long), length(random_long) / 2)
### Make some of the selected values negative
random_long[random_long_indices] <- random_long[random_long_indices] * -1
#### construct datafram
conversions <- data.frame(row_number = 1:12, random_lat = random_lat, random_long = random_long)


## load activity groups selected for coordinate transformation -------------
location_transformations <- read_tsv(file = "Dataout/locations - locations.tsv", show_col_types = ) %>% 
  select(3, 4, 5) %>% 
  # mutate(across(c("Latitude","Longitude"), ~format(., digits = 6))) %>%
  rename(group=`activityId (group)`) %>% glimpse()
  
## create key for how to transform coordinates from random constants  
key <-  location_transformations %>% count(group)  %>% 
    mutate(row_number = row_number()) %>% 
    #join to conversions
    left_join(conversions) %>% glimpse() %>% 
  mutate(random_lat = case_when(row_number >= 10 ~ abs(random_lat+fixed), 
                                row_number %in% c(9) ~ -abs(random_lat+(fixed*multiplier)), 
                                row_number %in% c(4, 5) ~ abs(random_lat+((fixed*4.6)^multiplier)), 
                                .default = random_lat),
          random_long =  case_when(row_number %in% c(9) ~ -multiplier/12, 
                                   row_number %in% c(5) ~ -abs(random_lat+multiplier/5.8), 
                                   .default = random_long),
         ) %>% 
  # select(-n, -row_number) %>% 
  print()
  
### supplement key with coordinate ranges for increasing inclusiveness -------


ranges <- read_tsv(file = "Dataout/locations - location ranges.tsv", show_col_types = ) %>% 
  pivot_wider(names_from = `Measure Names`, values_from = `Measure Values`) %>% 
  janitor::clean_names() %>% 
  rename(group = activity_id_group) %>% glimpse()

#add some lenience
keys <- key %>% inner_join(ranges) %>% 
  mutate(across(starts_with("Min"), ~.-0.00013),
         across(starts_with("Max"), ~.+0.00013),) %>%
  print()



## modify original data with transformations to replace selected coordinates -------
new_geo <- initial_location_activity_data_garmin_runkeeper_strava %>%
  cross_join(keys) %>%  # Create all possible matches
  filter(
    Latitude >= min_latitude & Latitude <= max_latitude &
      Longitude >= min_longitude & Longitude <= max_longitude
  ) %>% 
  select(activityId , Latitude, Longitude, group, row_number, random_lat, random_long)  # Keep only relevant columns

### Left join back to original dataframe to ensure all rows are preserved, including the untransformed locations
location_activity_data_garmin_runkeeper_strava <- initial_location_activity_data_garmin_runkeeper_strava %>% 
  left_join(new_geo, by = c("activityId", "Latitude", "Longitude")) %>% 
  #create transformations
  mutate(New_Latitude  = if_else(row_number != 8, Latitude + random_lat, Latitude + lat),
         New_Longitude = if_else(row_number != 8, Longitude + random_long, Longitude-long),
         new_city = case_when(row_number==5 ~ "Goleta",
                              row_number==9 & New_Latitude < 41.9 ~ "New Buffalo",
                              row_number==9 & New_Latitude >= 41.9 ~ "Three Rivers"),
         new_location = case_when(row_number==5 ~ "Goleta",
                                  row_number==9 & New_Latitude < 41.9 ~ "New Buffalo",
                                  row_number==9 & New_Latitude >= 41.9 ~ "Three Rivers"),
  ) %>%

    # recode transformed data
    mutate(Latitude = if_else(is.na(New_Latitude), Latitude, New_Latitude),
         Longitude = if_else(is.na(New_Longitude), Longitude, New_Longitude),
         locationName = if_else(is.na(new_location), locationName, new_location),
         city = case_when(!is.na(new_city) ~ new_city, 
                          country != "United States" & is.na(city) ~ str_c(locationName, country, sep = ", "),
                          is.na(city) & state == "United States" ~ str_c(locationName, state, sep = ", "),
                          .default = city),
  ) %>% select(-contains("new"),
               -group, -row_number,
               -contains("random")) %>%   glimpse()


# location_activity_data_garmin_runkeeper_strava %>% glimpse()

# location_activity_data_garmin_runkeeper_strava <- initial_location_activity_data_garmin_runkeeper_strava %>%  
#   mutate(across(c("Latitude","Longitude"), ~round(., 7)),
#          ) %>% 
#   left_join(locations, relationship = "many-to-one") %>%  print() %>% 
#   mutate(Latitude = if_else(is.na(New_Latitude), Latitude, New_Latitude),
#          Longitude = if_else(is.na(New_Longitude), Longitude, New_Longitude),
#          locationName = if_else(is.na(new_location), locationName, new_location),
#          city = case_when(!is.na(new_city) ~ new_city, 
#                           country != "United States" & is.na(city) ~ locationName,
#                           is.na(city) & country == "United States" ~ str_c(state, "State", sep = " "),
#                           .default = city),
#          ) %>%   
#   # filter((New_Latitude == Latitude), New_Longitude ==Longitude ) %>%
#   # select(-starts_with(str_to_lower("New_")), -locationName) %>%
#   # filter(city %in% c("Goleta", "New Buffalo")) %>% 
#   print(n=42)

# location_activity_data_garmin_runkeeper_strava %>% count(country, state, city) %>% print(n=100)

# purrr::walk(df_names_output, ~write_csv(x=get(.x), file=str_c("Dataout/", .x, ".csv")))

