
# Data4Distance

<!-- badges: start -->
<!-- badges: end -->

Data4Distance leverages data from Strava and Garmin Connect, initially collected using a Garmin smartwatch (2019-) and prior to that the Runkeeper app (2016-2019). The R project contains files used to process these data and protect location data. Visualization projects using these data can be found on Tableau Public:
\* [Shoe Journeys](https://public.tableau.com/app/profile/datadventures/viz/Shoejourneys/Shoebiographies), an interactive dashboard featuring maps and charts hosted on Tableau Public
\* [My Running Journey](https://public.tableau.com/app/profile/datadventures/viz/MyRunningJourney/Thebeginningofthejourney), a narrative data exploration hosted on Tableau Public. *A Quarto HTML version is forthcoming.*


Garmin and Strava archives need only to be downloaded placed in the project data folder to run this with updated data.

The following scripts are run to accomplish the necessary cleaning, transformations, and concealments:

<li>**000_Load_Packages.R**    
  <ol>
      <li> loads all packages necessary.</li>
  </ol>
**001_Garmin_Run_Gear_ActivityIDs.R** cleans running shoe names and identifies running activities from my early Garmin data, particularly for activities between April 2019 and May 2020 when I tracked my shoes using Garmin Connect.
**002_Garmin_Activities_All.R** loads a later era of Garmin activity data and appends it to the activity data (no shoe data) from above. 
**003_Garmin_Locations.R** munges and cleans location data from both eras of Garmin activities
**004_Non-Garmin_Location_Data.R** obtains activity dates from Strava, where my 2016-2019 Runkeeper Data was migrated before deletion, and draws from other documentation recorded on Google Sheets to supplement missing data
**005_Location_Fixes.R** loads hidden constants from the R environment should users wish to transform locations in order to protect privacy
**006_strava_activity_name_fixes.** removes selected personal information from activity names in the Strava activity and fields that might contain additional non-public information, should users wish to do so.
<li>007_output_activity_Data.R
  <ol>
    <li>exports gear, location, and activity data. It also cleans the environment.</li>
  </ol>
---

Note: None of the data is actually replaced. These functions were simply built to allow for protection of personal data should someone else wish to apply the project code. This is in effort to match Strava and Garmin's protections which allow hiding start points and potentially restricting to followers only.
