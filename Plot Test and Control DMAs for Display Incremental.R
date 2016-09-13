#Set the working directory
setwd('E://StorageSync//Grainger Files//2016//Projects//PPC Incremental Test//')

#Load the choroplethr package
library(devtools)
#install_github('arilamstein/choroplethrZip@v1.5.0')
library(choroplethrZip)
library(choroplethr)
library(RColorBrewer)
library(plyr)
library(ggplot2)

#Read in all zipcodes and state regions
data(zip.regions)
data(continental_us_states)

#De-duplciate the zipcodes
uniq_zip<-count(zip.regions,c('region'))

#Read in GIS zipcodes with mappings to DMAs
ztd<-read.table('ZIP_TO_DMA_PPCI3.dat',sep='\t',header = TRUE)

#Merge the data together
zc<-merge(uniq_zip,ztd,by = 'region', all.x = TRUE)

#Replace N/A values in the TC column with 0
zc$TC[is.na(zc$TC)]<- 0

#TC should be a factor
zc$TC<-as.factor(zc$TC)

#read in only region and the value we are interested in (test and control)
zcp<-zc[,c(1,4)]

colnames(zcp)[2]<-"value"

choro <- ZipChoropleth$new(zcp)
choro$set_zoom_zip(state_zoom=continental_us_states,county_zoom = NULL,
                   msa_zoom = NULL, zip_zoom = NULL)
choro$ggplot_polygon<-geom_polygon(aes(fill = value),color = NA)
choro$ggplot_scale <- scale_fill_manual(name='value',values = c('gray','blue','red',
                                                                'green','purple'),
                                        drop=FALSE)
choro$render()
