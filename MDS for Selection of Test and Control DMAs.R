#Set the working directory
setwd('E://StorageSync//Grainger Files//2016//Projects//Display//Geographic Test//')

#Load the libraries we need
library(ggplot2)
library(car)

#Read in the data we want to analyze
dma<-read.table('DMA MDS Metrics.dat',sep='\t',header=TRUE)

#Calculate the growth percentage of 12M GIS sales and Gcom Sales
dma$gis_sg_pct<-( (dma$SALES12X - dma$SALES24X) / dma$SALES24X ) * 100
dma$gcom_sg_pct<-( (dma$GCOM12X - dma$GCOM24X) / dma$GCOM24X ) * 100

###MDS STANDARDIZING VARIABLES BEFORE DISTANCE AND ADDING IN BPG VARIABLES###

#Store only the variables we wish to use for the distance calculation
dma_mds<-dma[,c(1:3,14,4,6,8,10,12,45:46,15:44)]

#Scale each of the continuous variables
dma_mds_std<-cbind(dma_mds[,1:4],
                   data.frame(lapply(dma_mds[,c(12:41)],function(x) 
                      recode(x,'0 = - 4; 1 = 4',as.numeric.result = TRUE))),
                    scale(dma_mds[,5:11]))

#Get the distance matrix using euclidean distances
dma_mds_dist<-dist(dma_mds_std[,5:41],method="euclidean")

#Perform PCA on the distance matrix to scale it to two dimensions
dma_mds_fit<-cmdscale(dma_mds_dist,eig=TRUE,k=2)

#Store the results
dma_mds_res<-cbind(dma_mds_std[,c(1:4)],dma_mds_fit$points[,1:2])

colnames(dma_mds_res)[5:6]<-c("Dim1","Dim2")

# Before plotting remove any DMAs in large markets or those which are part of the 
# radio test in Q3 2016 or those which are part of the the PPC test or
# those which are in a market where a branch is closing in 2016
dma_mds_res2<-dma_mds_res[which(dma_mds_res$DMA_ID != 8  & 
                                dma_mds_res$DMA_ID != 9  &
                                dma_mds_res$DMA_ID != 10 &
                                dma_mds_res$DMA_ID != 13 &
                                dma_mds_res$DMA_ID != 21 &
                                dma_mds_res$DMA_ID != 22 &
                                dma_mds_res$DMA_ID != 24 &
                                dma_mds_res$DMA_ID != 27 &
                                dma_mds_res$DMA_ID != 31 &
                                dma_mds_res$DMA_ID != 38 &
                                dma_mds_res$DMA_ID != 43 &
                                dma_mds_res$DMA_ID != 45 &
                                dma_mds_res$DMA_ID != 51 &
                                dma_mds_res$DMA_ID != 52 &
                                dma_mds_res$DMA_ID != 54 &
                                dma_mds_res$DMA_ID != 55 &
                                dma_mds_res$DMA_ID != 60 &
                                dma_mds_res$DMA_ID != 64 &
                                dma_mds_res$DMA_ID != 65 &
                                dma_mds_res$DMA_ID != 67 &
                                dma_mds_res$DMA_ID != 69 &
                                dma_mds_res$DMA_ID != 77 &
                                dma_mds_res$DMA_ID != 79 &
                                dma_mds_res$DMA_ID != 87 &
                                dma_mds_res$DMA_ID != 92 &
                                dma_mds_res$DMA_ID != 98 &
                                dma_mds_res$DMA_ID != 100 &
                                dma_mds_res$DMA_ID != 101 &
                                dma_mds_res$DMA_ID != 105 &
                                dma_mds_res$DMA_ID != 107 &
                                dma_mds_res$DMA_ID != 108 &
                                dma_mds_res$DMA_ID != 112 &
                                dma_mds_res$DMA_ID != 116 &
                                dma_mds_res$DMA_ID != 120 &
                                dma_mds_res$DMA_ID != 122 &
                                dma_mds_res$DMA_ID != 134 &
                                dma_mds_res$DMA_ID != 139 &
                                dma_mds_res$DMA_ID != 146 &
                                dma_mds_res$DMA_ID != 148 &
                                dma_mds_res$DMA_ID != 150 &
                                dma_mds_res$DMA_ID != 158 &
                                dma_mds_res$DMA_ID != 160 &
                                dma_mds_res$DMA_ID != 162 &
                                dma_mds_res$DMA_ID != 168 &
                                dma_mds_res$DMA_ID != 169 &
                                dma_mds_res$DMA_ID != 175 &
                                dma_mds_res$DMA_ID != 176 &
                                dma_mds_res$DMA_ID != 177 &
                                dma_mds_res$DMA_ID != 179 &
                                dma_mds_res$DMA_ID != 187 &
                                dma_mds_res$DMA_ID != 191 &
                                dma_mds_res$DMA_ID != 208 &
                                dma_mds_res$Branch_Closure_2016 == 0),]

#Plot the results
ggplot(dma_mds_res2,aes(Dim1,Dim2)) + 
  geom_point(aes(colour=factor(final_cluster)),size=4,) +
  geom_text(aes(label=DMA_ID,x=Dim1 - 0.1,y=Dim2),size=3) +
  ggtitle("Similarity of DMAs") +
  labs(x="Dim1",y="Dim2")

#Zoom into peer group at the top left of the chart
dma_mds_g1<-dma_mds_res2[which(dma_mds_res2$Dim1 < 1 &
                               dma_mds_res2$Dim2 > 0),]

ggplot(dma_mds_g1,aes(Dim1,Dim2)) + 
  geom_point(aes(colour=factor(final_cluster)),size=4,) +
  geom_text(aes(label=DMA_ID,x=Dim1 - 0.05,y=Dim2),size=3) +
  ggtitle("Similarity of DMAs") +
  labs(x="Dim1",y="Dim2")

#Divide the records into those in the top of the chart and at the bottom
dma_mds_tg<-dma_mds_g1[which(dma_mds_g1$Dim2 > 0.8),]

ggplot(dma_mds_tg,aes(Dim1,Dim2)) + 
  geom_point(aes(colour=factor(final_cluster)),size=4,) +
  geom_text(aes(label=DMA_ID,x=Dim1 - 0.05,y=Dim2),size=3) +
  ggtitle("Similarity of DMAs") +
  labs(x="Dim1",y="Dim2")

#Divide the top group into visuals for cluster 3 and clusters 7/23
dma_mds_tg3<-dma_mds_tg[which(dma_mds_tg$Dim2 > 1.4),]

ggplot(dma_mds_tg3,aes(Dim1,Dim2)) + 
  geom_point(aes(colour=factor(final_cluster)),size=4,) +
  geom_text(aes(label=DMA_ID,x=Dim1 - 0.01,y=Dim2),size=3) +
  ggtitle("Similarity of DMAs") +
  labs(x="Dim1",y="Dim2")

dma_mds_tg7<-dma_mds_tg[which(dma_mds_tg$Dim2 < 1.2 & 
                              dma_mds_tg$Dim1 < -1.6),]

ggplot(dma_mds_tg7,aes(Dim1,Dim2)) + 
  geom_point(aes(colour=factor(final_cluster)),size=4,) +
  geom_text(aes(label=DMA_ID,x=Dim1 - 0.01,y=Dim2),size=3) +
  ggtitle("Similarity of DMAs") +
  labs(x="Dim1",y="Dim2")

#Divide the records into those in the top of the chart and at the bottom
dma_mds_bg<-dma_mds_g1[which(dma_mds_g1$Dim2 < 0.8),]

ggplot(dma_mds_bg,aes(Dim1,Dim2)) + 
  geom_point(aes(colour=factor(final_cluster)),size=4,) +
  geom_text(aes(label=DMA_ID,x=Dim1 - 0.05,y=Dim2),size=3) +
  ggtitle("Similarity of DMAs") +
  labs(x="Dim1",y="Dim2")

dma_mds_bg2<-dma_mds_bg[which(dma_mds_bg$Dim1 < -0.75  &
                              dma_mds_bg$Dim2 < 0.55   &
                              dma_mds_bg$Dim2 > 0.35),]

ggplot(dma_mds_bg2,aes(Dim1,Dim2)) + 
  geom_point(aes(colour=factor(final_cluster)),size=4,) +
  geom_text(aes(label=DMA_ID,x=Dim1 - 0.02,y=Dim2),size=3) +
  ggtitle("Similarity of DMAs") +
  labs(x="Dim1",y="Dim2")