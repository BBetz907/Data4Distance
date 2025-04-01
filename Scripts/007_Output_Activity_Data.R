

#clean environment --------------------
dfs <- ls(pattern = "^locations|^df|^activities(?!\\_strava)|json|^all|locations$|location_data|^initial")
dfs
rm(list=dfs, envir = .GlobalEnv)

# use PURRR to output running_activities, running_gear, running_activityid_gear ------------------------
df_names_output <- ls(pattern = "running_gear_data_from_garmin|^location_activity_data_garmin_runkeeper_strava|^activities$")



purrr::walk(df_names_output, ~write_csv(x=get(.x), file=str_c("Dataout/", .x, ".csv")))




qc()

