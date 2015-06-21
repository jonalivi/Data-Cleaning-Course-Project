## run_analysis.R

library(data.table)
library(stringr)
library(reshape2)

# download the data and make a timestamp -------------------------------------------

## if (!file.exists("./data"))
##       dir.create("./data")
## url <- "https://d396qusza40orc.cloudfront.net/getdata%2Fprojectfiles%2FUCI%20HAR%20Dataset.zip"
## download.file(url, destfile="./data/ADL.zip",mode="wb")
## if (!file.exists("./data/tlabel"))
##       file.create("./data/tlabel")
## tlabel <- file("./data/tlabel","w")
## cat(date(), file=tlabel)
## close(tlabel)

# unzip the data ---------------------------------------------------------------

## unzip("./data/ADL.zip",exdir="./data")
datapath <- "./data/UCI HAR Dataset"

# find all variable names having mean' or 'std' --------------------------------

features <- fread(file.path(datapath,"features.txt"))
# logical vector of all necessary columns
col.present <- grepl("mean|std",features[[2]],
                     ignore.case=TRUE)
# names of all the columns
col.names <- grep("mean|std",features[[2]],
                  value=TRUE,ignore.case=TRUE)
rm("features")

# function to read each set of data separately ---------------------------------
## returns a data.table with variables values
## merged with corresponding subjects and activities

## Parameters: 
## * vars_fname - a file.path to the data file
## * subj_fname - a file.path to the file with data on subjects
## * act_fname - a file.pth to the file containing activities data

readData <- function(vars_fname,
                     subj_fname,
                     act_fname) {
      
      # read the variables data as a string vector
      x <- file.path(vars_fname)
      tempcontent <- readLines(x)
      # remove leading spaces
      for (i in 1:length(tempcontent))
            tempcontent[i] <- str_trim(tempcontent[i])
      # replace double spaces with single ones
      tempcontent <- gsub("  "," ", tempcontent)
      # concatenate all the resulting strings
      # and read them as a data.table, choosing the right columns
      datatable <- fread(input=paste(tempcontent,collapse='\n'),sep=' ',      
                         select=which(col.present))
      rm("tempcontent")
      
      # give names to the columns ----------------------------------------------
      setnames(datatable,1:length(col.names),col.names)
      
      # add subject ids as the first column ------------------------------------
      
      subjects <- fread(subj_fname)
      datatable <- cbind(subjects, datatable)
      setnames(datatable,1,"subject")
      
      datatable
}

# read and process the test data ------------------------------------------------

testpath <- file.path(datapath,"test")
datatable <- readData(vars_fname=file.path(testpath,"X_test.txt"),
                      subj_fname=file.path(testpath,"subject_test.txt"),
                      act_fname=file.path(testpath,"y_test.txt"))

# read and process the training data -------------------------------------------


trainpath <- file.path(datapath,"train")
traintable <- readData(vars_fname=file.path(trainpath,"X_train.txt"),
                       subj_fname=file.path(trainpath,"subject_train.txt"),
                       act_fname=file.path(trainpath,"y_train.txt"))

# combine all rows in the two datasets -----------------------------------------

datatable <- rbind(datatable,traintable)
rm("traintable")

# add the activities column -----------------------------------------------------

## read and combine the activities columns for the two data sets
activities <- fread(file.path(testpath,"y_test.txt"))
activities <- rbind(activities,
                    fread(file.path(trainpath,"y_train.txt")))
## add a row number column to keep the order (or merging will aply sorting)
activities <- cbind(activities,as.integer(rownames(activities)))
setnames(activities,1:2,c("fk","order"))
## read the activity labels
act_voc <- fread(file.path(datapath,"activity_labels.txt"))
## improve readability of the labels
act_voc[[2]] <- tolower(gsub("_"," ",act_voc[[2]]))
setnames(act_voc,1:2,c("fk","labels"))
## merge the activities and labels 
activities <- merge(activities, act_voc, by="fk")
## restore the row order
activities <- setorder(activities,"order")
## add the activity labels column as the first one to the resulting data.table
datatable <- cbind(activities$labels, datatable)
setnames(datatable,1,"activity")
rm("activities")

# make another, tidy table -----------------------------------------------------

tidytable <- copy(datatable)
## choose the activities and subject columns as grouping
tidytable <- melt(tidytable, id=c(1,2))
## find the means for all the chosen variables
tidytable <- dcast(tidytable, activity + subject ~ variable,mean)
## give readable names to all the mean(variable) columns
cnames <- colnames(tidytable)
setnames(tidytable,
         cnames[3:length(cnames)],
         paste("mean(",
               cnames[3:length(cnames)],
               ")",
               sep=""))


# export tidy data to a text file without row naming ---------------------------

write.table(tidytable, "./tidydata.txt",row.names = FALSE)

