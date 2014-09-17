# SxPicklist

Pulls survey results from remote server through API in JSON format.

#### Notes
+ API is HTML and JSON based using survey IDs to define data sources
+ Data pulled in using JSON and stripped into dataframes
+ Data frames are manipulated (merged, ordered, filtered)
+ Output files are generated based on pre-defined criteria
+ Functional for both 2014 and 2014/2015 studies.

#### Next Steps

1. Simplify debugging by inserting failsafe code (if statements with errors out to file)
2. Clean up and create 2 versions; 64-bit and 32-bit R compatible
3. Clean up date selection to <code>IF</code> statement.  
    Ex. <code>IF</code> function attribute = 1, current date; 
    <code>IF</code> function attribute = 2, defined date; 
    <code>IF</code> function attribute = 3, most recent date; etc.


