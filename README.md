
This file provides description of the Data Cleaning Course Project (DCCP) and its prerequisites.


The project contains the following files:
* `README.md` 
* `run_analysis.R` (executable part of the project, outputting the tidy data set)
* `CodeBook.md` (a description of all the variables in the resulting dataset)



The code in the DCCP uses the data collected for Human Activity Recognition Using Smartphones. (See the description at [1].) The data are initially split into several distinct files and do not meet the 'tidy data' principles: the values of the variables from the same observation are kept in different datasets. 

## Prerequisites

For the script to run successfully, you must have the `data` folder in your working directory. This folder must contain [the zip archive with the data](https://d396qusza40orc.cloudfront.net/getdata%2Fprojectfiles%2FUCI%20HAR%20Dataset.zip). You can download and unpack it into the `data` folder manually or execute the following script:

```
if (!file.exists("./data"))
      dir.create("./data")
url <- "https://d396qusza40orc.cloudfront.net/getdata%2Fprojectfiles%2FUCI%20HAR%20Dataset.zip"
## don't use the 'curl' method if you are on Windows!
download.file(url, destfile="./data/ADL.zip",method='curl',mode="wb")
## make an easily readable label saying when the data were requested
if (!file.exists("./data/tlabel"))
      file.create("./data/timelabel")
tlabel <- file("./data/timelabel","w")
cat(date(), file=tlabel)
close(tlabel)
unzip("./data/ADL.zip",exdir="./data")
```

The script uses the following files from the archive:
* `activity_labels.txt`
* `features.txt`
* `test/subject_test.txt`
* `test/X_test.txt`
* `test/y_test.txt`
* `train/subject_train.txt`
* `train/X_train.txt`
* `train/y_train.txt`

## Description of the input

The data consist of two parts: the first part, the training set, contains 7352 observations of 561 variables and is kept in the `train/X_train.txt`, and the second one, the test set, contains 2947 observations of the same 561 variables and is kept in the `test/X_test.txt`. In addition, there are two pairs of files containing the subject ids for each observation (these are `train/subject_train.txt` and `test/subject_test.txt`, respectively) and the activity ids for each observation (`train/y_train.txt` and `test/y_test.txt`, respectively). `features.txt` contains the names of all the 561 variables of the feature vector, which correspond to the labels of the columns of the `train/X_train.txt` and `test/X_test.txt`. The `activity_labels.txt` maps the activitiy ids to their human-readable names. 

## Description of the run_analysis.R script

The script combines all the data described above in order to make them compliant with the tidy data[2] principles: one table for similar observations, descriptive column names, no unnecessary tables. 

First the script finds in the `features.txt` those variables having `mean` or `std` in their names (they correspond to mean and standard deviation values for measurements or are based on them), 86 in total. 

The `readData` function is used twice to read the two data sets into a `data.table`, one by one, selecting only the columns corresponding to the chosen variables. (As the double values in the `train/X_train.txt` and `test/X_test.txt` data files are fixed-width and some of them have the minus sign and others don't, values are separated with one or two spaces, so, to parse the data into a `data.table`, extra spaces are removed.) The function also `cbind`s the column containing the subject ids (from the `train/subject_train.txt` and `test/subject_test.txt`) as the first column. The vector of the variables' names is used to name the columns. The two `data.table`s are combined by means of `rbind`, giving the `datatable` object with 10299 rows and 87 columns.

The activities ids are read into new `data.table`s from `train/y_train.txt` and `test/y_test.txt` and combined with `rbind`. (An extra column containing row numbers is added to preserve the original row ordering later.) The activity names are read from `activity_labels.txt` and merged with this `data.table` by the activity id values. After restoring initial row ordering (`merge` function sorts rows automatically), this `data.table` gives a column with activity names in the right order. It is `cbind`ed to the `datatable`, described in the previous paragraph, and the resulting dataset contains 10299 rows and 88 columns, including `subject`, `activity` and 86 other columns, each of them being or using some mean or standard deviation and having an appropriate name.

A copy of the `datatable`, `tidytable`, is made. `tidytable` is made molten: `subject` and `activity` become id variables, and the rest are measure variables. By means of `dcast` function, average values are calculated for each measure variable and each distinct pair of `activity` and `subject` values. The columns are renamed to `mean(<measure variable name>)`.

## Description of the output

The resulting `tidytable` contains 180 rows and 88 columns. It is exported to the file `./data/tidydata.txt` with the `write.table` function.



## References:

1.[Davide Anguita, Alessandro Ghio, Luca Oneto, Xavier Parra and Jorge L. Reyes-Ortiz. A Public Domain Dataset for Human Activity Recognition Using Smartphones. 21th European Symposium on Artificial Neural Networks, Computational Intelligence and Machine Learning, ESANN 2013. Bruges, Belgium 24-26 April 2013.](http://archive.ics.uci.edu/ml/datasets/Human+Activity+Recognition+Using+Smartphones)

2.[Hadley Wickham. Tidy Data. Journal of Statistical Software, Vol. 59, Issue 10, Sep 2014.](http://www.jstatsoft.org/v59/i10/paper)

