# Data4Distance

Data4Distance leverages data from Strava and Garmin Connect, initially collected using a Garmin smartwatch (2019-) and prior to that the Runkeeper app (2016-2019). The project contains files used to process these data and protect location data. Visualization projects using these data can be found on Tableau Public:

##### [Shoe Journeys](https://public.tableau.com/app/profile/datadventures/viz/Shoejourneys/Shoebiographies)

-   an interactive dashboard featuring maps and charts hosted on Tableau Public


##### [My Running Journey](https://public.tableau.com/app/profile/datadventures/viz/MyRunningJourney/Thebeginningofthejourney)

-   a narrative data exploration hosted on Tableau Public - a *Quarto version is forthcoming*
<br>

Garmin and Strava archives need only to be downloaded and placed in the project Data folder to update the data. Garmin data can take up to 24 hours following your request and can be obtained by selecting /Export Your Data from the [Account Management page](https://www.garmin.com/en-US/account/datamanagement/) on Garmin Connect. Strava activity data can be obtained in a few hours from the [Account Deletion page](https://www.strava.com/athlete/delete_your_account) without actually deleting the account. It can only be downloaded once per week.

The following scripts are run to accomplish the necessary cleaning, transformations, and concealments:

<p style="margin-left: 20px;">**000_Load_Packages.R** loads all packages necessary</p>

<p style="margin-left: 20px;">**001_Garmin_Run_Gear_ActivityIDs.R** cleans running shoe names and identifies running activities from my early Garmin data, particularly for activities between April 2019 and May 2020 when I tracked my shoes using Garmin Connect.</p>

<p style="margin-left: 20px;">**002_Garmin_Activities_All.R** loads a later era of Garmin activity data and appends it to the activity data (no shoe data) from above.</p>

<p style="margin-left: 20px;">**003_Garmin_Locations.R** munges and cleans location data from both eras of Garmin activities</p>

<p style="margin-left: 20px;">**004_Non-Garmin_Location_Data.R** obtains activity dates from Strava, where my 2016-2019 Runkeeper Data was migrated before deletion, and draws from other documentation recorded on Google Sheets to supplement missing data</p>

<p style="margin-left: 20px;">**005_Location_Fixes.R** loads hidden constants from the R environment should users wish to transform locations in order to protect privacy</p>

<p style="margin-left: 20px;">**006_strava_activity_name_fixes.** removes selected personal information from activity names in the Strava activity and fields that might contain additional non-public information, should users wish to do so.</p>

<p style="margin-left: 20px;">**007_output_activity_Data.R** exports gear, location, and activity data. It also cleans the environment.</p>

------------------------------------------------------------------------
