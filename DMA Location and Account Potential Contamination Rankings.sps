GET FILE = '/usr/spss/userdata/LWhately/dunsnmbr_dunsBusiness_xref.sav'
   /KEEP DUNSNMBR dunsBusiness N_in_prnt N_in_glbl.
CACHE.
EXE.

DATASET NAME DUNS_BUS.

*Open the latest DUNS file.
GET FILE = '/usr/spss/userdata/d_and_b/duns_files/201603_DUNS_DOMESTIC.sav'
   /KEEP DUNSNMBR DUNSNAME ZIPCODE mrospend mro_decile.
CACHE.
EXE.

DATASET NAME DUNS_ZIP.
DATASET ACTIVATE DUNS_ZIP.

DATASET COPY LOC_ZIP.
DATASET ACTIVATE LOC_ZIP.

RENAME VARIABLES DUNSNAME = Location_Name ZIPCODE = Location_ZIP.

DATASET ACTIVATE DUNS_BUS.

MATCH FILES
   /FILE = *
   /TABLE = 'LOC_ZIP'
   /BY DUNSNMBR.
EXE.

DATASET CLOSE LOC_ZIP.
DATASET ACTIVATE DUNS_ZIP.

RENAME VARIABLES DUNSNMBR = dunsBusiness DUNSNAME = Bus_Name ZIPCODE = Bus_ZIP.

DELETE VARIABLES mrospend mro_decile.

DATASET ACTIVATE DUNS_BUS.

SORT CASES BY dunsBusiness(A).

MATCH FILES
   /FILE = *
   /TABLE = 'DUNS_ZIP'
   /BY dunsBusiness.
EXE.

DATASET CLOSE DUNS_ZIP.
DATASET ACTIVATE DUNS_BUS.

*Open the current analytics file to get the sales and number of active customer accounts.
GET FILE = '/usr/spss/userdata/model_files/201605_May_merged_model_file.sav'
   /KEEP account CUSTSTAT dunsnmbr SALES12X.
CACHE.
EXE.

DATASET NAME AF.
DATASET ACTIVATE AF.

SELECT IF(CUSTSTAT = 'A').
EXE.

ALTER TYPE account(A10) dunsnmbr(A10).

IF(RTRIM(dunsnmbr) = '000000000') dunsnmbr = CONCAT('-',LTRIM(RTRIM(account))).
EXE.

DATASET DECLARE CUST_LOC.

AGGREGATE
   /OUTFILE = 'CUST_LOC'
   /BREAK = dunsnmbr
   /SALES12X = SUM(SALES12X)
   /Active_Accounts = N.

DATASET ACTIVATE DUNS_BUS.

ALTER TYPE DUNSNMBR(A10).

SORT CASES BY DUNSNMBR(A).

MATCH FILES
   /FILE = *
   /TABLE = 'CUST_LOC'
   /BY DUNSNMBR.
EXE.

DATASET CLOSE CUST_LOC.
DATASET CLOSE AF.

DATASET ACTIVATE DUNS_BUS.

RECODE SALES12X(MISSING = 0) /Active_Accounts(MISSING = 0).
EXE.

ALTER TYPE DUNSNMBR(A9).

*Open the file containing the zipcode to DMA mappings.
GET FILE = '/usr/spss/userdata/LWhately/Media/2015 Media Test/dma_zip_xref_mine.sav'
   /KEEP ZipCode DMA.
CACHE.
EXE.

DATASET NAME ZTD.
DATASET ACTIVATE ZTD.

DATASET COPY LOC_ZTD.
DATASET ACTIVATE LOC_ZTD.

RENAME VARIABLES ZipCode = Location_ZIP DMA = Loc_DMA.

DATASET ACTIVATE DUNS_BUS.

SORT CASES BY Location_Zip(A).

MATCH FILES
   /FILE = *
   /TABLE = 'LOC_ZTD'
   /BY Location_Zip.
EXE.

DATASET CLOSE LOC_ZTD.
DATASET ACTIVATE ZTD.

RENAME VARIABLES ZipCode = Bus_ZIP DMA = Bus_DMA.

DATASET ACTIVATE DUNS_BUS.

SORT CASES BY Bus_ZIP(A).

MATCH FILES
   /FILE = *   
   /TABLE = 'ZTD'
   /BY Bus_ZIP.
EXE.

DATASET CLOSE ZTD.
DATASET ACTIVATE DUNS_BUS.

SAVE OUTFILE = '/usr/spss/userdata/Albrecht/Display Geo/Location to Business Possible DMA Contamination.sav'.

*Remove the record for locations with unknown DMAs.
SELECT IF(Loc_DMA <> '' AND Loc_DMA <> 'INVALID ZIP' AND Loc_DMA <> 'PUERTO RICO' AND Loc_DMA <> 'NON-DMA' AND Loc_DMA <> 'UNKNOWN' AND
                 Bus_DMA <> '' AND Bus_DMA <> 'INVALID ZIP' AND Bus_DMA <> 'PUERTO RICO' AND Bus_DMA <> 'NON-DMA' AND Bus_DMA <> 'UNKNOWN').

*Compute a variable to show whether the DMA of the customer location is different from that of the business (indicating a multi-site location).
COMPUTE Multi_DMA = (Loc_DMA <> Bus_DMA).
FORMATS Multi_DMA(F1.0).

*Compute a variable to show whether a location is a customer location(purchased in the last 24 months).
COMPUTE Cust_Loc = (Active_Accounts > 0).
FORMATS Cust_Loc(F1.0).
EXE.

FREQ Multi_DMA Cust_Loc.

FILTER BY Cust_Loc.

FREQ Multi_DMA.

*Aggregate the count of locations, accounts, sales, and MRO potential in each DMA which may be at risk for contamination.
FILTER OFF.

DATASET DECLARE DMA_CONTAM.

AGGREGATE
   /OUTFILE = 'DMA_CONTAM'
   /BREAK = Loc_DMA Multi_DMA
   /Active_Accounts = SUM(Active_Accounts)
   /Cust_Locations = SUM(Cust_Loc)
   /Total_Locations = N
   /SALES12X = SUM(SALES12X)
   /MRO = SUM(mrospend).

DATASET ACTIVATE DMA_CONTAM.

*Divide the data into multi-DMA and single DMA datasets.
DATASET COPY SDMA.
DATASET ACTIVATE SDMA.

SELECT IF(Multi_DMA = 0).
EXE.

RENAME VARIABLES Active_Accounts = SDMA_Act_Accts Cust_Locations = SDMA_Cust_Loc Total_Locations = SDMA_Loc SALES12X = SDMA_S12X MRO = SDMA_MRO.

DELETE VARIABLES Multi_DMA.

DATASET ACTIVATE DMA_CONTAM.

SELECT IF(Multi_DMA = 1).
EXE.

RENAME VARIABLES Active_Accounts = MDMA_Act_Accts Cust_Locations = MDMA_Cust_Loc Total_Locations = MDMA_Loc SALES12X = MDMA_S12X MRO = MDMA_MRO.

DELETE VARIABLES Multi_DMA.

DATASET ACTIVATE SDMA.

MATCH FILES
   /FILE = *
   /TABLE = 'DMA_CONTAM'
   /BY Loc_DMA.
EXE.

DATASET CLOSE DMA_CONTAM.
DATASET ACTIVATE SDMA.
DATASET NAME DMAS.

*Compute a variable to show total active accounts, customer locations, locations, sales, and MRO in each DMA.
COMPUTE Total_Act_Accts = SUM(SDMA_Act_Accts + MDMA_Act_Accts).
COMPUTE Act_Accts_Contam_Pct = ( (MDMA_Act_Accts / Total_Act_Accts) * 100).
FORMATS Act_Accts_Contam_Pct(PCT5.2).

COMPUTE Total_Cust_Loc = SUM(SDMA_Cust_Loc + MDMA_Cust_Loc).
COMPUTE Cust_Loc_Contam_Pct = ( (MDMA_Cust_Loc / Total_Cust_Loc) * 100).
FORMATS Cust_Loc_Contam_Pct(PCT5.2).

COMPUTE Total_Loc = SUM(SDMA_Loc + MDMA_Loc).
COMPUTE Loc_Contam_Pct = ( (MDMA_Loc / Total_Loc) * 100).
FORMATS Loc_Contam_Pct(PCT5.2).

COMPUTE SALES12X = SUM(SDMA_S12X + MDMA_S12X).
COMPUTE Sales_Contam_Pct = ( (MDMA_S12X / SALES12X) * 100).
FORMATS Sales_Contam_Pct(PCT5.2).

COMPUTE MRO = SUM(SDMA_MRO + MDMA_MRO).
COMPUTE MRO_Contam_Pct = ( (MDMA_MRO / MRO) * 100).
FORMATS MRO_Contam_Pct(PCT5.2).
EXE.

/*LOOK AT THE CONTAMINATION SPECIFIC TO TEST AND CONTROL DMAs USING DUNS HQ INFORMATION*/.

DATASET ACTIVATE DUNS_BUS.

*Compute a variable to show whether the location is in a test, control, or other DMA.
COMPUTE Loc_Group = -1.
IF(ANY(Loc_DMA,'ALBANY, GA','WILMINGTON','SANTABARBRA - SANMAR - SANLUOB','JONESBORO','TOPEKA','CASPER - RIVERTON','AMARILLO',
                           'TALLAHASSEE - THOMASVILLE','LUBBOCK','TRAVERSE CITY - CADILLAC')) Loc_Group = 0.
IF(ANY(Loc_DMA,'TERRE HAUTE','BOISE','MEDFORD - KLAMATH FALLS','BEAUMONT - PORT ARTHUR','MONROE - EL DORADO','GRAND JUNCTION - MONTROSE',
                           'RENO','ROCHESTR - MASON CITY - AUSTIN','BINGHAMTON','CHICO - REDDING')) Loc_Group = 1.
FORMATS Loc_Group(F1.0).
VALUE LABELS Loc_Group -1 'Non-Target' 0 'Control' 1 'Test'.

*Compute a variable to show whether the HQ DMA is in a test, control, or other DMA.
COMPUTE Bus_Group = -1.
IF(ANY(Bus_DMA,'ALBANY, GA','WILMINGTON','SANTABARBRA - SANMAR - SANLUOB','JONESBORO','TOPEKA','CASPER - RIVERTON','AMARILLO',
                           'TALLAHASSEE - THOMASVILLE','LUBBOCK','TRAVERSE CITY - CADILLAC')) Bus_Group = 0.
IF(ANY(Bus_DMA,'TERRE HAUTE','BOISE','MEDFORD - KLAMATH FALLS','BEAUMONT - PORT ARTHUR','MONROE - EL DORADO','GRAND JUNCTION - MONTROSE',
                           'RENO','ROCHESTR - MASON CITY - AUSTIN','BINGHAMTON','CHICO - REDDING')) Bus_Group = 1.
FORMATS Bus_Group(F1.0).
VALUE LABELS Bus_Group -1 'Non-Target' 0 'Control' 1 'Test'.
EXE.

DATASET DECLARE TC_CONTAM.

AGGREGATE
   /OUTFILE = 'TC_CONTAM'
   /BREAK = Loc_Group Bus_Group
   /Active_Accounts = SUM(Active_Accounts)
   /Cust_Locations = SUM(Cust_Loc)
   /Total_Locations = N
   /SALES12X = SUM(SALES12X)
   /MRO = SUM(mrospend).

DATASET ACTIVATE TC_CONTAM.

/*NOW LOOK AT THE CONTAMINATION SPECIFIC TO TEST AND CONTROL DMAs USING CONTACT ZIP CODE AND ACCOUNT ZIP CODE INFORMATION*/.

*Open the file containing contacts, their assigned account, and their zipcode.
GET FILE = '/usr/spss/userdata/contact_data/201605_May_contact_model_file.sav'
   /KEEP INDV_ID BSN_ID INDV_ZIP_AD BSN_ZIP_AD SALES12X
   /RENAME BSN_ID = account INDV_ZIP_AD = INDV_ZIP BSN_ZIP_AD = BSN_ZIP.
CACHE.
EXE.

DATASET NAME CF.
DATASET ACTIVATE CF.

ALTER TYPE INDV_ID(F10.0) account(F10.0) INDV_ZIP(A5) BSN_ZIP(A5).

SORT CASES BY account(A).

*Open the most recent analytic file to get the account's zipcode.
GET FILE = '/usr/spss/userdata/model_files/201605_May_merged_model_file.sav'
   /KEEP account ZIPCODE SALES12X
   /RENAME ZIPCODE = ACCT_ZIP SALES12X = ACCT_S12X.
CACHE.
EXE.

DATASET NAME AF.

DATASET ACTIVATE CF.

MATCH FILES
   /FILE = *
   /TABLE = 'AF'
   /BY account.
EXE.

DATASET CLOSE AF.
DATASET ACTIVATE CF.

ALTER TYPE ACCT_ZIP(A5).

*Check to see if the account zipcode in the contact file always matches the zipcode in the model file.
COMPUTE Same_Zip = (BSN_ZIP = ACCT_ZIP).
FORMATS Same_Zip(F1.0).
EXE.

FREQ Same_Zip.

*Get the total number of contacts for each account.
AGGREGATE
   /OUTFILE = *
   MODE ADDVARIABLES
   /BREAK = account
   /Total_Contacts = N.

*Get the account sales per contact.
COMPUTE ACCT_S12X_PC = (ACCT_S12X / Total_Contacts).
EXE.

*Get the DMAs for each zipcode.
GET FILE = '/usr/spss/userdata/LWhately/Media/2015 Media Test/dma_zip_xref_mine.sav'
   /KEEP ZipCode DMA.
CACHE.
EXE.

DATASET NAME ZTD.
DATASET ACTIVATE ZTD.

DATASET COPY CNT_ZTD.
DATASET ACTIVATE CNT_ZTD.

RENAME VARIABLES ZipCode = INDV_ZIP DMA = INDV_DMA.

DATASET ACTIVATE CF.

SORT CASES BY INDV_ZIP(A).

MATCH FILES
   /FILE = *
   /TABLE = 'CNT_ZTD'
   /BY INDV_ZIP.
EXE.

DATASET CLOSE CNT_ZTD.
DATASET ACTIVATE ZTD.

RENAME VARIABLES ZipCode = ACCT_ZIP DMA = ACCT_DMA.

DATASET ACTIVATE CF.

SORT CASES BY ACCT_ZIP(A).

MATCH FILES
   /FILE = *   
   /TABLE = 'ZTD'
   /BY ACCT_ZIP.
EXE.

DATASET CLOSE ZTD.
DATASET ACTIVATE CF.

*Save the resulting file.
SAVE OUTFILE = '/usr/spss/userdata/Albrecht/Display Geo/Contact to Account Possible DMA Contamination.sav'.

*Remove the record for contacts with unknown DMAs.
SELECT IF(INDV_DMA <> '' AND INDV_DMA <> 'INVALID ZIP' AND INDV_DMA <> 'PUERTO RICO' AND INDV_DMA <> 'NON-DMA' AND INDV_DMA <> 'UNKNOWN' AND
                 ACCT_DMA <> '' AND ACCT_DMA <> 'INVALID ZIP' AND ACCT_DMA <> 'PUERTO RICO' AND ACCT_DMA <> 'NON-DMA' AND ACCT_DMA <> 'UNKNOWN').

*Compute a variable to show whether the location is in a test, control, or other DMA.
COMPUTE INDV_Group = -1.
IF(ANY(INDV_DMA,'ALBANY, GA','WILMINGTON','SANTABARBRA - SANMAR - SANLUOB','JONESBORO','TOPEKA','CASPER - RIVERTON','AMARILLO',
                           'TALLAHASSEE - THOMASVILLE','LUBBOCK','TRAVERSE CITY - CADILLAC')) INDV_Group = 0.
IF(ANY(INDV_DMA,'TERRE HAUTE','BOISE','MEDFORD - KLAMATH FALLS','BEAUMONT - PORT ARTHUR','MONROE - EL DORADO','GRAND JUNCTION - MONTROSE',
                           'RENO','ROCHESTR - MASON CITY - AUSTIN','BINGHAMTON','CHICO - REDDING')) INDV_Group = 1.
FORMATS INDV_Group(F1.0).
VALUE LABELS INDV_Group -1 'Non-Target' 0 'Control' 1 'Test'.

*Compute a variable to show whether the HQ DMA is in a test, control, or other DMA.
COMPUTE ACCT_Group = -1.
IF(ANY(ACCT_DMA,'ALBANY, GA','WILMINGTON','SANTABARBRA - SANMAR - SANLUOB','JONESBORO','TOPEKA','CASPER - RIVERTON','AMARILLO',
                           'TALLAHASSEE - THOMASVILLE','LUBBOCK','TRAVERSE CITY - CADILLAC')) ACCT_Group = 0.
IF(ANY(ACCT_DMA,'TERRE HAUTE','BOISE','MEDFORD - KLAMATH FALLS','BEAUMONT - PORT ARTHUR','MONROE - EL DORADO','GRAND JUNCTION - MONTROSE',
                           'RENO','ROCHESTR - MASON CITY - AUSTIN','BINGHAMTON','CHICO - REDDING')) ACCT_Group = 1.
FORMATS ACCT_Group(F1.0).
VALUE LABELS ACCT_Group -1 'Non-Target' 0 'Control' 1 'Test'.
EXE.

DATASET DECLARE CNT_CONTAM.

AGGREGATE
   /OUTFILE = 'CNT_CONTAM'
   /BREAK = INDV_Group ACCT_Group
   /Total_Contacts = N
   /INDV_S12X = SUM(SALES12X)
   /ACCT_S12X = SUM(ACCT_S12X_PC).

DATASET ACTIVATE CNT_CONTAM.
