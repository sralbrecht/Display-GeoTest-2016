*Select GIS sales by account and zipcode for the dates we would like.
GET DATA 
  /TYPE=ODBC 
  /CONNECT='DSN=Teradata;DB=PRD_DWH_VIEW;PORT=1025;DBCNL=10.4.165.29;UID=spss;PWD=$-<~*x#N3@!/-!!+'
  /SQL='SELECT '+
             '  CU.CUSTOMER, CU.ZZIPCD5 ZIPCODE, CU.CREATEDON CREATE_DATE, CPD.FIRST_PURCH_DT FPD, ' +
            '   A.ORDERS JUL_ORDERS, A.SALES JUL_SALES, B.ORDERS AUG_ORDERS, B.SALES AUG_SALES, C.ORDERS SEP_ORDERS, C.SALES SEP_SALES  '+
           'FROM PRD_DWH_VIEW.Customer_V CU ' +
           'LEFT JOIN PRD_DWH_VIEW.CUSTOMER_PURCH_DATES_V CPD ' +
              'ON CU.CUSTOMER = CPD.CUSTOMER ' +
           'LEFT JOIN (SELECT SIA.SOLD_TO CUSTOMER, COUNT(DISTINCT SIA.S_ORD_NUM) ORDERS, SUM(SIA.SUBTOTAL_2) SALES '+
                             'FROM PRD_DWH_VIEW.Sales_Invoice_V SIA '+
                             'WHERE '+
                                  '  SIA.ZZCOMFLG = ''Y'' ' +
                                  '  AND SIA.ZORD_DATE >= {d ''2016-07-01''} '+
                                  '  AND SIA.ZORD_DATE <= {d ''2016-07-31''} '+
                              'GROUP BY 1) A ' +
           'ON CU.CUSTOMER = A.CUSTOMER '+
           'LEFT JOIN (SELECT SIB.SOLD_TO CUSTOMER, COUNT(DISTINCT SIB.S_ORD_NUM) ORDERS, SUM(SIB.SUBTOTAL_2) SALES '+
                             'FROM PRD_DWH_VIEW.Sales_Invoice_V SIB '+
                             'WHERE '+
                                  '  SIB.ZZCOMFLG = ''Y'' ' +
                                  '  AND SIB.ZORD_DATE >= {d ''2016-08-15''} '+
                                  '  AND SIB.ZORD_DATE <= {d ''2016-08-31''} '+
                              'GROUP BY 1) B ' +
           'ON CU.CUSTOMER = B.CUSTOMER '+
           'LEFT JOIN (SELECT SIC.SOLD_TO CUSTOMER, COUNT(DISTINCT SIC.S_ORD_NUM) ORDERS, SUM(SIC.SUBTOTAL_2) SALES '+
                             'FROM PRD_DWH_VIEW.Sales_Invoice_V SIC '+
                             'WHERE '+
                                  '  SIC.ZZCOMFLG = ''Y'' ' +
                                  '  AND SIC.ZORD_DATE >= {d ''2016-09-01''} '+
                                  '  AND SIC.ZORD_DATE <= {d ''2016-09-11''} '+
                              'GROUP BY 1) C ' +
           'ON CU.CUSTOMER = C.CUSTOMER '+
           'WHERE CU.ZZIPCD5 <> '''' AND ' +
                         'CU.ACCNT_GRP = ''0001'' '.
CACHE.
EXE.

DATASET NAME SLS_BY_AZ.
DATASET ACTIVATE SLS_BY_AZ.

SORT CASES BY CUSTOMER(A) ZIPCODE(A).

*Select Gcom sales by account and zipcode for the dates we would like.
GET DATA 
  /TYPE=ODBC 
  /CONNECT='DSN=Teradata;DB=PRD_DWH_VIEW;PORT=1025;DBCNL=10.4.165.29;UID=spss;PWD=$-<~*x#N3@!/-!!+'
  /SQL='SELECT CU.CUSTOMER, A.ORDERS JUL_ORDERS, A.SALES JUL_SALES, B.ORDERS AUG_ORDERS, B.SALES AUG_SALES, ' +
                         'C.ORDERS SEP_ORDERS, C.SALES SEP_SALES ' +
           'FROM PRD_DWH_VIEW.Customer_V CU ' +
           'LEFT JOIN (SELECT SIA.SOLD_TO CUSTOMER, COUNT(DISTINCT SIA.S_ORD_NUM) ORDERS, SUM(SIA.SUBTOTAL_2) SALES '+
                             'FROM PRD_DWH_VIEW.Sales_Invoice_V SIA '+
                             'WHERE '+
                                  '  SIA.ZZCOMFLG = ''Y'' ' +
                                  '  AND SIA.ZORD_DATE >= {d ''2016-07-01''} '+
                                  '  AND SIA.ZORD_DATE <= {d ''2016-07-31''} '+
                                  '  AND SIA.SALES_OFF = ''E01'' ' +
                              'GROUP BY 1) A ' +
           'ON CU.CUSTOMER = A.CUSTOMER '+
           'LEFT JOIN (SELECT SIB.SOLD_TO CUSTOMER, COUNT(DISTINCT SIB.S_ORD_NUM) ORDERS, SUM(SIB.SUBTOTAL_2) SALES '+
                             'FROM PRD_DWH_VIEW.Sales_Invoice_V SIB '+
                             'WHERE '+
                                  '  SIB.ZZCOMFLG = ''Y'' ' +
                                  '  AND SIB.ZORD_DATE >= {d ''2016-08-15''} '+
                                  '  AND SIB.ZORD_DATE <= {d ''2016-08-31''} '+
                                  '  AND SIB.SALES_OFF = ''E01'' ' +
                              'GROUP BY 1) B ' +
           'ON CU.CUSTOMER = B.CUSTOMER '+
           'LEFT JOIN (SELECT SIC.SOLD_TO CUSTOMER, COUNT(DISTINCT SIC.S_ORD_NUM) ORDERS, SUM(SIC.SUBTOTAL_2) SALES '+
                             'FROM PRD_DWH_VIEW.Sales_Invoice_V SIC '+
                             'WHERE '+
                                  '  SIC.ZZCOMFLG = ''Y'' ' +
                                  '  AND SIC.ZORD_DATE >= {d ''2016-09-01''} '+
                                  '  AND SIC.ZORD_DATE <= {d ''2016-09-11''} '+
                                  '  AND SIC.SALES_OFF = ''E01'' ' +
                              'GROUP BY 1) C ' +
           'ON CU.CUSTOMER = C.CUSTOMER '+
           'WHERE CU.ZZIPCD5 <> '''' AND ' +
                        'CU.ACCNT_GRP = ''0001'' '.
CACHE.
EXE.

DATASET NAME GCSLS_BY_AZ.
DATASET ACTIVATE GCSLS_BY_AZ.

*Rename the variables.
RENAME VARIABLES
   JUL_ORDERS = GC_JUL_ORDERS
   JUL_SALES = GC_JUL_SALES
   AUG_ORDERS = GC_AUG_ORDERS
   AUG_SALES = GC_AUG_SALES
   SEP_ORDERS = GC_SEP_ORDERS
   SEP_SALES = GC_SEP_SALES.
   
SORT CASES BY CUSTOMER(A).

DATASET ACTIVATE SLS_BY_AZ.

MATCH FILES
   /FILE = *
   /TABLE = 'GCSLS_BY_AZ'
   /BY CUSTOMER.
EXE.

DATASET CLOSE GCSLS_BY_AZ.
DATASET ACTIVATE SLS_BY_AZ.

*Select Gcom guest sales by zipcode for the dates we would like.
GET DATA 
  /TYPE=ODBC 
  /CONNECT='DSN=Teradata;DB=PRD_DWH_VIEW;PORT=1025;DBCNL=10.4.165.29;UID=spss;PWD=$-<~*x#N3@!/-!!+'
  /SQL='SELECT DISTINCT SI.SOLD_TO CUSTOMER, SI.ZSHIPZIP, A.ORDERS JUL_ORDERS, A.SALES JUL_SALES, B.ORDERS AUG_ORDERS, B.SALES AUG_SALES, ' +
                                         'C.ORDERS SEP_ORDERS, C.SALES SEP_SALES ' +
            'FROM PRD_DWH_VIEW.Sales_Invoice_V SI ' +
                 'LEFT JOIN (SELECT SIA.SOLD_TO CUSTOMER, SIA.ZSHIPZIP, COUNT(DISTINCT SIA.S_ORD_NUM) ORDERS, SUM(SIA.SUBTOTAL_2) SALES '+
                                   'FROM PRD_DWH_VIEW.Sales_Invoice_V SIA '+
                                   'WHERE '+
                                        '  SIA.ZZCOMFLG = ''Y'' ' +
                                        '  AND SIA.ZORD_DATE >= {d ''2016-07-01''} '+
                                        '  AND SIA.ZORD_DATE <= {d ''2016-07-31''} '+
                                        '  AND SIA.SOLD_TO = ''0222222226'' ' +
                                    'GROUP BY 1,2) A ' +
                 'ON SI.SOLD_TO = A.CUSTOMER AND SI.ZSHIPZIP = A.ZSHIPZIP '+
                 'LEFT JOIN (SELECT SIB.SOLD_TO CUSTOMER, SIB.ZSHIPZIP, COUNT(DISTINCT SIB.S_ORD_NUM) ORDERS, SUM(SIB.SUBTOTAL_2) SALES '+
                                   'FROM PRD_DWH_VIEW.Sales_Invoice_V SIB '+
                                   'WHERE '+
                                        '  SIB.ZZCOMFLG = ''Y'' ' +
                                        '  AND SIB.ZORD_DATE >= {d ''2016-08-15''} '+
                                        '  AND SIB.ZORD_DATE <= {d ''2016-08-31''} '+
                                        '  AND SIB.SOLD_TO = ''0222222226'' ' +
                                    'GROUP BY 1,2) B ' +
                 'ON SI.SOLD_TO = B.CUSTOMER AND SI.ZSHIPZIP = B.ZSHIPZIP '+
                 'LEFT JOIN (SELECT SIC.SOLD_TO CUSTOMER, SIC.ZSHIPZIP, COUNT(DISTINCT SIC.S_ORD_NUM) ORDERS, SUM(SIC.SUBTOTAL_2) SALES '+
                                   'FROM PRD_DWH_VIEW.Sales_Invoice_V SIC '+
                                   'WHERE '+
                                        '  SIC.ZZCOMFLG = ''Y'' ' +
                                        '  AND SIC.ZORD_DATE >= {d ''2016-09-01''} '+
                                        '  AND SIC.ZORD_DATE <= {d ''2016-09-11''} '+
                                        '  AND SIC.SOLD_TO = ''0222222226'' ' +
                                    'GROUP BY 1,2) C ' +
                 'ON SI.SOLD_TO = C.CUSTOMER AND SI.ZSHIPZIP = C.ZSHIPZIP '+
            'WHERE SI.ZORD_DATE >= {d ''2016-07-01''}  AND ' +
                          'SI.ZORD_DATE <= {d ''2016-09-11''} AND ' +
                          'SI.SOLD_TO = ''0222222226'' AND ' +
                          'SI.ZZCOMFLG = ''Y'' '.

CACHE.
EXE.

DATASET NAME GUEST.
DATASET ACTIVATE GUEST.

COMPUTE GC_JUL_ORDERS = JUL_ORDERS.
COMPUTE GC_JUL_SALES = JUL_SALES.
COMPUTE GC_AUG_ORDERS = AUG_ORDERS.
COMPUTE GC_AUG_SALES = AUG_SALES.
COMPUTE GC_SEP_ORDERS = SEP_ORDERS.
COMPUTE GC_SEP_SALES = SEP_SALES.

STRING ZIPCODE(A5).
COMPUTE ZIPCODE=SUBSTR(ZSHIPZIP,1,5).
EXE.

DELETE VARIABLES ZSHIPZIP.

DATASET ACTIVATE SLS_BY_AZ.

ADD FILES
   /FILE = *
   /FILE = 'GUEST'.
EXE.

DATASET CLOSE GUEST.
DATASET ACTIVATE SLS_BY_AZ.

*Sort the cases by Zipcode.
SORT CASES BY ZIPCODE(A).

*Open the file containing the Zipcode to DMA mapping.
GET FILE = '/usr/spss/userdata/LWhately/Media/2015 Media Test/dma_zip_xref_mine.sav'
   /KEEP Zipcode DMA.
CACHE.
EXE.

DATASET NAME ZTD.
DATASET ACTIVATE ZTD.

COMPUTE Group = 0.
IF(ANY(DMA,'BEAUMONT - PORT ARTHUR','BINGHAMTON','BOISE','CHICO - REDDING','GRAND JUNCTION - MONTROSE','MEDFORD - KLAMATH FALLS',
                    'MONROE - EL DORADO','RENO','ROCHESTR - MASON CITY - AUSTIN','TERRE HAUTE')) Group = 1.
IF(ANY(DMA, 'ALBANY, GA','AMARILLO','CASPER - RIVERTON','JONESBORO','LUBBOCK','SANTABARBRA - SANMAR - SANLUOB','TALLAHASSEE - THOMASVILLE',
                     'TOPEKA','TRAVERSE CITY - CADILLAC','WILMINGTON')) Group = 2.
FORMATS Group(F1.0).
VALUE LABELS Group 1 'Test' 2 'Control'.
EXE.

SORT CASES BY ZIPCODE(A).

DATASET ACTIVATE SLS_BY_AZ.

MATCH FILES
   /FILE = *
   /TABLE = 'ZTD'
   /BY ZIPCODE.
EXE.

DATASET CLOSE ZTD.
DATASET ACTIVATE SLS_BY_AZ.

*Compute accounts acquired during each timeframe of interest.
COMPUTE AUG15_ACQ = ( (CREATE_DATE >= DATE.MDY(8,1,2015) AND CREATE_DATE <= DATE.MDY(8,7,2015) ) OR
                                          (CREATE_DATE >= DATE.MDY(8,8,2015) AND CREATE_DATE <= DATE.MDY(8,10,2015) AND MISSING(FPD) = 0) OR 
                                          (CREATE_DATE >= DATE.MDY(8,11,2015) AND CREATE_DATE <= DATE.MDY(8,31,2015) ) ).
IF(DMA = 'RENO' AND CREATE_DATE = DATE.MDY(8,6,2015) AND AUG15_ACQ = 1) AUG15_ACQ = 0.
FORMATS AUG15_ACQ(F1.0).

COMPUTE SEP15_ACQ = (CREATE_DATE >= DATE.MDY(9,1,2015) AND CREATE_DATE <= DATE.MDY(9,30,2015) ).
FORMATS SEP15_ACQ(F1.0).

COMPUTE OCT15_ACQ = (CREATE_DATE >= DATE.MDY(10,1,2015) AND CREATE_DATE <= DATE.MDY(10,31,2015) ).
FORMATS OCT15_ACQ(F1.0).

COMPUTE TP_PY_ACQ = ( (CREATE_DATE >= DATE.MDY(8,15,2015) AND CREATE_DATE <= DATE.MDY(9,11,2015)) ).
FORMATS TP_PY_ACQ(F1.0).

 * COMPUTE CP1_ACQ = ( (CREATE_DATE >= DATE.MDY(6,1,2016) AND CREATE_DATE <= DATE.MDY(6,7,2016)) ).
 * FORMATS CP1_ACQ(F1.0).

 * COMPUTE CP2_ACQ = ( (CREATE_DATE >= DATE.MDY(6,8,2016) AND CREATE_DATE <= DATE.MDY(6,14,2016)) ).
 * FORMATS CP2_ACQ(F1.0).

COMPUTE WK1_ACQ = (CREATE_DATE >= DATE.MDY(8,15,2016) AND CREATE_DATE <= DATE.MDY(8,21,2016) ).
FORMATS WK1_ACQ(F1.0).

COMPUTE WK2_ACQ = ( (CREATE_DATE >= DATE.MDY(8,22,2016) AND CREATE_DATE <= DATE.MDY(8,28,2016)) ).
FORMATS WK2_ACQ(F1.0).

COMPUTE WK3_ACQ = ( (CREATE_DATE >= DATE.MDY(8,29,2016) AND CREATE_DATE <= DATE.MDY(9,4,2016)) ).
FORMATS WK3_ACQ(F1.0).

COMPUTE WK4_ACQ = ( (CREATE_DATE >= DATE.MDY(9,5,2016) AND CREATE_DATE <= DATE.MDY(9,11,2016)) ).
FORMATS WK4_ACQ(F1.0).

 * COMPUTE WK5_ACQ = ( (CREATE_DATE >= DATE.MDY(7,14,2016) AND CREATE_DATE <= DATE.MDY(7,20,2016)) ).
 * FORMATS WK5_ACQ(F1.0).

 * COMPUTE WK6_ACQ = ( (CREATE_DATE >= DATE.MDY(7,21,2016) AND CREATE_DATE <= DATE.MDY(7,27,2016)) ).
 * FORMATS WK6_ACQ(F1.0).

 * COMPUTE WK7_ACQ = ( (CREATE_DATE >= DATE.MDY(7,28,2016) AND CREATE_DATE <= DATE.MDY(8,3,2016)) ).
 * FORMATS WK7_ACQ(F1.0).

 * COMPUTE WK8_ACQ = ( (CREATE_DATE >= DATE.MDY(8,4,2016) AND CREATE_DATE <= DATE.MDY(8,10,2016)) ).
 * FORMATS WK8_ACQ(F1.0).

*Recode missing values to 0.
VECTOR KF = JUL_ORDERS TO WK4_ACQ.

LOOP #i = 1 TO 20.

   IF(MISSING(KF(#i))) KF(#i) = 0.

END LOOP.
EXE.

*Filter out any accounts which were identified as having high avg monthly orders or unstable order history.
GET FILE = '/usr/spss/userdata/Albrecht/Display Geo/Five Year Orders through June16 by Account from TD.sav'
   /KEEP account ZIPCODE Order_Outlier Stable_Order_Outlier.
CACHE.
EXE.

DATASET NAME ORD_OUT.

DATASET ACTIVATE SLS_BY_AZ.

STRING account(A10).
COMPUTE account = CUSTOMER.
EXE.

ALTER TYPE account(F10.0).

SORT CASES BY account(A) ZIPCODE(A).

MATCH FILES
   /FILE = *
   /TABLE = 'ORD_OUT'
   /BY account ZIPCODE.
EXE.

DATASET CLOSE ORD_OUT.
DATASET ACTIVATE SLS_BY_AZ.

RECODE Group(MISSING = 0) /Order_Outlier(MISSING = 0) /Stable_Order_Outlier(MISSING = 0).

COMPUTE Include_Orders = (Order_Outlier = 0 AND Stable_Order_Outlier = 0).
FORMATS Include_Orders(F1.0).
EXE.

*Save the resulting file.
SAVE OUTFILE = '/usr/spss/userdata/Albrecht/Display Geo/Weekly Updates/Week 4/GIS and Gcom Monthly Sales and Acquisitions by Account_MP.sav'.

SELECT IF(Group > 0).
EXE.

FILTER BY Include_Orders.

*Look at acquisitions.
MEANS AUG15_ACQ SEP15_ACQ OCT15_ACQ TP_PY_ACQ WK1_ACQ WK2_ACQ WK3_ACQ WK4_ACQ BY Group
   /CELLS SUM.

*Aggregate the data by DMA and group.
DATASET DECLARE SLS_BY_DMA.

AGGREGATE
   /OUTFILE = 'SLS_BY_DMA'
   /BREAK = DMA Group
   /JUL_ORDERS = SUM(JUL_ORDERS)
   /JUL_SALES = SUM(JUL_SALES)
   /GC_JUL_ORDERS = SUM(GC_JUL_ORDERS)
   /GC_JUL_SALES = SUM(GC_JUL_SALES)
   /AUG_ORDERS = SUM(AUG_ORDERS)
   /AUG_SALES = SUM(AUG_SALES)
   /GC_AUG_ORDERS = SUM(GC_AUG_ORDERS)
   /GC_AUG_SALES = SUM(GC_AUG_SALES)
   /SEP_ORDERS = SUM(SEP_ORDERS)
   /SEP_SALES = SUM(SEP_SALES)
   /GC_SEP_ORDERS = SUM(GC_SEP_ORDERS)
   /GC_SEP_SALES = SUM(GC_SEP_SALES).

DATASET ACTIVATE SLS_BY_DMA.

SORT CASES BY Group(A) DMA(A).

***LOOK AT TOTAL GIS AND GCOM SALES AND ORDERS FOR THE FIRST WEEK OF THE ANALYSIS PERIOD***.

MEANS JUL_ORDERS GC_JUL_ORDERS AUG_ORDERS GC_AUG_ORDERS SEP_ORDERS GC_SEP_ORDERS BY Group
   /CELLS SUM.

