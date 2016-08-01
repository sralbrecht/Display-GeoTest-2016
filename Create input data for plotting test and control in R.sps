*Open the file containing the mapping of zipcodes to DMAs.
GET FILE = '/usr/spss/userdata/LWhately/Media/2015 Media Test/dma_zip_xref_mine.sav'
   /KEEP ZipCode DMA.
CACHE.
EXE.

DATASET NAME ZTD.
DATASET ACTIVATE ZTD.

SORT CASES BY DMA(A).

*Open the file containing the DMAs and the flag for test/control group.
GET FILE = '/usr/spss/userdata/Albrecht/Display Geo/DMA MDS Metrics.sav'
   /KEEP DMA_ID DMA.
CACHE.
EXE.

DATASET NAME TC.

*Create a variable to show which group each DMA falls into.
COMPUTE TC = 0.
IF(ANY(DMA_ID,186,23,119,16,128,73,157,161,20,39)) TC = 1.
IF(ANY(DMA_ID,3,206,170,96,188,29,7,184,114,189)) TC = 2.
VALUE LABELS TC 1 'Test' 2 'Control'.
FORMATS TC(F1.0).
EXE.

FREQ TC.

DELETE VARIABLES DMA_ID.

*Join the test and control flag to the Zipcode mapping.
DATASET ACTIVATE ZTD.

MATCH FILES
   /FILE = *
   /TABLE = 'TC'
   /BY DMA.
EXE.

DATASET CLOSE TC.
DATASET ACTIVATE ZTD.

*Replace missing test/control flags with 0.
RECODE TC(MISSING = 0).

*Create a flag to show the zipcode is a Grainger zipcode.
COMPUTE GIS_Zip = 1.
FORMATS GIS_Zip(F1.0).
EXE.

RENAME VARIABLES Zipcode = region.

*Save the resulting file as a tab delimited.
SAVE TRANSLATE OUTFILE='/usr/spss/userdata/Albrecht/Display Geo/ZIP_TO_DMA_DISP.dat'
  /TYPE=TAB
  /MAP
  /REPLACE
  /FIELDNAMES
  /CELLS=VALUES.
