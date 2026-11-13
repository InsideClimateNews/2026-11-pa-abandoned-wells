# set working directory to the folder containing this script
setwd(dirname(rstudioapi::getActiveDocumentContext()$path))

# load required packages
library(tidyverse)
library(esri2sf)
library(sf)
library(janitor)
library(htmltools)
library(rvest)
library(httr)
library(jsonlite)
library(fs)

# don't use scientific notation
options(scipen = 999)

##################################################
# Pennsylvania Department of Environmental Protection oil and gas wells inventory
# CSV downloaded from https://greenport.pa.gov/ReportExtracts/OG/OilGasWellInventoryReport
##################################################

current_csv <- read_csv("data/OilGasWellInventory.csv") %>%
  clean_names()

glimpse(current_csv)
# Rows: 280,000
# Columns: 31
# $ ogo                 <chr> "OGO-69667", "OGO-68885", "OGO-45065", "OGO-63400", "OGO-63400", "OGO-63400", "OGO-6340…
# $ operator            <chr> "(WELTER) SMITH TAMARA M", "1030 MCCAIN PARTNERSHIP", "10TH STREET UNITED METH CH", "11…
# $ client_status       <chr> "Active, Indiv", "Active, Non-Govt", "Active, Non-Govt", "Active, Non-Govt", "Active, N…
# $ api                 <chr> "019-22964", "049-00300", "049-23865", "105-00008", "105-00253", "105-00254", "105-0025…
# $ pf_type             <chr> "OGL", "OGL", "OGL", "OGL", "OGL", "OGL", "OGL", "OGL", "OGL", "OGL", "OGL", "OGL", "OG…
# $ other_type          <chr> "OGW", "OGW", "OGW", "OGW", "OGW", "OGW", "OGW", "OGW", "OGW", "OGW", "OGW", "OGW", "OG…
# $ farm                <chr> "WELTER 1", "1030 WEST 26TH ST 1", "10TH ST METHT CH 1", "DUTTER 30", "GREEN 1A", "GREE…
# $ spud_date           <chr> "1/01/1800", "1/01/1800", "1/01/1800", "1/01/1800", "1/01/1800", "1/01/1800", "1/01/180…
# $ well_status         <chr> "Active", "Active", "Active", "Active", "Active", "Active", "Plugged OG Well", "Plugged…
# $ well_type           <chr> "UNDETERMINED", "GAS", "UNDETERMINED", "OIL", "OIL", "OIL", "OIL", "OIL", "OIL", "OIL",…
# $ iija_ind            <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA,…
# $ unconventional      <chr> "No", "No", "No", "No", "No", "No", "No", "No", "No", "No", "No", "No", "No", "No", "No…
# $ conservation        <chr> "No", "No", "No", "No", "No", "No", "No", "No", "No", "No", "No", "No", "No", "No", "No…
# $ configuration       <chr> "Undetermined", "Vertical Well", "Vertical Well", "Vertical Well", "Vertical Well", "Ve…
# $ latitude            <chr> "40° 54' 54.9''", "42° 6' 15.118''", "42° 7' 47.643''", "41° 57' 6.1164''", "41° 57' 10…
# $ longitude           <chr> "-79° 45' 42.732''", "-80° 5' 44.645''", "-80° 4' 15.369''", "-78° 3' 50.508''", "-78° …
# $ latitude_decimal    <dbl> 40.91525, 42.10420, 42.12990, 41.95170, 41.95292, 41.95261, 41.95336, 41.95233, 41.9525…
# $ longitude_decimal   <dbl> -79.76187, -80.09574, -80.07094, -78.06403, -78.05592, -78.05731, -78.05822, -78.05735,…
# $ region              <chr> "EP DOGO NWDO Dstr Off", "EP DOGO NWDO Dstr Off", "EP DOGO NWDO Dstr Off", "EP DOGO NCD…
# $ county              <chr> "Butler", "Erie", "Erie", "Potter", "Potter", "Potter", "Potter", "Potter", "Potter", "…
# $ municipality        <chr> "Donegal Twp", "Erie City", "Erie City", "Oswayo Twp", "Oswayo Twp", "Oswayo Twp", "Osw…
# $ address1            <chr> "418 BONNIEBROOK RD", "1115 W 12TH ST", "538 E 10TH ST", "1639 ELEVEN MILE RD", "1639 E…
# $ address2            <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA,…
# $ city                <chr> "BUTLER", "ERIE", "ERIE", "SHINGLEHOUSE", "SHINGLEHOUSE", "SHINGLEHOUSE", "SHINGLEHOUSE…
# $ state               <chr> "PA", "PA", "PA", "PA", "PA", "PA", "PA", "PA", "PA", "PA", "PA", "PA", "PA", "PA", "PA…
# $ zip                 <chr> "16002-0322", "16501-1516", "16503-1314", "16748-8420", "16748-8420", "16748-8420", "16…
# $ well_pad            <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA,…
# $ well_pad_id         <dbl> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA,…
# $ site_id             <dbl> 874321, 664163, 39561, 171775, 172017, 172018, 172019, 172020, 172021, 172022, 172025, …
# $ primary_facility_id <dbl> 877569, 674562, 41313, 173726, 173968, 173969, 173970, 173971, 173972, 173973, 173976, …
# $ client_id           <dbl> 387877, 331025, 48244, 225362, 225362, 225362, 225362, 225362, 225362, 225362, 225362, …

# how many wells in the data have no coordinates?
no_coordinates <- current_csv %>%
  filter(is.na(latitude_decimal))
nrow(no_coordinates)
# [1] 55246

# are any of these duplicates of other wells?
current_csv %>%
  filter(api %in% no_coordinates$api) %>%
  group_by(api) %>%
  count() %>%
  arrange(-n)
# A tibble: 55,246 × 2
# Groups:   api [55,246]
# api           n
# <chr>     <int>
# 1 003-00402     1
# 2 003-00426     1
# 3 003-00479     1
# 4 003-20054     1
# 5 003-20055     1
# 6 003-20076     1
# 7 003-20089     1
# 8 003-20765     1
# 9 003-20812     1
# 10 003-20813     1
# # ℹ 55,236 more rows
# # ℹ Use `print(n = ...)` to see more rows
# no duplicates for these wells, only one row per api

# what is the status of these wells according to PA DEP categories?
current_csv %>%
  filter(api %in% no_coordinates$api) %>%
  group_by(well_status) %>%
  count() %>%
  arrange(-n)
# # A tibble: 11 × 2
# # Groups:   well_status [11]
# well_status                         n
# <chr>                           <int>
# 1 Operator Reported Not Drilled   16877
# 2 Plugged OG Well                 16831
# 3 Proposed But Never Materialized  8599
# 4 Active                           6884
# 5 DEP Abandoned List               5635
# 6 Abandoned                         329
# 7 Duplicate                          69
# 8 Plugged Unverified                  8
# 9 DEP Plugged                         7
# 10 Cannot Be Located                   5
# 11 DEP Orphan List                     2

# what is the status of these wells according to our filtering criteria and recategorization, 
# applied to the mapped wells below?
current_csv %>%
  filter(api %in% no_coordinates$api
         & well_status != "Duplicate" 
         & well_status != "Operator Reported Not Drilled" 
         & well_status != "Proposed But Never Materialized") %>%  
  mutate(well_status = case_when(well_status == "Active" ~ "Active/Other",
                                 well_status == "Regulatory Inactive Status" ~ "Active/Other",
                                 well_status == "Cannot Be Located" ~ "Abandoned/Orphaned",
                                 well_status == "Uncharted Mined Through" ~ "Abandoned/Orphaned",
                                 grepl("Plugged",well_status) ~ "Plugged",
                                 TRUE ~ "Abandoned/Orphaned")) %>%
  group_by(well_status) %>%
  count() %>%
  arrange(-n)
# # A tibble: 3 × 2
# # Groups:   well_status [3]
# well_status            n
# <chr>              <int>
# 1 Plugged            16846
# 2 Active/Other        6884
# 3 Abandoned/Orphaned  5971

16486+6884+5971
# [1] 29341
# More than 29,000 wells are missing from our map because they have no coordinates in the DEP data

# process data for interactive map
current_csv_edit <- current_csv %>%
  filter(!is.na(latitude_decimal)) %>%
  select(api, well_name = farm, dep_status = well_status, longitude_decimal, latitude_decimal, county, municipality) %>%
  filter(dep_status != "Duplicate" 
         & dep_status != "Operator Reported Not Drilled" 
         & dep_status != "Proposed But Never Materialized") %>%
  mutate(municipality = str_remove(municipality,"\\s+\\S+$"), # removes Twp, Boro etc
         origin_layer = "Current",
         well_status = case_when(dep_status == "Active" ~ "Active/Other",
                                 dep_status == "Regulatory Inactive Status" ~ "Active/Other",
                                 dep_status == "Cannot Be Located" ~ "Abandoned/Orphaned",
                                 dep_status == "Uncharted Mined Through" ~ "Abandoned/Orphaned",
                                 grepl("Plugged",dep_status) ~ "Plugged",
                                 TRUE ~ "Abandoned/Orphaned")) %>%
  group_by(api) %>% # this and following two lines remove any duplicates with the same API
  slice(1) %>%
  ungroup() %>%
  st_as_sf(coords = c("longitude_decimal","latitude_decimal"), crs = st_crs(4326)) %>%
  rename(geoms = geometry) # renaming for consistency with geometry in the historical and farmline map layers, processed below

# review status of wells in the processed data
current_csv_edit %>%
  st_drop_geometry() %>%
  group_by(well_status) %>%
  count()
# # A tibble: 3 × 2
# # Groups:   well_status [3]
# well_status             n
# <chr>               <int>
# 1 Abandoned/Orphaned  28070
# 2 Active/Other       105060
# 3 Plugged             56533

glimpse(current_csv_edit)
# ows: 189,663
# Columns: 8
# $ api          <chr> "0-00002", "0-00003", "0-00004", "0-00005", "003-00020", "003-00067", "003-00069", "003-00070"…
# $ well_name    <chr> "ZEIN 1H", "DOMAN 1H", "DOMAN 2H", "J DUNN 1", "JOHN LAZICH 1", "CARNEGIE NATL GAS CO 114", "S…
# $ dep_status   <chr> "Active", "Active", "Active", "Abandoned", "Plugged OG Well", "Plugged OG Well", "Plugged OG W…
# $ county       <chr> "Out Of State", "Out Of State", "Out Of State", "Out Of State", "Allegheny", "Allegheny", "All…
# $ municipality <chr> "Out of State Municipality", "Out of State Municipality", "Out of State Municipality", "Out of…
# $ origin_layer <chr> "Current", "Current", "Current", "Current", "Current", "Current", "Current", "Current", "Curre…
# $ well_status  <chr> "Active/Other", "Active/Other", "Active/Other", "Abandoned/Orphaned", "Plugged", "Plugged", "P…
# $ geoms        <POINT [°]> POINT (-80.58177 39.89665), POINT (-80.53397 39.89516), POINT (-80.53399 39.89513), POIN…

##################################################
# Digitized historical wells from Pennsylvania Mine Map Atlas 
# see https://www.minemaps.psu.edu/aboutnew.htm
##################################################

historical <- esri2sf("https://gis.dep.pa.gov/depgisprd/rest/services/OilGas/OilGasAllStrayGasEGSP/MapServer/6", crs = NULL)

historical <- historical %>%
  clean_names() %>%
  unique()  %>%
  st_transform(4326)

glimpse(historical)
# Rows: 30,527
# Columns: 12
# $ objectid     <int> 204, 205, 206, 207, 208, 209, 210, 211, 212, 213, 214, 215, 216, 217, 218, 219, 220, 221, 222,…
# $ id           <int> 204, 205, 206, 207, 208, 209, 210, 211, 212, 213, 214, 215, 216, 217, 218, 219, 220, 221, 222,…
# $ map_id       <chr> "WPA205", "WPA206", "WPA207", "WPA208", "WPA209", "WPA210", "WPA211", "WPA212", "WPA213", "WPA…
# $ type         <chr> "Gas Well", "Gas Well", "Gas Well", "Gas Well", "Gas Well", "Dry Hole", "Dry Hole", "Dry Hole"…
# $ longitude    <dbl> -80.20592, -80.24788, -80.24381, -80.24121, -80.23822, -80.23533, -80.24557, -80.24636, -80.22…
# $ latitude     <dbl> 40.14238, 40.13845, 40.13977, 40.14321, 40.14174, 40.14547, 40.15942, 40.15878, 40.13200, 40.1…
# $ mapname      <chr> "WPA Amity 4 Pitt.TIF", "WPA Amity 4 Pitt.TIF", "WPA Amity 4 Pitt.TIF", "WPA Amity 4 Pitt.TIF"…
# $ county_name  <chr> "Washington", "Washington", "Washington", "Washington", "Washington", "Washington", "Washingto…
# $ municipality <chr> "AMWELL, TWP", "NORTH FRANKLIN, TWP", "NORTH FRANKLIN, TWP", "NORTH FRANKLIN, TWP", "NORTH FRA…
# $ comment      <chr> " ", " ", " ", " ", " ", " ", " ", " ", " ", " ", " ", " ", " ", " ", " ", " ", " ", " ", " ",…
# $ pasda_link   <chr> "ftp://data1.commons.psu.edu/pub/minemaps/Map_Repository/Other_Collections/WPA_Maps/", "ftp://…
# $ geoms        <POINT [°]> POINT (-80.20592 40.14239), POINT (-80.24788 40.13846), POINT (-80.24381 40.13978), POIN…

# process data for interactive map
historical_edit <- historical %>%
  mutate(well_status = "Historical",
         origin_layer = "Historical") %>%
  select(well_status, county = county_name, municipality, origin_layer) %>%
  unique()

##################################################
# Digitized historical wells from digitized farmline maps (hand-drawn oil and gas well location maps) 
# see https://www.pa.gov/agencies/dep/programs-and-services/oil-and-gas/legacy-wells/farmline-maps
##################################################

farmline <- esri2sf("https://gis.dep.pa.gov/depgisprd/rest/services/OilGas/OilGasAllStrayGasEGSP/MapServer/7", crs = NULL)

farmline <- farmline %>%
  clean_names() %>%
  unique() %>%
  st_transform(4326)

glimpse(farmline)
# Rows: 6,076
# Columns: 12
# $ objectid       <int> 679, 680, 681, 682, 683, 684, 685, 686, 687, 688, 689, 690, 691, 692, 693, 694, 695, 696, 69…
# $ farml_id       <chr> "FM-4383", "FM-4384", "FM-4385", "FM-4386", "FM-4387", "FM-4388", "FM-4389", "FM-4390", "FM-…
# $ well_type      <chr> "Oil Well", "Oil Well", "Gas Well", "Gas Well", "Gas Well", "Abandoned Oil", "Oil Well", "Oi…
# $ county_nam     <chr> "WASHINGTON", "WASHINGTON", "WASHINGTON", "WASHINGTON", "WASHINGTON", "WASHINGTON", "WASHING…
# $ municipal      <chr> "EAST FINLEY", "EAST FINLEY", "EAST FINLEY", "EAST FINLEY", "EAST FINLEY", "EAST FINLEY", "E…
# $ lat_dd         <dbl> 40.06691, 40.06564, 40.06640, 40.06729, 40.06331, 40.06277, 40.06396, 40.06490, 40.06737, 40…
# $ long_dd        <dbl> -80.37198, -80.37308, -80.36912, -80.36624, -80.37286, -80.37359, -80.36876, -80.36622, -80.…
# $ farml_map      <chr> "Claysville", "Claysville", "Claysville", "Claysville", "Claysville", "Claysville", "Claysvi…
# $ activ_mine     <chr> "Enlow Fork", "Enlow Fork", "Enlow Fork", "Enlow Fork", "Enlow Fork", "Enlow Fork", "Enlow F…
# $ mine_out_areas <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, …
# $ comments       <chr> NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, NA, …
# $ geoms          <POINT [°]> POINT (-80.37197 40.06691), POINT (-80.37308 40.06564), POINT (-80.36912 40.0664), POI…

# process data for interactive map
farmline_edit <- farmline %>%
  mutate(well_status = "Historical",
         origin_layer = "Farmline") %>%
  select(well_status, county = county_nam, municipality = municipal, origin_layer) %>%
  unique()

glimpse(farmline_edit)
# Rows: 6,074
# Columns: 5
# $ well_status  <chr> "Historical", "Historical", "Historical", "Historical", "Historical", "Historical", "Historica…
# $ county       <chr> "WASHINGTON", "WASHINGTON", "WASHINGTON", "WASHINGTON", "WASHINGTON", "WASHINGTON", "WASHINGTO…
# $ municipality <chr> "EAST FINLEY", "EAST FINLEY", "EAST FINLEY", "EAST FINLEY", "EAST FINLEY", "EAST FINLEY", "EAS…
# $ origin_layer <chr> "Farmline", "Farmline", "Farmline", "Farmline", "Farmline", "Farmline", "Farmline", "Farmline"…
# $ geoms        <POINT [°]> POINT (-80.37197 40.06691), POINT (-80.37308 40.06564), POINT (-80.36912 40.0664), POINT…

##################################################
# combine the three sources into a single layer, further processing/cleaning
##################################################

# combine into a single layer
pa_wells <- bind_rows(current_csv_edit,historical_edit,farmline_edit) %>%
  slice_sample(prop = 1) # this randomizes row order, for display on map, so wells from historical maps don't all render on top

glimpse(pa_wells)
# Rows: 226,257
# Columns: 8
# $ api          <chr> "059-01468", "005-01767", "005-30128", "125-26963", NA, NA, "083-05601", "031-00282", "063-302…
# $ well_name    <chr> "J C MCNAY ETUX 603873", "E.C. BEST 529-4", "J CLAYPOOL 1-9.27", "JOHN W CLUTTER 1", NA, NA, "…
# $ dep_status   <chr> "Plugged OG Well", "Active", "Active", "DEP Abandoned List", NA, NA, "Plugged OG Well", "Activ…
# $ county       <chr> "Greene", "Armstrong", "Armstrong", "Washington", "Greene", "WASHINGTON", "McKean", "Clarion",…
# $ municipality <chr> "Center", "Boggs", "North Buffalo", "East Finley", "GILMORE, TWP", "BUFFALO", "Otto", "Porter"…
# $ origin_layer <chr> "Current", "Current", "Current", "Current", "Historical", "Farmline", "Current", "Current", "C…
# $ well_status  <chr> "Plugged", "Active/Other", "Active/Other", "Abandoned/Orphaned", "Historical", "Historical", "…
# $ geoms        <POINT [°]> POINT (-80.25617 39.87908), POINT (-79.378 40.86019), POINT (-79.621 40.7666), POINT (-8…

# extract latitude and longtude from coordinates, add columns to data
coords <- st_coordinates(pa_wells)
pa_wells$latitude = coords[, "Y"]
pa_wells$longitude = coords[, "X"]

# function to convert well name to title case
title_case_wells <- function(well_vector) {
  
  # clean up stringified R vectors, quotes etc
  well_vector <- gsub('^c\\(|\\)$', '', well_vector) # remove leading c( and trailing )
  well_vector <- gsub('["\']', '', well_vector)       # remove stray quotes
  well_vector <- sub(",.*$", "", well_vector)         # take the first value if comma-separated
  
  # convert"Null", "NA", etc., to true R NA values
  well_vector[tolower(well_vector) %in% c("null", "na", "n/a", "none")] <- NA
  
  # save NA mask to restore missing values at the end
  na_mask <- is.na(well_vector)
  
  # base title case
  clean_names <- str_to_title(well_vector)
  
  # process non-NA elements
  words_list <- str_split(clean_names, "\\s+")
  
  formatted_names <- sapply(words_list, function(w) {
    if (all(is.na(w))) return(NA_character_)
    
    # capitalize 2-letter codes (except Co/No), single letters, & alphanumeric IDs
    is_two_letter <- nchar(w) == 2 & grepl("^[A-Za-z]{2}$", w) & !w %in% c("Co", "No")
    is_single_letter <- nchar(w) == 1 & grepl("^[A-Za-z]$", w)
    has_number <- grepl("\\d", w)
    
    w[is_two_letter | is_single_letter | has_number] <- toupper(w[is_two_letter | is_single_letter | has_number])
    
    # fix Mc prefixes (e.g., Mcgill -> McGill)
    mc_idx <- grepl("^Mc[a-z]", w) & nchar(w) > 3
    if (any(mc_idx)) {
      w[mc_idx] <- paste0("Mc", toupper(substr(w[mc_idx], 3, 3)), substr(w[mc_idx], 4, nchar(w[mc_idx])))
    }
    
    # collapse words back into a single string per well name
    paste(w, collapse = " ")
  })
  
  # restore true R NAs
  formatted_names[na_mask] <- NA_character_
  
  return(unname(formatted_names))
}

# standardize case and other cleaning
pa_wells <- pa_wells %>%
  mutate(well_name = title_case_wells(well_name),
         county = str_to_title(county),
         county = str_replace(county,"00_west Virginia|Out Of State",NA_character_),
         municipality = str_to_title(municipality),
         municipality = str_remove(municipality, ",.*")) # removing Twp, Boro etc

glimpse(pa_wells)
# Rows: 226,257
# Columns: 10
# $ api          <chr> "059-00319", "073-20280", "003-90287", "049-24037", NA, "123-00580", "083-39779", "085-23551",…
# $ well_name    <chr> "Jos Murdock 1", "Byler 72", "G W Baldwin 1", "Frances Hedderick 1", NA, "Bovee A3", "Lot 11 1…
# $ pf_stat      <chr> "Plugged OG Well", "Active", "Plugged OG Well", "Active", NA, "Plugged OG Well", "Plugged OG W…
# $ county       <chr> "Greene", "Lawrence", "Allegheny", "Erie", "Allegheny", "Warren", "Mckean", "Mercer", "Jeffers…
# $ municipality <chr> "Whiteley", "Hickory", "North Fayette", "Waterford", "Penn Hills", "Southwest", "Lafayette", "…
# $ origin_layer <chr> "Current", "Current", "Current", "Current", "Historical", "Current", "Current", "Current", "Cu…
# $ well_status  <chr> "Plugged", "Active/Other", "Plugged", "Active/Other", "Historical", "Plugged", "Plugged", "Act…
# $ geoms        <POINT [°]> POINT (-80.11223 39.85459), POINT (-80.28387 41.07113), POINT (-80.21762 40.3972), POINT…
# $ latitude     <dbl> 39.85459, 41.07113, 40.39720, 41.96708, 40.46592, 41.69487, 41.82380, 41.17779, 41.17760, 41.7…
# $ longitude    <dbl> -80.11223, -80.28387, -80.21762, -79.92856, -79.87578, -79.52714, -78.76569, -80.11640, -79.00…

# numbers of wells in each category
pa_wells %>%
  st_drop_geometry() %>%
  group_by(well_status) %>%
  count()
# # A tibble: 4 × 2
# # Groups:   well_status [4]
# well_status             n
# <chr>               <int>
# 1 Abandoned/Orphaned  28070
# 2 Active/Other       105060
# 3 Historical          36594
# 4 Plugged             56533

##################################################
# data on pre-plugging investigations
# loads behind the dashboard at https://www.arcgis.com/apps/instant/portfolio/index.html?appid=064e373125c34182b2e132dd50d7c619
##################################################

survey <- esri2sf("https://services5.arcgis.com/bykQ7FaL2oSIxFNa/arcgis/rest/services/survey123_934e46cf84164217946545df8faefdc7_results/FeatureServer/0", crs = NULL)

survey <- survey %>%
  clean_names() %>%
  mutate(inspection_date = mdy(stimulus_date_calc))

# find matches to wells in the pa_wells data
survey_matches <- survey %>%
  st_drop_geometry() %>%
  semi_join(pa_wells, by = "api") %>%
  group_by(api) %>%
  summarise(
    latest_inspection_date = if (all(is.na(inspection_date))) as.Date(NA) else max(inspection_date, na.rm = TRUE),
    attachment_url = list(unique(attachment_url[!is.na(attachment_url)])),
    .groups = "drop"
  ) %>%
  mutate(n_attachment_url = lengths(attachment_url)) %>%
  unique()

glimpse(survey_matches)

#################
# Get urls for photos from survey_matches

# close any open connections
closeAllConnections()

get_photo_urls <- function(url) {
  tryCatch({
    p <- read_html(url)
    links <- p %>% html_elements("a") %>% html_text()
    links <- links[-1]
    links <- paste0(url,"/",links)
    
    photos <- c()
    for (l in links) {
      photo <- tryCatch({
        pp <- read_html(l) %>%
          html_elements("a") %>%
          html_attr("href") %>%
          basename()
        pp <- pp[-1]
        paste0(l, "/", pp)
      }, error = function(e) {
        warning(paste("Failed subpage:", l, "-", e$message))
        character(0)
      })
      photos <- c(photos, photo)
    }
    photos
  }, error = function(e) {
    warning(paste("Failed top-level page:", url, "-", e$message))
    character(0)
  })
}

survey_matches$photo_urls <- vector("list", nrow(survey_matches))

for (i in seq_len(nrow(survey_matches))) {
  urls <- survey_matches$attachment_url[[i]]
  
  if (i %% 50 == 0) closeAllConnections() # if open connections are building up, close them every 50 iterations of loop
  
  if (length(urls) == 0) {
    survey_matches$photo_urls[[i]] <- character(0)
    next
  }
  
  api_photos <- c()
  for (u in urls) {
    api_photos <- c(api_photos, get_photo_urls(u))
  }
  
  survey_matches$photo_urls[[i]] <- api_photos
  print(i)
}

# join to the wells data
survey_join <- survey_matches %>%
  mutate(photos = map_chr(photo_urls, ~ toJSON(.x))) %>%
  select(api, photos) %>%
  filter(photos != "[]")

pa_wells <- left_join(pa_wells,survey_join, by = "api")

##################################################
# write geodata for interactive map
##################################################

# write to GeoBuf
st_write(
 pa_wells, 
  "map_data/pa_wells.fgb", 
  driver = "FlatGeobuf",
  dataset_options = "SPATIAL_INDEX=YES",
  delete_dsn = TRUE
)

# setup paths 
out_dir <- file.path(getwd(), "map_data")

out <- file.path(out_dir, "pa_wells.mbtiles")
geojson <- tempfile(fileext = ".geojson")

# write to GeoJSON 
st_write(pa_wells, geojson, delete_dsn = TRUE, overwrite = TRUE)

# build tippecanoe command with shQuote to protect paths and add density flags
cmd <- sprintf(
  'tippecanoe -o %s -l pa_wells -Z4 -z13 --drop-rate=0 --no-tile-size-limit --force %s',
  shQuote(out), 
  shQuote(geojson)
)

# execute
system(cmd)

# convert to pmtiles
system('./pmtiles convert map_data/pa_wells.mbtiles map_data/pa_wells.pmtiles')

# clean up
if (file.exists(geojson)) file.remove(geojson)
file.remove("map_data/pa_wells.mbtiles")
rm(geojson,out,out_dir,cmd)

##################################################
# record date of data update for display in the interactive map
##################################################

# format current date as 'Abbreviated-Month Day, Year' (e.g., "Sep 15, 2026")
date_str <- format(Sys.Date(), "%b %e, %Y")

# clean any double spaces in single-digit days and construct the JS string
js_content <- sprintf('const dataLastUpdated = "%s";', gsub("  ", " ", trimws(date_str)))

# write to data_date.js
writeLines(js_content, "map_data/data_date.js")

# save data
save.image("processed_data/pa_wells.RData")