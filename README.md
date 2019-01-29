## The package

The CBRT package includes functions for finding, and downloading data from the Central Bank of the Republic of Turkey's database.

The CBRT database covers more than 22,000 time series variables.

You can install the package from the source by using the following command (the __CBRT__ package depends on the __data.table__ package.):

```{r, eval = F}
install.packages("http://users.metu.edu.tr/etaymaz/files/CBRT_0.1.0.tar.gz",
                 repos = NULL, type = "source")
```
You may also install it from GitHub. Install the the <a href="https://github.com/r-lib/devtools">devtools</a> package if not installed, then

```{r, eval = F}
library(devtools)
install_github("etaymaz/CBRT")
```

Please kindly note that you need a __key__ to download data from the CBRT's database. To get the __key__, register at the CBRT's <a href="https://evds2.tcmb.gov.tr/index.php?/" target="_blank">Electronic Data Delivery System</a>. Registration is free of charge and takes only a few minutes.

If you create an object called __myCBRTkey__ in R session, you do not need to define it for downloading:

`myCBRTKey <-` _your-key_


## Finding and downloading variables

All __data series__ (variables) are classified into __data groups__, and data groups into __data categories__. There are 24 
data categories (including the archieved ones), 323 data groups, 
and 22,243 data series.

To find variables, use the `searchCBRT` function:

```{r, p0, eval = FALSE}
searchCBRT(c("production", "labor", "labour"))
searchCBRT(c("production", "labor", "labour"), tags = TRUE)
```

The package contains the lists of all data categories, data groups, and
data series, as of 26 January 2019. You can update the lists
by the following commands:

```{r, p1, eval = FALSE}
allCBRTCategories <- getAllCategories()
allCBRTGroups <- getAllGroups()
allCBRTSeries <- getAllSeries()
```

After identifying the data group or data series, you can get 
some information about the data by `showGroupInfo` function:

```{r, p2, eval = FALSE}
showGroupInfo("bie_apifon")
```

If you want to get only names of series in a data group, use the following command:

```{r, p3, eval = FALSE}
showSeriesNames("bie_apifon")
```
You can download either one or more data series you specified, 
or all data series in a data group. 

To download individual data series, use the `getDataSeries` function:

```{r, p4, eval = FALSE}
mySeries <- getDataSeries("TP.D1TOP")
mySeries <- getDataSeries(c("TP.D1TOP", "TP.D2HAZ", "TP.D4TCMB"))
mySeries <- getDataSeries(c("TP.D1TOP", "TP.D2HAZ", "TP.D4TCMB", startDate="01-01-2010"))
```

To download all data series in a group, use the `getDataGroup` function:

```{r, p5, eval = FALSE}
myData <- getDataGroup("bie_dbafod")
```
If you do not define any frequency (the `freq` parameter), the default frequency will be used. If you define a level of frequency lower than the default (for example, "annual" for monthly data), the data will be aggregated by the method you may define by the `aggType` parameter. If no aggregation method is defined, the default will be used. (For the default values, use the `showGroupInfo` function.)

The myData object is in __data.table__ and __data.frame__ classes, and it includes a __time__ variable, and data series. The __time__ variable will be either in `date` or `numeric` format depending on its frequency.

## Comments and suggestions

I would appreciate your comments, suggestions, and bug reports. Please <a href="mailto:etaymaz@metu.edu.tr">contact me by e-mail</a>.
