**********************************************************************************************
* Author: Scott Albrecht
* Date Created: 5/23/2016
* Description: This syntax will group Grainger DMAs into similar test and control
* groups which would be used in the Geographic display test to measure 
* incremental sales of the investment. Any DMAs which will be used in the Q3
* radio marketing or paid search geographic tests will be removed as to not interfere 
* with any of the tests. In addition, very large DMA markets will be removed. We 
* will use the DMA clusters as a starting point for dividing DMAs into test and 
* control groups. We will also consider other measures such as GIS sales and 
* transactions, GIS sales growth, Gcom sales and transactions, and Gcom sales
* growth.
**********************************************************************************************

*Get 24M sales and transaction information.
GET FILE = '/usr/spss/userdata/model_files/201604_Apr_merged_model_file.sav'
   /KEEP account DUNSNMBR CUSTSTAT ZIPCODE SALES12X SALES24X TRANS12X TRANS24X GCOM12X GCOM24X GCOMN12X GCOMN24X mrospend.
CACHE.
EXE.

DATASET NAME AF.
DATASET ACTIVATE AF.

SELECT IF(CUSTSTAT = 'A').
EXE.

*Replace missing DUNS numbers with the opposite of the account #.
ALTER TYPE dunsnmbr(A10).
ALTER TYPE account(A9).

IF(dunsnmbr = '000000000') dunsnmbr = CONCAT('-',account).
EXE.

ALTER TYPE account(F10.0).

*Aggregate the data by DUNSNMBR and zipcode.
DATASET DECLARE DUNS.

AGGREGATE
  /OUTFILE='DUNS'
  /BREAK=dunsnmbr ZIPCODE
  /SALES12X=SUM(SALES12X) 
  /SALES24X=SUM(SALES24X) 
  /TRANS12X=SUM(TRANS12X) 
  /TRANS24X=SUM(TRANS24X) 
  /GCOM12X=SUM(GCOM12X) 
  /GCOM24X=SUM(GCOM24X) 
  /GCOMN12X=SUM(GCOMN12X) 
  /GCOMN24X=SUM(GCOMN24X) 
  /mrospend=MAX(mrospend)
  /NUM_ACCTS=N.

DATASET ACTIVATE DUNS.

*Check to see if zipcodes are duplicated for the same location.
COMPUTE Unique_Zip = 1.
IF(dunsnmbr = LAG(dunsnmbr) AND ZIPCODE <> LAG(ZIPCODE)) Unique_Zip = 0.
FORMATS Unique_Zip(F1.0).
EXE.

FREQ Unique_Zip.

*De-duplicate the zip codes.
AGGREGATE
   /OUTFILE = *
   MODE ADDVARIABLES
   /BREAK = dunsnmbr
   /Dup_Zip = MIN(Unique_Zip).

DELETE VARIABLES Unique_Zip.

*Split the dataset.
DATASET COPY DUNSU.
DATASET COPY DUNSD.

DATASET ACTIVATE DUNSD.

SELECT IF(Dup_Zip = 0).
EXE.

*Sort the cases by total sales.
COMPUTE TS = SUM(SALES12X,SALES24X).
EXE.

SORT CASES BY dunsnmbr(A) TS(D).

AGGREGATE
   /OUTFILE = *
   MODE ADDVARIABLES
   /BREAK = dunsnmbr
   /ZIP2 = FIRST(ZIPCODE).

DELETE VARIABLES ZIPCODE.

RENAME VARIABLES ZIP2 = ZIPCODE.

DATASET DECLARE DUNSD2.

AGGREGATE
   /OUTFILE = 'DUNSD2'
   /BREAK = dunsnmbr ZIPCODE
   /SALES12X=SUM(SALES12X) 
   /SALES24X=SUM(SALES24X) 
   /TRANS12X=SUM(TRANS12X) 
   /TRANS24X=SUM(TRANS24X) 
   /GCOM12X=SUM(GCOM12X) 
   /GCOM24X=SUM(GCOM24X) 
   /GCOMN12X=SUM(GCOMN12X) 
   /GCOMN24X=SUM(GCOMN24X) 
   /mrospend=MAX(mrospend)
   /NUM_ACCTS=SUM(NUM_ACCTS).

DATASET CLOSE DUNSD.
DATASET ACTIVATE DUNSD2.

DATASET ACTIVATE DUNSU.

SELECT IF(Dup_Zip = 1).
EXE.

DELETE VARIABLES Dup_Zip.

ADD FILES
   /FILE = *
   /FILE = 'DUNSD2'
   /BY dunsnmbr ZIPCODE.
EXE.

DATASET CLOSE DUNSD2.
DATASET CLOSE DUNS.
DATASET ACTIVATE DUNSU.

DATASET NAME DUNS.

*Open the mapping file of zipcode to DMA.
GET FILE = '/usr/spss/userdata/LWhately/Media/2015 Media Test/dma_zip_xref_mine.sav'
   /KEEP ZipCode DMA.
CACHE.
EXE.

DATASET NAME ZTD.

*Add in a flag for whether the DMA contains a branch which is closing in 2016. 
GET FILE = '/usr/spss/userdata/Albrecht/Branch Closure Impact/Branch Master List.sav'
   /KEEP BRANCH_ID BR_ZIP Original_Branch Future_Closure.
CACHE.
EXE.

DATASET NAME BR_CL.
DATASET ACTIVATE BR_CL.

SELECT IF(Original_Branch = 1 AND Future_Closure = 1).
EXE.

STRING ZIPCODE(A5).
COMPUTE ZIPCODE = SUBSTR(BR_ZIP,1,5).
EXE.

DELETE VARIABLES BRANCH_ID TO Original_Branch.

SORT CASES BY ZIPCODE(A).

*Merge the DMA for each customer using the zipcode.
DATASET ACTIVATE DUNS.

ALTER TYPE ZIPCODE(A5).
EXE.

SORT CASES BY ZIPCODE(A).

MATCH FILES
   /FILE = *
   /TABLE = 'ZTD'
   /TABLE = 'BR_CL'
   /BY ZIPCODE.
EXE.

DATASET CLOSE ZTD.
DATASET CLOSE BR_CL.
DATASET ACTIVATE DUNS.

RECODE Future_Closure(MISSING = 0).
EXE.

*Open the file containing the list of Grainger DMAs.
GET FILE = '/usr/spss/userdata/Albrecht/PPC Geo/DMA_Clusters_Final.sav'
   /KEEP DMA_imputed final_cluster
   /RENAME DMA_imputed = DMA.
CACHE.
EXE.

DATASET NAME DMA.
DATASET ACTIVATE DMA.

SORT CASES BY DMA(A).

DATASET ACTIVATE DUNS.

SORT CASES BY DMA(A).

MATCH FILES
   /FILE = *
   /TABLE = 'DMA'
   /BY DMA.
EXE.

DATASET CLOSE DMA.
DATASET ACTIVATE DUNS.

*Aggregate the file by DMA and cluster.
DATASET DECLARE DMAM.

AGGREGATE
   /OUTFILE = 'DMAM'
   /BREAK = DMA final_cluster
   /SALES12X=SUM(SALES12X) 
   /SALES24X=SUM(SALES24X) 
   /TRANS12X=SUM(TRANS12X) 
   /TRANS24X=SUM(TRANS24X) 
   /GCOM12X=SUM(GCOM12X) 
   /GCOM24X=SUM(GCOM24X) 
   /GCOMN12X=SUM(GCOMN12X) 
   /GCOMN24X=SUM(GCOMN24X) 
   /mrospend=SUM(mrospend)
   /NUM_ACCTS=SUM(NUM_ACCTS)
   /Branch_Closure_2016 = MAX(Future_Closure).

DATASET CLOSE AF.
DATASET CLOSE DUNS.

DATASET ACTIVATE DMAM.

*Remove the record for the unknown DMA.
SELECT IF(DMA <> '' AND DMA <> 'INVALID ZIP' AND DMA <> 'PUERTO RICO' AND DMA <> 'NON-DMA' AND DMA <> 'UNKNOWN').
EXE.

ALTER TYPE final_cluster(F2.0).

*Create a variable for each DMA cluster.
VECTOR DMA_PG(30,F1.0).

LOOP #i = 1 TO 30.

   COMPUTE DMA_PG(#i) = 0.

END LOOP.

IF(final_cluster = 1) DMA_PG1 = 1.
IF(final_cluster = 2) DMA_PG2 = 1.
IF(final_cluster = 3) DMA_PG3 = 1.
IF(final_cluster = 4) DMA_PG4 = 1.
IF(final_cluster = 5) DMA_PG5 = 1.
IF(final_cluster = 6) DMA_PG6 = 1.
IF(final_cluster = 7) DMA_PG7 = 1.
IF(final_cluster = 8) DMA_PG8 = 1.
IF(final_cluster = 9) DMA_PG9 = 1.
IF(final_cluster = 10) DMA_PG10 = 1.
IF(final_cluster = 11) DMA_PG11 = 1.
IF(final_cluster = 12) DMA_PG12 = 1.
IF(final_cluster = 13) DMA_PG13 = 1.
IF(final_cluster = 14) DMA_PG14 = 1.
IF(final_cluster = 15) DMA_PG15 = 1.
IF(final_cluster = 16) DMA_PG16 = 1.
IF(final_cluster = 17) DMA_PG17 = 1.
IF(final_cluster = 18) DMA_PG18 = 1.
IF(final_cluster = 19) DMA_PG19 = 1.
IF(final_cluster = 20) DMA_PG20 = 1.
IF(final_cluster = 21) DMA_PG21 = 1.
IF(final_cluster = 22) DMA_PG22 = 1.
IF(final_cluster = 23) DMA_PG23 = 1.
IF(final_cluster = 24) DMA_PG24 = 1.
IF(final_cluster = 25) DMA_PG25 = 1.
IF(final_cluster = 26) DMA_PG26 = 1.
IF(final_cluster = 27) DMA_PG27 = 1.
IF(final_cluster = 28) DMA_PG28 = 1.
IF(final_cluster = 29) DMA_PG29 = 1.
IF(final_cluster = 30) DMA_PG30 = 1.
EXE.

*Compute an ID variable for each DMA.
COMPUTE DMA_ID = $CASENUM.
FORMATS DMA_ID(F1.0).
EXE.

*Open the file containing PPC attributed visits, revenue, and orders.
 * GET FILE = '/usr/spss/userdata/Albrecht/PPC Geo/PPC Metrics by Month and Zip.sav'.
 * CACHE.
 * EXE.

 * DATASET NAME PPC.
 * DATASET ACTIVATE PPC.

*Add in the DMA to remove any invalid zip codes or zip codes in uknown DMAs.
 * SORT CASES BY ZIPCODE(A).

 * MATCH FILES
   /FILE = *
   /TABLE = 'ZTD'
   /BY ZIPCODE.
 * EXE.

 * DATASET CLOSE ZTD.
 * DATASET ACTIVATE PPC.

*Remove records from March 2015 and any records for which we have an invalid or uknown zipcode.
 * COMPUTE #dash = INDEX(ZIPCODE,'-').
 * SELECT IF(YM > 201503 AND #dash = 0 AND DMA <> '' AND DMA <> 'INVALID ZIP' AND DMA <> 'PUERTO RICO' AND DMA <> 'NON-DMA' AND DMA <> 'UNKNOWN').
 * EXE.

*Aggregate data to get the monthly mean and standard deviation for each zipcode.
 * AGGREGATE
   /OUTFILE = *
   MODE ADDVARIABLES
   /BREAK = ZIPCODE
   /Visit_Median = MEDIAN(Visits)
   /Visit_Mean = MEAN(Visits)
   /Visit_SD = SD(Visits)
   /Rev_Median = MEDIAN(Revenue)
   /Rev_Mean = MEAN(Revenue)
   /Rev_SD = SD(Revenue).

 * EXAMINE Visit_SD
   /PLOT HISTOGRAM BOXPLOT
   /PERCENTILES(5,10,25,50,75,90,95,99).

 * EXAMINE Rev_SD
   /PLOT HISTOGRAM BOXPLOT
   /PERCENTILES(5,10,25,50,75,90,95,99).

*Flag the zipcodes which need the visits or revenue cleansed.
 * COMPUTE Clean_Visits = Visit_SD >= 350.
 * FORMATS Clean_Visits(F1.0).

 * COMPUTE Clean_Rev = Rev_SD >= 15000.
 * FORMATS Clean_Rev(F1.0).
 * EXE.

 * FREQ Clean_Visits Clean_Rev.

*Flag the individual records which need to be replaced.
 * COMPUTE Update_Visits = (Clean_Visits = 1 AND (Visits >= (Visit_Mean + Visit_SD))).
 * FORMATS Update_Visits(F1.0).

 * COMPUTE Update_Rev = (Update_Visits = 1 OR (Clean_Rev = 1 AND (Revenue >= (Rev_Mean + Rev_SD)))).
 * FORMATS Update_Rev(F1.0).
 * EXE.

 * FREQ Update_Visits Update_Rev.

*Compute new visit and revenue metrics.
 * COMPUTE Visits2 = Visits.
 * IF(Update_Visits = 1) Visits2 = Visit_Median.

 * COMPUTE Revenue2 = Revenue.
 * IF(Update_Rev = 1) Revenue2 = Rev_Median.
 * EXE.

*Aggregate the data by DMA.
 * DATASET DECLARE DMA_PPC.

 * AGGREGATE
   /OUTFILE = 'DMA_PPC'
   /BREAK = DMA
   /PPC_Visits = SUM(Visits2)
   /PPC_Revenue = SUM(Revenue2).

 * DATASET ACTIVATE DMAM.

 * MATCH FILES
   /FILE = *
   /TABLE = 'DMA_PPC'
   /BY DMA.
 * EXE.

 * DATASET CLOSE DMA_PPC.
 * DATASET CLOSE PPC.
 * DATASET ACTIVATE DMAM.

SAVE OUTFILE = '/usr/spss/userdata/Albrecht/Display Geo/DMA MDS Metrics.sav'.

*Save the data as a tab delimited file to import into R.
SAVE TRANSLATE OUTFILE='/usr/spss/userdata/Albrecht/Display Geo/DMA MDS Metrics.dat'
  /TYPE=TAB
  /MAP
  /REPLACE
  /FIELDNAMES
  /CELLS=VALUES.
