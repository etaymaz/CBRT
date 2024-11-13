globalVariables(c("myCBRTKey"))
#' Information about data categories
#'
#' Creates a meta data object for all categories
#'
#' @param CBRTKey Your personal CBRT access key
#'
#' @return a data.table object
#'
#' @examples
#' \dontrun{
#' allCBRTCategories <- getAllCategoriesInfo()
#' }
#'
#' @export
getAllCategoriesInfo <-
function(CBRTKey = myCBRTKey)
{
  fileName <- "https://evds2.tcmb.gov.tr/service/evds/categories/type=csv"
  catData <- CBRT_fread(fileName, CBRTKey)
  setnames(catData, c("cid", "topic", "konu"))
  return(catData[, c("cid", "topic")])
}


#' Information about data groups
#'
#' Creates a meta data object for all data gorups
#'
#' @param CBRTKey Your personal CBRT access key
#'
#' @return a data.table object
#'
#' @examples
#' \dontrun{
#' allCBRTGroups <- getAllGroupsInfo()
#' }
#'
#' @export
#' @import data.table
getAllGroupsInfo <-
function(CBRTKey = myCBRTKey)
{
  freq <- groupName <- NULL
  fileName <- paste0("https://evds2.tcmb.gov.tr/service/evds/datagroups/mode=0&type=csv")
  dataGroups <- CBRT_fread(fileName, CBRTKey)
  keepNames <- c("cid", "groupCode", "groupName", "freq", "source", "sourceLink",
                 "revisionPolicy", "appLink", "firstDate", "lastDate")
  setnames(dataGroups, c("CATEGORY_ID", "DATAGROUP_CODE", "DATAGROUP_NAME_ENG", "FREQUENCY",
                         "DATASOURCE_ENG", "METADATA_LINK_ENG", "REV_POL_LINK_ENG",
                         "APP_CHA_LINK_ENG", "END_DATE", "START_DATE"), keepNames)
  dataGroups <- dataGroups[, keepNames, with = FALSE]

  # Change freq variable so that it is consistent with data retrival freq
  dataGroups[, freq := match(freq, CBRT::CBRTfreq$tfreq)]
  dataGroups[, groupName := changeASCII(groupName)]
  return(dataGroups[, keepNames, with = FALSE])
}


#' Information about data series
#'
#' Creates a meta data object for all data series
#'
#' @param CBRTKey Your personal CBRT access key
#' @param verbose TRUE turns on status and information messages to the console
#'
#' @return a data.table object
#'
#' @examples
#' \dontrun{
#' allCBRTSeries <- getAllSeriesInfo()
#' }
#'
#' @export
#' @import data.table
getAllSeriesInfo <- function(CBRTKey = myCBRTKey, verbose = TRUE) {
  freqname <- cid <- groupCode <- topic <- groupName <- freq <- seriesName <- tag <- NULL
  if (!exists("allCBRTCategories")) allCBRTCategories <- getAllCategoriesInfo()
  if (!exists("allCBRTGroups")) allCBRTGroups <- getAllGroupsInfo()
  allGroupsCodes <- unique(allCBRTGroups$groupCode)
  allSeries <- vector(mode = "list", length = length(allGroupsCodes))
  keepNames <- c("seriesCode", "seriesName", "groupCode", "start", "end", "aggMethod",
                 "freqname", "tag")
  nSeries <- length(allGroupsCodes)
  for (i in seq_along(allGroupsCodes)) {
    gCode <- allGroupsCodes[i]
    if (verbose) cat("Series", i, "of", nSeries, ":", gCode, "\n")
    fileName <- paste0("https://evds2.tcmb.gov.tr/service/evds/serieList/type=csv&code=", gCode)
    tryCatch(series <- CBRT_fread(fileName, CBRTKey),
             error = function(e) {
               warning(gCode, " is not available at CBRT database.")
               })
    if (exists("series") == TRUE) {
      setnames(series, c("SERIE_CODE", "SERIE_NAME_ENG", "DATAGROUP_CODE", "START_DATE", "END_DATE",
                         "DEFAULT_AGG_METHOD", "FREQUENCY_STR", "TAG_ENG"), keepNames)
     allSeries[[i]] <- series[, keepNames, with = FALSE]
     rm(series)
    }
  }
  allSeries <- do.call("rbind", allSeries)
  allSeries[grepl("^HAFTALIK", freqname), freqname := "HAFTALIK"]
  allSeries[, freqname := CBRT::CBRTfreq$FreqEng[match(freqname, CBRT::CBRTfreq$FreqTr)]]
  setkey(allCBRTCategories, cid)
  setkey(allCBRTGroups, cid)
  allCBRTGroups <- allCBRTCategories[allCBRTGroups]
  setkey(allCBRTGroups, groupCode)
  setkey(allSeries, groupCode)
  allSeries <- allCBRTGroups[, c("cid", "topic", "groupCode", "groupName", "freq")][allSeries]
  allSeries[cid == 0 & grepl("Archive", groupName), topic := "Archived data"]
  # Remove non-ASCII characters
  allSeries[, groupName := changeASCII(groupName)]
  allSeries[, seriesName := changeASCII(seriesName)]
  allSeries[, tag := gsub("\u00A0", "", tag)]
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
#' @keywords internal
#' @importFrom stats time
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
#' @import data.table
showSeriesNames <-
function(gCode)
{
  groupCode <- NULL
  if (!exists("allCBRTSeries")) allCBRTSeries <- getAllSeriesInfo()
  return(allCBRTSeries[groupCode == gCode, c("seriesCode", "seriesName", "aggMethod")])
}


#' Information about a data group
#'
#' Shows information about a data group
#'
#' @param gCode the code for the data group
#' @param verbose TRUE turns on status and information messages to the console
#'
#' @return a data.table object
#'
#' @examples
#' showGroupInfo("bie_apifon")
#'
#' @export
#' @import data.table
showGroupInfo <-
function(gCode, verbose = TRUE)
{
  groupCode <- Code <- Variable <- seriesCode <- seriesName <- aggMethod <- NULL
  if (!exists("allCBRTGroups")) allCBRTGroups <- getAllGroupsInfo()
  if (!exists("allCBRTSeries")) allCBRTSeries <- getAllSeriesInfo()
  info <- data.table(Code = names(allCBRTGroups))
  info$Variable <- t(allCBRTGroups[groupCode == gCode])
  info[Code == "freq",
       Variable := paste0(Variable, " (", CBRT::CBRTfreq$FreqEng[as.numeric(Variable)], ")" )]
  # Print if verbose
  if (verbose) {
    print(info[1:7, list(Code = Code, Variable = substr(Variable, 1, 80))], justify = "left")
    if (info[8, 2] != "") cat("Note: \n", gsub("     ", "\n ", info[8, 2]), "\n")
    cat(rep("*", times = 39), "\n")
  }
  return(allCBRTSeries[groupCode == gCode, c("seriesCode", "seriesName", "aggMethod")])
}

#' Variable search
#'
#' Search for keywords in the CBRT datasets
#'
#' @param keywords A vector of keywords
#' @param field The name of the field to be searched ("groups", "categories" or
#' "series"). We recommend searching first the "groups" names.
#' @param tags A logical variable that indicates if the tags to be searched
#'
#' @return a data.table object
#'
#' @examples
#' searchCBRT(c("production", "labor", "labour"))
#' searchCBRT(c("production", "labor", "labour"), field = "series")
#' searchCBRT(c("production", "labor", "labour"), tags = TRUE)
#'
#' @export
#' @import data.table
searchCBRT <-
function(keywords, field = c("groups", "categories", "series"), tags = FALSE)
{
  topic <- seriesCode <- seriesName <- groupCode <- groupName <- tag <- NULL
  if (!exists("allCBRTCategories")) allCBRTCategories <- getAllCategoriesInfo()
  if (!exists("allCBRTGroups")) allCBRTGroups <- getAllGroupsInfo()
  if (!exists("allCBRTSeries")) allCBRTSeries <- getAllSeriesInfo()
  field <- match.arg(field)
  if (field == "categories") {
    sdat <- allCBRTCategories
    sdat[, field := topic]
  } else if (field == "series") {
    sdat <- allCBRTSeries[, c("seriesCode", "seriesName", "groupCode", "groupName")]
    sdat[, field := seriesName]
  } else {
    sdat <- allCBRTGroups[, c("groupCode", "groupName")]
    sdat[, field := groupName]
  }

  if (tags == TRUE)  {
    sdat <- allCBRTSeries[, c("seriesCode", "seriesName", "groupCode", "groupName", "tag")]
    setnames(sdat, "tag", "field")
  }

  sres <- matrix(nrow = nrow(sdat), ncol = length(keywords))
  for (ii in seq_along(keywords)) {
    sres[, ii] <- grepl(keywords[ii], sdat$field, ignore.case = TRUE)
  }

  msum <- apply(sres, 1, sum)
  sdat$msum <- msum
  sdat <- sdat[order(-msum)][msum > 0]

  sdat[, c("field", "msum") := NULL]
  return(sdat[])
}

#' Downloading data series
#'
#' Downloads one or more data series from the CBRT datasets.
#'
#' @param series A vector of data series' codes.
#' @param CBRTKey Your personal CBRT access key.
#' @param freq Numeric, the frequency of the data series. If not defined, the default
#' (the highest possible frequency) will be used. The frequencies are as follows:
#' \describe{
#'   \item{1}{Day}
#'   \item{2}{Work day}
#'   \item{3}{Week}
#'   \item{4}{Biweekly}
#'   \item{5}{Month}
#'   \item{6}{Quarter}
#'   \item{7}{Six months}
#'   \item{8}{Year}
#' }
#' @param aggType Aggregation of data series. This paremeter defines the method
#' to be used to aggregate data series from high frequency to low frequency (for
#' example, weekly data to monthly data). The following methods are available:
#' \describe{
#'   \item{avg}{Average value}
#'   \item{first}{First observation}
#'   \item{last}{Last observation}
#'   \item{max}{Maximum value}
#'   \item{min}{Minimum value}
#'   \item{sum}{Sum}
#' }
#' If a frequency level lower than the default is used, the data will be aggregated
#' by using the default method for that data group (for example, if monthly data
#' are download for weekly series).
#' @param startDate The beginning date for data series (DD-MM-YYYY).
#' @param endDate The ending date for data series (DD-MM-YYYY). If not defined, the default
#' (the latest available) will be used.
#' @param na.rm Logical variable to drop all missing dates.
#'
#' @return a data.table object
#'
#' @examples
#' \dontrun{
#' mySeries <- getDataSeries("TP.D1TOP")
#' mySeries <- getDataSeries(c("TP.D1TOP", "TP.D2HAZ", "TP.D4TCMB"))
#' mySeries <- getDataSeries(c("TP.D1TOP", "TP.D2HAZ", "TP.D4TCMB", startDate="01-01-2010"))
#' }
#'
#' @export
#' @import data.table
getDataSeries <-
function(series, CBRTKey = myCBRTKey, freq, aggType, startDate = "01-01-1950",
         endDate, na.rm = TRUE)
{
  YEARWEEK <- NULL
  if (missing(endDate)) endDate <- format.Date(Sys.Date(), "%d-%m-%Y")
  if (grepl("^[0-9]{4}-[0-9]{2}-[0-9]{2}$", startDate)) startDate <- format.Date(as.Date(startDate, format = "%Y-%m-%d"), "%d-%m-%Y")
  if (grepl("^[0-9]{4}-[0-9]{2}-[0-9]{2}$", endDate)) endDate <- format.Date(as.Date(endDate, format = "%Y-%m-%d"), "%d-%m-%Y")
  series <- paste(gsub("_", ".", series), collapse = "-")
  fileName <- paste0("https://evds2.tcmb.gov.tr/service/evds/series=", series,
                     "&startDate=", startDate, "&endDate=", endDate,
                     "&type=csv")
  if (!missing(freq)) fileName <- paste0(fileName, "&frequency=", freq)
  if (!missing(aggType)) fileName <- paste0(fileName, "&aggregationTypes=", aggType)
  data <- CBRT_fread(fileName, CBRTKey)
  data[, c("UNIXTIME") := NULL]
  setnames(data, "Tarih", "time")
  onames <- names(data)
  onames <- gsub("_", ".", onames)
  setnames(data, onames)
  data[, time := formatTime(time)]
  if (exists("YEARWEEK", where = data)) data[, YEARWEEK := NULL]
  # Remove all missing row
  nvar <- ncol(data) - 1
  if (na.rm == TRUE) data <- data[!(rowSums(is.na(data)) == nvar)]
  return(data)
}


#' Downloading data groups
#'
#' Downloads all data series of a data group
#'
#' @param group Code for the data group.
#' @param CBRTKey Your personal CBRT access key.
#' @param freq Numeric, the frequency of the data series. If not defined, the default
#' (the highest possible frequency) will be used. The frequencies are as follows:
#' \describe{
#'   \item{1}{Day}
#'   \item{2}{Work day}
#'   \item{3}{Week}
#'   \item{4}{Biweekly}
#'   \item{5}{Month}
#'   \item{6}{Quarter}
#'   \item{7}{Six months}
#'   \item{8}{Year}
#' }
#' If a frequency level lower than the default is used, the data will be aggregated
#' by using the default method for that data group (for example, if monthly data
#' are download for weekly series).
#' @param startDate The beginning date for data series (DD-MM-YYYY).
#' @param endDate The ending date for data series (DD-MM-YYYY). If not defined, the default
#' (the latest available) will be used.
#' @param na.rm Logical variable to drop all missing dates.
#' @param verbose TRUE turns on status and information messages to the console.
#'
#' @return a data.table object
#'
#' @examples
#' \dontrun{
#' myData <- getDataGroup("bie_dbafod")
#' }
#'
#' @export
#' @import data.table
getDataGroup <-
function(group, CBRTKey = myCBRTKey, freq, startDate = "01-01-1950", endDate, na.rm = TRUE, verbose = TRUE)
{
  YEARWEEK <- NULL
  if (missing(endDate)) endDate <- format.Date(Sys.Date(), "%d-%m-%Y")
  if (grepl("^[0-9]{4}-[0-9]{2}-[0-9]{2}$", startDate)) startDate <- format.Date(as.Date(startDate, format = "%Y-%m-%d"), "%d-%m-%Y")
  if (grepl("^[0-9]{4}-[0-9]{2}-[0-9]{2}$", endDate)) endDate <- format.Date(as.Date(endDate, format = "%Y-%m-%d"), "%d-%m-%Y")
  fileName <- paste0("https://evds2.tcmb.gov.tr/service/evds/datagroup=", group,
                    "&startDate=", startDate, "&endDate=", endDate,
                    "&type=csv")
  if (!missing(freq)) fileName <- paste0(fileName, "&frequency=", freq)
  # Aggregation type is the default type for data groups
  data <- CBRT_fread(fileName, CBRTKey)
  data[, c("UNIXTIME") := NULL]
  setnames(data, "Tarih", "time")
  data[, time := formatTime(time)]
  onames <- names(data)
  onames <- gsub("_", ".", onames)
  setnames(data, onames)
  if (exists("YEARWEEK", where = data)) data[, YEARWEEK := NULL]
  # Remove all missing row
  nvar <- ncol(data) - 1
  if (na.rm == TRUE) data <- data[!(rowSums(is.na(data)) == nvar)]
  # Print series names if verbose
  if (verbose && exists("allCBRTSeries")) print(showSeriesNames(group))
  return(data)
}


#' Changing characters to ASCII
#'
#' Changes non-ASCII characters to ASCII
#'
#' @param x String to be modifies
#'
#' @return Modified string
#'
#' @keywords internal
changeASCII <-
function(x)
{
  x <- gsub("\u011e", "G", x, ignore.case = FALSE)
  x <- gsub("\u011f", "g", x, ignore.case = FALSE)
  x <- gsub("\u015e", "S", x, ignore.case = FALSE)
  x <- gsub("\u015f", "s", x, ignore.case = FALSE)
  x <- gsub("\u0130", "I", x, ignore.case = FALSE)
  x <- gsub("\u0131", "i", x, ignore.case = FALSE)
  x <- gsub("\u00dc", "U", x, ignore.case = FALSE)
  x <- gsub("\u00fc", "u", x, ignore.case = FALSE)
  x <- gsub("\u00d6", "O", x, ignore.case = FALSE)
  x <- gsub("\u00f6", "o", x, ignore.case = FALSE)
  x <- gsub("\u00c7", "C", x, ignore.case = FALSE)
  x <- gsub("\u00f6", "c", x, ignore.case = FALSE)
  return(x)
}


#' CBT API function
#'
#' Reading the data from the CBT server
#'
#' @param fileName URL for API
#'
#' @param CBRTKey Individual key for CB API
#'
#' @return The data from CBRT
#'
#' @keywords internal
#' @import data.table
#' @import curl
CBRT_fread <-
function(fileName, CBRTKey)
{
  h <- curl::new_handle(verbose = FALSE)
  curl::handle_setheaders(h, "Key" = CBRTKey)
  x <- curl::curl_fetch_memory(fileName, handle = h)
  curl::handle_reset(h)
  if (x$status_code == 200) {
    x <- fread(rawToChar(x$content), encoding = "UTF-8", na.strings = c("ND", "null"))
    return(x)
    }
    else {
    stop(paste0("Error in connecting to the CBRT server. Error code ", x$status_code))
    }
}

