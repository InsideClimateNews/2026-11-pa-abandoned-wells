# Pennsylvania Oil and Gas Wells

This repository contains code used to make the interactive map displayed in stories in the series [Abandoned](https://insideclimatenews.org/project/abandoned/), published by Inside Climate News and the Pittsburgh Post-Gazette.

### Methods

We simplified the Pennsylvania Department of Environmental Protection's system for classifying wells into four categories:

**Active/Other.** These are mostly wells that are still producing oil or gas. However, the state’s active category includes wells that have no other status description, which means that some disused wells may be mistakenly included. We have also included a small number of wells with “[regulatory inactive status](https://www.law.cornell.edu/regulations/pennsylvania/25-Pa-Code-SS-78-104),” which allows an operator to shut down production for up to five years without having to seal a well. 

**Plugged** wells are recorded as sealed. Most were plugged by contractors hired by their former operators, but some were sealed by the state. Plugging may fail because materials like metal pipe and cement deteriorate over time, so some of these wells may still leak gases.

**Abandoned/Orphaned** includes abandoned wells, which have been out of production for more than 12 months. [Orphaned wells](https://www.pa.gov/agencies/dep/programs-and-services/oil-and-gas/legacy-wells) are abandoned wells for which no responsible operator or owner exists. 

**Historical.** The Department of Environmental Protection is in the process of digitizing hand-drawn [historical](https://www.minemaps.psu.edu/aboutnew.htm) [maps](https://www.pa.gov/agencies/dep/programs-and-services/oil-and-gas/legacy-wells/farmline-maps) showing older wells. These maps are not comprehensive—so far they concentrate on the southwest of the state—and have largely not been verified by modern inspections.

We excluded wells that appear in the state’s data as proposed but were never actually drilled, plus wells marked in the data as duplicates, which were mistakenly given a new American Petroleum Institute well number.

### **Analysis code/data**

Data used for the map comes from the following Pennsylvania Department of Environmental Protection sources:

- [**Oil and Gas Well Inventory**](https://greenport.pa.gov/ReportExtracts/OG/OilGasWellInventoryReport). Full data for all operators and well configurations exported as a CSV file.

- [**WPA Mine Maps**](https://www.minemaps.psu.edu/aboutnew.htm). These are hand-drawn maps of mines [made in the 1930s](https://www.minemaps.psu.edu/aboutnew.htm#2.%20What%20is%20a%20WPA%20mine%20map?) that also show oil and gas wells. We obtained data for wells that have been digitized from these maps and made publicly available from [this map layer](https://gis.dep.pa.gov/depgisprd/rest/services/OilGas/OilGasAllStrayGasEGSP/MapServer/6).

- [**Farmline Maps**](https://www.pa.gov/agencies/dep/programs-and-services/oil-and-gas/legacy-wells/farmline-maps). These are hand-drawn maps made by oil and gas companies to locate their wells, typically using county property line maps as a basemap. We obtained data for wells that have been digitized from these maps and made publicly available from [this map layer](https://gis.dep.pa.gov/depgisprd/rest/services/OilGas/OilGasAllStrayGasEGSP/MapServer/7).

URLs for photos of wells taken during government inspections were scraped using information in [this map layer](https://services5.arcgis.com/bykQ7FaL2oSIxFNa/arcgis/rest/services/survey123_934e46cf84164217946545df8faefdc7_results/FeatureServer/0), which underpins [this dashboard](https://www.arcgis.com/apps/instant/portfolio/index.html?appid=064e373125c34182b2e132dd50d7c619).

The [R](https://www.r-project.org/) script `pa_wells.R` processes data from these sources, writing the results to [FlatGeoBuf](https://flatgeobuf.org/) and [PMtiles](https://docs.protomaps.com/pmtiles/) formats used for the interactive map. Conversion to PMtiles, as executed in this script, depends on [tippecanoe](https://github.com/mapbox/tippecanoe) and the [pmtiles CLI](https://docs.protomaps.com/pmtiles/cli).

At the time of publication, the processed data contained the following:

| Category           | Number of wells **†** |
|--------------------|-----------------------|
| Active/Other       | 105,060               |
| Plugged            | 56,533                |
| Abandoned/Orphaned | 28,070                |
| Historical         | 36,594                |

**†** Note the possibility of duplicates, see below.

We scraped inspection photo URLs for a total of 3,242 of the wells displayed on the interactive map.

### **Caveats/limitations**

The Department of Environmental Protection is responsible for the accuracy of the underlying data. It warns that an individual well may appear in both historical maps and its actively maintained inventory. Wells may also be duplicated, possibly with slightly different locations, across the two digitized historical map collections used for our Historical category.

Locations for wells in our Historical category depend on digitized versions of maps that were originally drawn by hand, and therefore may be less reliable than those in the Department of Environmental Protection's inventory.

Wells may be misclassified in the state data. For example, Jane McGill #1, an old well on the property of the Pittsburgh Botanic Garden, was at the time of publication listed as active in the Department of Environmental Protection's inventory, but it is actually an abandoned well.

We have only been able to include wells mapped by the agency. Many older wells—possibly several hundred thousand—are missing from the records. In addition, we were unable to map more than 29,000 wells for which the Department of Environmental Protection’s inventory gave no coordinates. About half of these are Plugged wells, almost 6,000 fall into our Abandoned/Orphaned category and the remainder are Active/Other.

### Interactive map

The interactive map embedded in our stories is in the file `pa-wells.html`. It was built using [MapLibre](https://maplibre.org/) and uses [OpenFreeMap](https://openfreemap.org/) and [ESRI World Imagery](https://www.arcgis.com/home/item.html?id=10df2279f9684e4a9f6a7f08febac2a9&rsource=https%3A%2F%2Flinks.esri.com%2Fagol-help%2Fworld-imagery#overview) basemaps.

The map uses the [photon](https://photon.komoot.io/) geocoder to search [OpenStreetMap](https://www.openstreetmap.org/) for entered locations. Where no matching address is found, it falls back to the [U.S. Census Geocoder](https://geocoding.geo.census.gov/geocoder/). Distances to the nearest well from searched locations are calculated in the browser using [Turf.js](https://turfjs.org/).

The repository also contains the file `botanic-garden.html`, zoomed in to the Pittsburgh Botanic Garden, showing the location of Jane McGill #1 and nearby wells.

### **Questions/Feedback**

Email [Peter Aldhous](mailto:peter.aldhous@insideclimatenews.org).
