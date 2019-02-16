## ---- p0, eval = FALSE---------------------------------------------------
#  searchCBRT(c("production", "labor", "labour"))
#  searchCBRT(c("production", "labor", "labour"), field = "series")
#  searchCBRT(c("production", "labor", "labour"), tags = TRUE)

## ---- p1, eval = FALSE---------------------------------------------------
#  allCBRTCategories <- getAllCategories()
#  allCBRTGroups <- getAllGroups()
#  allCBRTSeries <- getAllSeries()

## ---- p2, eval = FALSE---------------------------------------------------
#  showGroupInfo("bie_apifon")

## ---- p3, eval = FALSE---------------------------------------------------
#  showSeriesNames("bie_apifon")

## ---- p4, eval = FALSE---------------------------------------------------
#  mySeries <- getDataSeries("TP.D1TOP")
#  mySeries <- getDataSeries(c("TP.D1TOP", "TP.D2HAZ", "TP.D4TCMB"))
#  mySeries <- getDataSeries(c("TP.D1TOP", "TP.D2HAZ", "TP.D4TCMB", startDate="01-01-2010"))

## ---- p5, eval = FALSE---------------------------------------------------
#  myData <- getDataGroup("bie_dbafod")

