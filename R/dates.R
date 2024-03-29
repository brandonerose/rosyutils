#' @export
age <- function(dob, age.day = lubridate::today(), units = "years", floor = TRUE) {
  calc.age = lubridate::interval(dob, age.day) / lubridate::duration(num = 1, units = units)
  if (floor) return(as.integer(floor(calc.age)))
  return(calc.age)
}
#' @export
is_date <- function(date) {
  OUT <- grepl("^\\d{4}-\\d{2}-\\d{2}$|^\\d{4}-\\d{2}$|^\\d{4}$", date)
  if(OUT){
    OUT2 <- date %>% strsplit(split = "-") %>% unlist()
    year <- OUT2[[1]]
    check_date <- year
    if(length(OUT2)==1){
      check_date<-check_date %>% paste0("-01")
      OUT2[[2]] <- "01"
    }
    if(length(OUT2)==2){
      check_date<-check_date %>% paste0("-01")
      OUT2[[3]] <- "01"
    }
    year <- year %>% as.integer()
    month <- OUT2[[2]] %>% as.integer()
    day <- OUT2[[3]] %>% as.integer()
    this_year <-
      OUT <- month>=1&&month<=12&&day>=1&&day<=31&&year>=1900&&year<=lubridate::year(Sys.Date())
  }
  OUT
}
#' @export
is_date_full <- function(date) {
  grepl("^\\d{4}-\\d{2}-\\d{2}$", date)
}
#' @export
extract_dates <- function(input_string) {
  # Regular expression pattern to match different date formats
  date_patterns <- c(
    "\\b(0?[1-9]|1[0-2])/(0?[1-9]|[12][0-9]|3[01])/(\\d{2})\\b", # MM/DD/YY
    "\\b(0?[1-9]|1[0-2])/(0?[1-9]|[12][0-9]|3[01])/(\\d{4})\\b", # MM/DD/YYYY
    "\\b(0?[1-9]|1[0-2])-(0?[1-9]|[12][0-9]|3[01])-(\\d{2})\\b", # MM-DD-YY
    "\\b(0?[1-9]|1[0-2])-(0?[1-9]|[12][0-9]|3[01])-(\\d{4})\\b"  # MM-DD-YYYY
  )
  # Initialize an empty list to store matches
  matched_dates <- list()
  # Extract date matches using str_extract_all for each pattern
  for (pattern in date_patterns) {
    matches <- stringr::str_extract_all(input_string, pattern)
    matched_dates <- matched_dates %>% append(matches)
  }
  return(unlist(matched_dates))
}
#' @export
extract_dates2 <- function(input_string) {
  # Regular expression pattern to match different date formats
  date_patterns <- c(
    "\\d{4}-(0[1-9]|1[0-2])-(0[1-9]|[12][0-9]|3[01])"
  )#"\\d{4}-(0?[1-9]|1[0-2])-(0?[1-9]|[12][0-9]|3[01])"
  # Initialize an empty list to store matches
  matched_dates <- list()
  # Extract date matches using str_extract_all for each pattern
  for (pattern in date_patterns) {
    matches <- stringr::str_extract_all(input_string, pattern)
    matched_dates <- matched_dates %>% append(matches)
  }
  if(length(matched_dates[[1]])==0)return(NA)
  return(unlist(matched_dates))
}
#' @export
delete_dates2 <- function(input_string){
  # Extract valid dates and remove the rest of the text
  date_patterns <- c(
    "\\d{4}-(0[1-9]|1[0-2])-(0[1-9]|[12][0-9]|3[01])"
  )
  gsub(paste(date_patterns, collapse = "|"), "", input_string)
}
#' @export
convert_dates <- function(input_string) {
  if(!is.na(input_string)){
    input_string <- input_string %>% trimws()
    if(input_string!=""){
      dates <- extract_dates(input_string)
      output_string <- input_string
      for (pattern in dates) {
        pattern <- gsub("-","/",pattern)
        split_pattern <- pattern %>% strsplit("/") %>% unlist()
        month <- split_pattern[[1]] %>% as.integer()%>% stringr::str_pad(2,"left",0)
        day <- split_pattern[[2]] %>% as.integer()%>% stringr::str_pad(2,"left",0)
        year <- split_pattern[[3]] %>% as.integer()
        if(stringr::str_length(year)%in%c(1,2)){
          year <-year %>% stringr::str_pad(2,"left",0)
          if(year>=0&&year<25){
            year <- paste0("20",year)
          }
          if(year>=50&&year<=99){
            year <- paste0("19",year)
          }
        }
        output_string <- gsub(pattern, paste0(year,"-",month,"-",day), output_string, perl = TRUE)
      }
      return(output_string)
    }
  }
}
#' @export
date_imputation<-function(dates_in,date_imputation){
  #followup add min max
  z <- sapply(dates_in,is_date) %>% as.logical()
  x<-which(z&!is_date_full(dates_in))
  y<-which(!z)
  date_out<-dates_in
  if(length(y)>0){
    date_out[y] <- NA
  }
  if(length(x)>0){
    if(missing(date_imputation)) date_imputation <- NULL
    if(is.null(date_imputation)){
      date_out[x]<- NA
    }
    if(!is.null(date_imputation)){
      date_out[x] <- dates_in[x] %>% sapply(function(date){
        admiral::impute_dtc_dt(
          date,
          highest_imputation = "M", # "n" for normal date
          date_imputation = date_imputation
          # min_dates = min_dates %>% lubridate::ymd() %>% as.list(),
          # max_dates = max_dates %>% lubridate::ymd() %>% as.list()
        )
      })
    }
  }
  date_out
}
