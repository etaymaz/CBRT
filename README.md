
<!-- README.md is generated from README.Rmd. Please edit that file -->

## The package

The CBRT package includes functions for finding, and downloading data
from the Central Bank of the Republic of Turkey’s database.

The CBRT database covers more than 22,000 time series variables.

You can install the package from the source by using the following
command (the **CBRT** package depends on the **data.table** package.):

``` r
install.packages("http://users.metu.edu.tr/etaymaz/files/CBRT_0.1.0.tar.gz",
                 repos = NULL, type = "source")
```

You may also install it from GitHub. Install the the
<a href="https://github.com/r-lib/devtools">devtools</a> package if not
installed, then

``` r
library(devtools)
install_github("etaymaz/CBRT")
```

Please kindly note that you need a **key** to download data from the
CBRT’s database. To get the **key**, register at the CBRT’s
<a href="https://evds2.tcmb.gov.tr/index.php?/" target="_blank">Electronic
Data Delivery System</a>. Registration is free of charge and takes only
a few minutes.

If you create an object called **myCBRTkey** in R session, you do not
need to define it for downloading:

`myCBRTKey <-` *your-key*

## Finding and downloading variables

All **data series** (variables) are classified into **data groups**, and
data groups into **data categories**. There are 24 data categories
(including the archieved ones), 323 data groups, and 22,243 data series.

To find variables, use the `searchCBRT` function:

``` r
searchCBRT(c("production", "labor", "labour"))
searchCBRT(c("production", "labor", "labour"), field = "series")
searchCBRT(c("production", "labor", "labour"), tags = TRUE)
```

The package contains the lists of all data categories, data groups, and
data series, as of 26 January 2019. You can update the lists by the
following commands:

``` r
allCBRTCategories <- getAllCategoriesInfo()
allCBRTGroups <- getAllGroupsInfo()
allCBRTSeries <- getAllSeriesInfo()
```

After identifying the data group or data series, you can get some
information about the data by `showGroupInfo` function:

``` r
showGroupInfo("bie_apifon")
```

If you want to get only names of series in a data group, use the
following command:

``` r
showSeriesNames("bie_apifon")
```

You can download either one or more data series you specified, or all
data series in a data group.

To download individual data series, use the `getDataSeries` function:

``` r
mySeries <- getDataSeries("TP.D1TOP")
mySeries <- getDataSeries(c("TP.D1TOP", "TP.D2HAZ", "TP.D4TCMB"))
mySeries <- getDataSeries(c("TP.D1TOP", "TP.D2HAZ", "TP.D4TCMB", startDate="01-01-2010"))
```

To download all data series in a group, use the `getDataGroup` function:

``` r
myData <- getDataGroup("bie_dbafod")
```

The `freq` parameter defines the frequency of the data. If you do not
define any frequency, the default frequency will be used.

The `aggType` paremeter defines the method to be used to aggregate data
series from high frequency to low frequency (for example, weekly data to
monthly data). If no aggregation method is defined, the default will be
used. (For the default values, use the `showGroupInfo` function.)

For example, if you define monthly frequency for weekly data, and “sum”
as the aggregation method, then the monthly totals will be returned.
Since a data group includes more than one series, the `getDataGroup`
function does not have any `aggType` parameter, and it aggregates data
series by using their default aggregation method.

The following frequencies are defined (from high frequency to low
frequency):

- `1` Day
- `2` Work day
- `3` Week
- `4` Biweekly
- `5` Month
- `6` Quarter
- `7` Six months
- `8` Year

The following aggregation methods are available:

- `avg` Average value
- `first` First observation
- `last` Last observation
- `max` Maximum value
- `min` Minimum value
- `sum` Sum

The myData object is in **data.table** and **data.frame** classes, and
it includes a **time** variable, and data series. The **time** variable
will be either in `date` or `numeric` format depending on its frequency.

## Comments and suggestions

I would appreciate your comments, suggestions, and bug reports. Please
<a href="mailto:etaymaz@metu.edu.tr">contact me by e-mail</a>.
