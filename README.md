# Trend Analysis for Next Generation Sequencing Data - the website

A tool for trend analysis of Next Generation Sequencing quality data.
This is the website for the Trend Analysis tool. The back-end part, the tool can be found [here](https://github.com/ALuesink/Trend_Analysis_tool "Trend Analysis tool")

## Getting Started
This website requires several R packages:  
* shiny
* shinythemes
* ggplot2
* DT
* RMariaDB
* RMySQL  
To connect to the data, the login data is stored in the .my.cnf file. This file needs to be put in the home directory (/~).  

## Website layout
This website has a simple layout.
At the top op the web page different tabs for the different data.  
The tab Sequencer corresponds with the data directly from the sequencers.  
This data is divided in lane data or sample data.  
Processed data can be found behind tab Processed. This data comes from the pipeline.  
The last tab is Datatables. Here all the data can be found in 3 tables, Sample Sequencer data, Lane Sequencer data and Processed data.  
This data can be filtered and sorted. Columns can be added or removed and the displayed data can be downloaded as a .csv file.  
  
At the left side of the web page there are different filtering options, the date range of the runs and which sequencers and/or lanes are displayed.  
Per parameter there is 1 plot, which is displayed on their own tab. Below the plot is a data table where if you brush the plot the corresponding data is displayed.  

## Updating the website
There are multiple scenarios when the code needs to be changed. At the same time the code of the tool needs to be updated.  
Below is described what needs to be changed for both the website and the tool.  

#### New sequencer
* R-script: add the new sequencer with a corresponding colour and shape
* Python: add the new sequencer to the list Sequencers in config.py

### New parameter
* R-script: add new plot if needed plus add parameter to brush table
* Python:
  * import_data: add parameter to corresponding dictionary
  * upload/.. : add parameter to the insert
* MySQL database: add parameter to the corresponding table

