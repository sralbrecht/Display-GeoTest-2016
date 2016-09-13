*Read in data for week 1.
GET DATA
  /TYPE=TXT
  /FILE="/usr/spss/userdata/Albrecht/Display Geo/Weekly Updates/Week 1/Grainger_Weekly_DMA_Spend-20160815-20160821.csv"
  /DELCASE=LINE
  /DELIMITERS=","
  /QUALIFIER = '"'
  /ARRANGEMENT=DELIMITED
  /FIRSTCASE=2
  /IMPORTCASE=ALL
  /VARIABLES = daydate A10 dma_id F5.0 dma A26 total_spend F10.2 control_flag F1.0 test_flag F1.0.
CACHE.
EXE.

DATASET NAME WK1.

*Read in data for week 2.
GET DATA
  /TYPE=TXT
  /FILE="/usr/spss/userdata/Albrecht/Display Geo/Weekly Updates/Week 2/Grainger_Weekly_DMA_Spend-20160822-20160828.csv"
  /DELCASE=LINE
  /DELIMITERS=","
  /QUALIFIER = '"'
  /ARRANGEMENT=DELIMITED
  /FIRSTCASE=2
  /IMPORTCASE=ALL
  /VARIABLES = daydate A10 dma_id F5.0 dma A26 total_spend F10.2 control_flag F1.0 test_flag F1.0.
CACHE.
EXE.

DATASET NAME WK3.

*Read in data for week 3.
GET DATA
  /TYPE=TXT
  /FILE="/usr/spss/userdata/Albrecht/Display Geo/Weekly Updates/Week 3/Grainger_Weekly_DMA_Spend-20160829-20160904.csv"
  /DELCASE=LINE
  /DELIMITERS=","
  /QUALIFIER = '"'
  /ARRANGEMENT=DELIMITED
  /FIRSTCASE=2
  /IMPORTCASE=ALL
  /VARIABLES = daydate A10 dma_id F5.0 dma A26 total_spend F10.2 control_flag F1.0 test_flag F1.0.
CACHE.
EXE.

DATASET NAME WK3.

*Read in data for week 4.
GET DATA
  /TYPE=TXT
  /FILE="/usr/spss/userdata/Albrecht/Display Geo/Weekly Updates/Week "+
    "4/Grainger_Weekly_DMA_Spend-20160905-20160911.csv"
  /DELCASE=LINE
  /DELIMITERS=","
  /QUALIFIER='"'
  /ARRANGEMENT=DELIMITED
  /FIRSTCASE=2
  /IMPORTCASE=ALL
  /VARIABLES = daydate A10 dma_id F5.0 dma A26 creative A28 total_spend F10.2 control_flag F1.0 test_flag F1.0.
CACHE.
EXE.

DATASET NAME WK4.
DATASET ACTIVATE WK4.

DELETE VARIABLES creative.

*Add all dates together.
DATASET ACTIVATE WK1.

ADD FILES
   /FILE = *
   /FILE = 'WK2'
   /FILE = 'WK3'
   /FILE = 'WK4'.
EXE.

DATASET CLOSE WK2.
DATASET CLOSE WK3.
DATASET CLOSE WK4.

DATASET ACTIVATE WK1.
DATASET NAME SPEND.

*Select only the records which are a test or control.
SELECT IF(control_flag = 1 OR test_flag = 1).
EXE.

SORT CASES BY daydate(A) test_flag(A) dma(A).

FREQ dma.

MEANS total_spend BY test_flag
   /CELLS SUM.



