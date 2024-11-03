#' Data categories
#'
#' A dataset containing the list of all data categories in the CBRT dataset
#'
#' @format A data table with 23 rows and 2 variables:
#' \describe{
#'   \item{cid}{Category ID}
#'   \item{topic}{Topic}
#' }
"allCBRTCategories"

#' Data groups
#'
#' A dataset containing the list of all data groups in the CBRT dataset
#'
#' @format A data table with 323 rows and 10 variables:
#' \describe{
#'   \item{cid}{Category ID}
#'   \item{groupCode}{Data group code (used for downloading the data)}
#'   \item{groupName}{Name of the data group}
#'   \item{freq}{Time series frequency code}
#'   \item{source}{Data source}
#'   \item{sourceLink}{URL of the data source}
#'   \item{revisionPolicy}{Revision policy for the data group}
#'   \item{firstDate}{The beginning date for the data}
#'   \item{lastDate}{The end date for the data}
#'   \item{appLing}{URL}
#' }
"allCBRTGroups"


#' Data series
#'
#' A dataset containing the list of all data series in the CBRT dataset
#'
#' @format A data table frame with 22,243 rows and 12 variables:
#' \describe{
#'   \item{cid}{Category ID}
#'   \item{topic}{Topic}
#'   \item{groupCode}{Data group code}
#'   \item{groupName}{Name of the data group}
#'   \item{freq}{Time series frequency code}
#'   \item{seriesCode}{Data series code (used for downloading the data)}
#'   \item{seriesName}{Name of the data series}
#'   \item{start}{Starting date, DD-MM-YYYY}
#'   \item{end}{Ending date, DD-MM-YYYY}
#'   \item{aggMethod}{Data aggregation method}
#'   \item{freqname}{Time series frequency}
#'   \item{tag}{Tages (keywords)}
#' }
"allCBRTSeries"

#' Frequenciess
#'
#' A dataset containing the list of frequencies
#'
#' @format A data table frame with 8 rows and 4 variables:
#' \describe{
#'   \item{freq}{Frequency code}
#'   \item{tfreq}{Frequency code (internal use)}
#'   \item{FreqEng}{Frequency name (English)}
#'   \item{FreqTr}{Frequency name (Turkish)}
#' }
"CBRTfreq"

#' Aggregation methods
#'
#' A dataset containing the list of aggregation methods
#'
#' @format A data table frame with 6 rows and 2 variables:
#' \describe{
#'   \item{Code}{Aggregation code}
#'   \item{Aggregation}{Aggregation method}
#' }
"CBRTagg"

