# SxPicklist

#### Purpose
Pulls survey results from remote server through API in JSON format.  

Script is run nightly (via .bat file & Windows Task Scheduler) to generate a list that guides sample collection the following day.  The file is e-mailed to necessary staff, also via .bat (blat) file.

#### Notes
+ API is HTML and JSON based. Survey IDs (like tokens) are used to define data sources
+ Data pulled in using JSON and stripped into dataframes
+ Data frames are manipulated (merged, ordered, filtered)
+ Output files are generated based on pre-defined criteria
+ Functional for both 2014 and 2014/2015 studies.
+ Unified versions for cross platform compatibility

#### Next Steps

1. Simplify debugging by inserting failsafe code (<code>if</code> statements with errors out to file)
2. Clean up date selection to <code>IF</code> statement.  
    Ex. <code>IF</code> function attribute = 1, current date; 
    <code>IF</code> function attribute = 2, defined date; 
    <code>IF</code> function attribute = 3, most recent date; etc.


