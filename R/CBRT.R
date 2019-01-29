#' Information about data categories
#'
#' Creates a meta data object for all categories
#'
#'#' @param CBRTkey Your personal CBRT access key
#'
#' @return a data.table object
#'
#' @examples
#' allCBRTSeries <- getAllCategoriesInfo()
#'
#' @export
getAllCategoriesInfo <-
function(CBRTkey = CBRTkey)
{
  fileName <- paste0("https://evds2.tcmb.gov.tr/service/evds/categories/key=",
                    CBRTkey, "&type=csv")
  catData <- fread(fileName)
  setnames(catData, c("cid", "topic", "konu"))
  return(catData[, .(cid, topic)])
}


#' Information about data groups
#'
#' Creates a meta data object for all data gorups
#'
#' @param CBRTkey Your personal CBRT access key
#'
#' @return a data.table object
#'
#' @examples
#' allCBRTGroups <- getAllGroupsInfo()
#'
#' @export
getAllGroupsInfo <-
function(CBRTkey = CBRTkey)
{
  fileName <- paste0("https://evds2.tcmb.gov.tr/service/evds/datagroups/key=",
                    CBRTkey, "&mode=0&type=csv")
  dataGroups <- fread(fileName)
  keepNames <- c("cid", "groupCode", "groupName", "freq", "source", "sourceLink", "note",
                 "revisionPolicy", "upperNote", "appLink")
  setnames(dataGroups, c("CATEGORY_ID", "DATAGROUP_CODE", "DATAGROUP_NAME_ENG", "FREQUENCY",
                         "DATASOURCE_ENG", "METADATA_LINK_ENG", "NOTE_ENG", "REV_POL_LINK_ENG",
                         "UPPER_NOTE_ENG", "APP_CHA_LINK_ENG"), keepNames)
  # Change freq variable so that it is consistent with data retrival freq
  dataGroups[, freq := match(freq, CBRTfreq$tfreq)]
  return(dataGroups[, ..keepNames])
}


#' Information about data series
#'
#' Creates a meta data object for all data series
#'
#' @param CBRTkey Your personal CBRT access key
#'
#' @return a data.table object
#'
#' @examples
#' allCBRTSeries <- getAllSeriesInfo()
#'
#' @export
getAllSeriesInfo <- function(CBRTkey = CBRTkey) {
  if (!exists("allCBRTCategories")) allCBRTCategories <- getAllCategoriesInfo()
  if (!exists("allCBRTGroups")) allCBRTGroups <- getAllGroupsInfo()
  allGroupsCodes <- unique(allCBRTGroups$groupCode)
  allSeries <- vector(mode = "list", length = length(allGroupsCodes))
  keepNames <- c("seriesCode", "seriesName", "groupCode", "start", "end", "aggMethod",
                 "freqname", "tag")
  for (i in seq_along(allGroupsCodes)) {
    gCode <- allGroupsCodes[i]
    fileName <- paste0("https://evds2.tcmb.gov.tr/service/evds/serieList/key=",
                       CBRTkey, "&type=csv&code=", gCode)
    series <- fread(fileName)
    setnames(series, c("SERIE_CODE", "SERIE_NAME_ENG", "DATAGROUP_CODE", "START_DATE", "END_DATE",
                       "DEFAULT_AGG_METHOD", "FREQUENCY_STR", "TAG_ENG"), keepNames)
    allSeries[[i]] <- series[, ..keepNames]
  }
  allSeries <- do.call("rbind", allSeries)
  allSeries[grepl("^HAFTALIK", freqname), freqname := "HAFTALIK"]
  allSeries[, freqname := CBRTfreq$FreqEng[match(freqname, CBRTfreq$FreqTr)]]
  setkey(allCBRTCategories, cid)
  setkey(allCBRTGroups, cid)
  allCBRTGroups <- allCBRTCategories[allCBRTGroups]
  setkey(allCBRTGroups, groupCode)
  setkey(allSeries, groupCode)
  allSeries <- allCBRTGroups[, .(cid, topic, groupCode, groupName, freq)][allSeries]
  allSeries[cid == 0 & grepl("Archive", groupName), topic := "Archived data"]
  return(allSeries)
}

#' Formatting time series
#'
#' Sets the format of a time series object retrieved from the CBRT database
#'
#' @param x a data series
#'
#' @return formatted object
#'
#' @examples
#' myData$myTime <- formatTime(myData$myTime)
#'
#' @export
formatTime <-
function(x)
{
  fr <- x[which.min(!is.na(x))]
  if (grepl("(^[0-9]{4}$)", fr)) x <- as.integer(x)
  if (grepl("(^[SQ0-9-]{7}$)", fr)) x <- as.numeric(substr(x, 1, 4)) + .25 * (as.numeric(substr(x, 7 ,7)) - 1)
  if (grepl("^[0-9]{4}-[0-9]{1,2}$", fr)) x <- as.Date(paste0(x, "-15"), format = "%Y-%m-%d")
  if (grepl("^[0-9]{2}-[0-9]{2}-[0-9]{4}$", fr)) x <- as.Date(x, format = "%d-%m-%Y")
  return(x)
}


#' Showing variable names
#'
#' Shows the names of all variables in a data group
#'
#' @param gCode the code for the data group
#'
#' @return a data.table object
#'
#' @examples
#' showSeriesNames("bie_apifon")
#'
#' @export
showSeriesNames <-
function(gCode)
{
  return(allCBRTSeries[groupCode == gCode, .(seriesCode, seriesName, aggMethod)])
}


#' Information about a data group
#'
#' Shows information about a data group
#'
#' @param gCode the code for the data group
#'
#' @return a data.table object
#'
#' @examples
#' showGroupInfo("bie_apifon")
#'
#' @export
showGroupInfo <-
function(gCode)
{
  if (!exists("allCBRTGroups")) allCBRTGroups <- getAllGroupsInfo()
  info <- data.table(Code = names(allCBRTGroups))
  info$Variable <- t(allCBRTGroups[groupCode == gCode])
  info[Code == "freq",
       Variable := paste0(Variable, " (", CBRTfreq$FreqEng[as.numeric(Variable)], ")" )]
  print(info[1:7, .(Code = Code, Variable = substr(Variable, 1, 80))], justify = "left")
  if (info[8, 2] != "") cat("Note: \n", gsub("     ", "\n ", info[8, 2]), "\n")
  cat(rep("*", times = 39), "\n")
  return(allCBRTSeries[groupCode == gCode, .(seriesCode, seriesName, aggMethod)])
}

#' Variable search
#'
#' Search for keywords in the CBRT datasets
#'
#' @param keywords A vector of keywords
#' @param field The name of the field to be searched (groups, categories, series)
#' @param tags A logical variable that indicates if the tags to be searched
#'
#' @return a data.table object
#'
#' @examples
#' searchCBRT(c("production", "labor", "labour"))
#' searchCBRT(c("production", "labor", "labour"), tags = TRUE)
#'
#' @export
searchCBRT <-
function(keywords, field = c("groups", "categories", "series"), tags = FALSE)
{
  field <- match.arg(field)
  if (field == "categories") {
    sdat <- allCBRTCategories
    sdat[, field := topic]
  } else if (field == "series") {
    sdat <- allCBRTSeries[, .(seriesCode, seriesName, groupCode, groupName)]
    sdat[, field := seriesName]
  } else {
    sdat <- allCBRTGroups[, .(groupCode, groupName)]
    sdat[, field := groupName]
  }

  if (tags == T)  {
    sdat <- allCBRTSeries[, .(seriesCode, seriesName, groupCode, groupName, tag)]
    setnames(sdat, "tag", "field")
  }

  sres <- matrix(nrow = nrow(sdat), ncol = length(keywords))
  for (ii in seq_along(keywords)) {
    sres[, ii] <- grepl(keywords[ii], sdat$field, ignore.case = T)
  }

  msum <- apply(sres, 1, sum)
  sdat$msum <- msum
  sdat <- sdat[order(-msum)][msum > 0]

  sdat[, c("field", "msum") := NULL]
  print(sdat, justify = "left")
}

#' Downloading data series
#'
#' Downloads one or more data series from the CBRT datasets
#'
#' @param series A vector of data series' codes
#' @param CBRTkey Your personal CBRT access key
#' @param freq Numeric, the frequency of the data series
#' @param aggType Aggregation of data series
#' @param startDate The beginning date for data series (DD-MM-YYYY)
#' @param endDate The ending date for data series (DD-MM-YYYY)
#' @param na.rm Logical variable to drop all missing dates
#'
#' @return a data.table object
#'
#' @examples
#' mySeries <- getDataSeries("TP.D1TOP")
#' mySeries <- getDataSeries(c("TP.D1TOP", "TP.D2HAZ", "TP.D4TCMB"))
#' mySeries <- getDataSeries(c("TP.D1TOP", "TP.D2HAZ", "TP.D4TCMB", startDate="01-01-2010"))
#'
#' @export
getDataSeries <-
function(series, CBRTkey = CBRTkey, freq, aggType, startDate = "01-01-1950", endDate, na.rm = T)
{
  if (missing(endDate)) endDate <- format.Date(Sys.Date(), "%d-%m-%Y")
  if (grepl("^[0-9]{4}-[0-9]{2}-[0-9]{2}$", startDate)) startDate <- format.Date(as.Date(startDate, format = "%Y-%m-%d"), "%d-%m-%Y")
  if (grepl("^[0-9]{4}-[0-9]{2}-[0-9]{2}$", endDate)) endDate <- format.Date(as.Date(endDate, format = "%Y-%m-%d"), "%d-%m-%Y")
  series <- paste(gsub("_", ".", series), collapse = "-")
  fileName <- paste0("https://evds2.tcmb.gov.tr/service/evds/series=", series,
                     "&startDate=", startDate, "&endDate=", endDate,
                     "&type=csv&key=", CBRTkey)
  if (!missing(freq)) fileName <- paste0(fileName, "&frequency=", freq)
  if (!missing(aggType)) fileName <- paste0(fileName, "&aggregationTypes=", aggType)
  data <- fread(fileName, na.strings = c("ND", "null"))
  data[, c("UNIXTIME") := NULL]
  setnames(data, "Tarih", "time")
  onames <- names(data)
  onames <- gsub("_", ".", onames)
  setnames(data, onames)
  data[, time := formatTime(time)]
  if (exists("YEARWEEK", where = data)) data[, YEARWEEK := NULL]
  # Remove all missing row
  nvar <- ncol(data) - 1
  if (na.rm == T) data <- data[!(rowSums(is.na(data)) == nvar)]
  return(data)
}


#' Downloading data groups
#'
#' Downloads all data series of a data group
#'
#' @param group Code for the data group
#' @param CBRTkey Your personal CBRT access key
#' @param freq Numeric, the frequency of the data series
#' @param startDate The beginning date for data series (DD-MM-YYYY)
#' @param endDate The ending date for data series (DD-MM-YYYY)
#' @param na.rm Logical variable to drop all missing dates
#'
#' @return a data.table object
#'
#' @examples
#' myData <- getDataGroup("bie_dbafod")
#'
#' @export
getDataGroup <- function(group, CBRTkey = CBRTkey, freq, startDate = "01-01-1950", endDate, na.rm = T) {
  if (missing(endDate)) endDate <- format.Date(Sys.Date(), "%d-%m-%Y")
  if (grepl("^[0-9]{4}-[0-9]{2}-[0-9]{2}$", startDate)) startDate <- format.Date(as.Date(startDate, format = "%Y-%m-%d"), "%d-%m-%Y")
  if (grepl("^[0-9]{4}-[0-9]{2}-[0-9]{2}$", endDate)) endDate <- format.Date(as.Date(endDate, format = "%Y-%m-%d"), "%d-%m-%Y")
  fileName <- paste0("https://evds2.tcmb.gov.tr/service/evds/datagroup=", group,
                    "&startDate=", startDate, "&endDate=", endDate,
                    "&type=csv&key=", CBRTkey)
  if (!missing(freq)) fileName <- paste0(fileName, "&frequency=", freq)
  # Aggregation type is the default type for data groups
  data <- fread(fileName, na.strings = c("ND", "null"))
  data[, c("UNIXTIME") := NULL]
  setnames(data, "Tarih", "time")
  data[, time := formatTime(time)]
  onames <- names(data)
  onames <- gsub("_", ".", onames)
  setnames(data, onames)
  if (exists("YEARWEEK", where = data)) data[, YEARWEEK := NULL]
  # Remove all missing row
  nvar <- ncol(data) - 1
  if (na.rm == T) data <- data[!(rowSums(is.na(data)) == nvar)]
  cat("\n")
  # Print series names
  if (exists("allCBRTSeries")) print(showSeriesNames(group))
  return(data)
}
