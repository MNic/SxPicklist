#'Script for testing import of study daily symptoms from remote survey API
#'The following function generates a file containing a list of subjects whose
#'survey derived symptom score changes over a defined period of time (closeday,
#'farday) have increased by a defined limit (Sxlim).  The file is formatted to 
#'include symptom score reports across a date range (winclose, winfar) in the
#'output.  
#'
#'If no subjects are selected due to no subjects meeting the symptom change
#'limit; a .csv file will be exported containing only "Pick list is EMPTY".

#'Install Packages if not already in .Rprofile

#   if(!"jsonlite" %in% rownames(installed.packages())) install.packages("jsonlite") 
#   if(!"plyr" %in% rownames(installed.packages())) install.packages("plyr") 
#   if(!"reshape2" %in% rownames(installed.packages())) install.packages("reshape2") 
#   if(!"httr" %in% rownames(installed.packages())) install.packages("httr")
#   if(!"RCurl" %in% rownames(installed.packages())) install.packages("RCurl")
#   if(!"devtools" %in% rownames(installed.packages())) install.packages("devtools")
#   if(!"data.table" %in% rownames(installed.packages())) install.packages("data.table")
#   require(data.table)
#   require(jsonlite)
#   require(plyr)
#   require(reshape2)
#   require(httr)
#   require(RCurl)
#   require(devtools)

#'Read JSON format export of results from Daily Symptom Score survey JSON 
#'URL/HTML Query:  Includes Request, User, Token, Format, Version and 
#'SurveyID parameters

#'.Rprofile contains appropriate login information and direction to Survey

url <- paste("https://survey.qualtrics.com/WRAPI/ControlPanel/api.php?Request=",
             request,"&User=",user,"&Token=",token,"&Format=",format,"&Version=",
             version,"&SurveyID=",svid, sep="")

txt <- fromJSON(readLines(url))     #readLines() not needed on Mac. see below
jsonstrip <- lapply(txt, unlist)    #Unlist/Strip the JSON file
df <- ldply(jsonstrip)              #convert JSON export to dataframe

#:::::::::::::::::::::::  IMPORTANT!!!  :::::::::::::::::::::::::::
#'Script isn't functional on Mac/64bit.  readLines() requires Windows
#'RCurl is the suggested replacement, but behaves differently.  readLines()
#'into unlist -> ldply produces a dataframe of columns in which each column
#'contains one piece of information (tidy?).  RCurl produces a dataframe, but
#'Many of the columns are columns of lists (multiple lists per column) and are
#'difficult to work with.

#'Generate supplementary data not provided by test data export.
#'This is for testing purposes only.  Live data will have these fiels
#'populated.

#   df$ExternalDataReference <- as.character(seq(1:20))
#   df$EmailAddress <- paste(df$ExternalDataReference, "@test.edu", sep="")

#Supply error text for failure output file.
  errortxt <- "Pick List is EMPTY"

#Create function for study 'sick' prediction based on self-reported symptoms from file
sick_id_qual <- function(doi1, closeday = 0, farday = -6, winclose = 0, winfar = -14, Sxlim = 4){

    # Define variables different than the defaults for testing
    #       closeday = 0 
    #       farday = -6 
    #       winclose = 0 
    #       winfar = -8 
    #       Sxlim = 2
    #          doi1 = "2014-08-26"    
  
    # Subset and keep fields of interest from the export
      df <-  df[,c("ExternalDataReference", "EmailAddress", "StartDate", "Symptoms.Sum")]
    
    #'Create 'StartDate' variable as date, original stored as character
      df$dfdate <- as.Date(df$StartDate)
      
    ###Alternate Date Selection Methods:
    # Comment out all but the intended date selection method.
    
    ##Picks highest date from each individual
    # dlimit <- seq.Date(max(df$dfdate)+closeday,max(df$dfdate)+farday, "-1 day")
  
    ##Picks current date
    # dlimit <- seq.Date(unique(df$dfdate[df$dfdate == Sys.Date()])+closeday, 
    #                    unique(df$dfdate[df$dfdate == Sys.Date()])+farday, "-1 day")
    
    ##Picks defined date
    #' <<- is key, otherwise the environment for doi gets restricted to the current function and
    #' ddply can't find it.
      doi <<- as.Date(doi1)
      dlimit <- seq.Date(unique(df$dfdate[df$dfdate %in% doi])+closeday,
                       unique(df$dfdate[df$dfdate %in% doi])+farday, "-1 day")
    
    #'Subset data to match only dates in dlimit
      dlimitdf <- df[df$dfdate %in% dlimit,]
    
    #'Find max symptoms in the previous dlimit days.  Many warnings will be produced here.  
    #'It's due to many cases of missing data causing max() to divide by 0.  Can squelch or
    #'fix at a later date; result is not affected.
      premax <- ddply(dlimitdf, .(ExternalDataReference), summarise, 
                    maxpresx = max(Symptoms.Sum, na.rm=TRUE))
    
    #'Find max symptoms for current date
      currentdatesx <- ddply(df, .(ExternalDataReference), summarise, 
                           maxdate = doi, 
                           maxsxf = max(Symptoms.Sum[dfdate %in% doi], na.rm=TRUE))
      
    #'Merge maximum symptom result from previous days with symptoms on the day of interest
    #'Replace the values divided by zero (-Inf) with 0
      final <- merge(premax, currentdatesx, by="ExternalDataReference") #merge datasets by subjectID
      final$maxpresx[final$maxpresx == -Inf] <- 0  #replace -Inf with 0
    
    #Calculate difference in most recent day Sx and max from previous 7 days
      final$sxdif <- as.numeric(final$maxsxf) - as.numeric(final$maxpresx)
    
    #Set symptom differential limit & Create Contact List
      pick <- na.exclude(final[final$sxdif > Sxlim,])
      dfpick <- merge(df, pick, by= intersect(c("ExternalDataReference", "maxdate"), 
                                            c("ExternalDataReference", "dfdate")))
    
    #'Define Window of previous days to show, default is -1 to -8
    #'Subset df keeping only dates in window
      window <- seq.Date(doi+winclose, doi+winfar, "-1 day")
      windf <- df[df$dfdate %in% window,]
    
    #'merge dataframe of subjects with sxdif > Sxlim and original symptom date information defined by 
    #'the window.  Creates a pull list with previous days and symptoms included
      pickwind <- merge(pick, windf, by="ExternalDataReference")
      names(pickwind)
    
  if (length(pickwind[,1]>0)) {
    
      #'cast pick list into 'tidy' format to generate report
        ctest <- dcast(pickwind, ExternalDataReference + maxdate + maxpresx + maxsxf + sxdif ~ dfdate,
               value.var="Symptoms.Sum")
        
      #subset the date columns from ctest for ease of reading/formatting
        check <- ctest[,names(ctest) %in% as.character(window)]
      #rchk <- rev(check)
        names(ctest)
    
      #generate report with records in decreasing order by symptom difference (sxdif)
        report <- cbind(ctest[,1:2], check, ctest[,3:5])
        ordered_report <- report[with(report, order(-sxdif)),]
    
      #'Rename specific columns.  Due to potential variability of date/sx columns, only known output
      #'columns are renamed.
        setnames(ordered_report, old=c("ExternalDataReference", "maxdate", "maxpresx", "maxsxf", 
                                   "sxdif"), new = c("study_id", "Day0_date", "Max_PreSx", 
                                                     "Day0_Sx", "Sx_Delta"))
      #'Write result to file
        write.csv(file=paste("./SSPicklists/","SSpicklist","_",format(Sys.time(), "%d%b%Y_%H%M%S"),".csv", sep=""), 
              ordered_report)
      
  } else stop("Pick List is Empty", write.csv(errortxt, file="test.csv"))  
}


