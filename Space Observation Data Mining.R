#--------------------Introduction and Data Preparation--------------------#
#Read dataset
dataset <- read.csv("skyserver.csv", header = TRUE)

str(dataset)
summary(dataset)

#Check if there is any missing data
sapply(dataset, function(x) sum(is.na(x)))

#Remove column with zero variance
dataset$objid = NULL
dataset$rerun = NULL

#Splitting the data into the training/test set
set.seed(148)
library(caTools)
split = sample.split(dataset$class, SplitRatio= 0.8)

train_set = subset(dataset, split == TRUE)
test_set = subset(dataset, split == FALSE)

table(train_set$class)
table(test_set$class)

#Treat the response column seprately
response_train = train_set$class
train_set$class = NULL

response_test = test_set$class
test_set$class = NULL

#Scale the data
library(caret)
Scaled_Values = preProcess(train_set, method = c("center", "scale"))
Scaled_Values

train_Transformed = predict(Scaled_Values, train_set)
test_Transformed = predict(Scaled_Values, test_set)

summary(train_Transformed)
summary(test_Transformed)

#Renuion data and response column
train_fin = cbind(train_Transformed, response_train)
test_fin = cbind(test_Transformed, response_test)

colnames(train_fin)[16] = "Class"
colnames(test_fin)[16] = "Class"

summary(train_fin)
summary(test_fin)

#Combine the scaled training & test set together
dataset_fin = rbind(train_fin,test_fin)
summary(dataset_fin)

#Summary : non-scaled dataset:dataset    
#          scaled data: dataset_fin 
#          training_set: train_fin
#          test set: test_fin


#--------------------Visualization--------------------#
attach(dataset_fin)

#Boxplots for prediction variables against response variable
ggplot(dataset_fin, aes(x = Class, y = ra, fill= Class)) + geom_boxplot()
ggplot(dataset_fin, aes(x = Class, y = dec, fill= Class)) + geom_boxplot()
ggplot(dataset_fin, aes(x = Class, y = u, fill= Class)) + geom_boxplot()
ggplot(dataset_fin, aes(x = Class, y = g, fill= Class)) + geom_boxplot()
ggplot(dataset_fin, aes(x = Class, y = r, fill= Class)) + geom_boxplot()
ggplot(dataset_fin, aes(x = Class, y = i, fill= Class)) + geom_boxplot()
ggplot(dataset_fin, aes(x = Class, y = z, fill= Class)) + geom_boxplot()
ggplot(dataset_fin, aes(x = Class, y = run, fill= Class)) + geom_boxplot()
ggplot(dataset_fin, aes(x = Class, y = camcol, fill= Class)) + geom_boxplot()
ggplot(dataset_fin, aes(x = Class, y = field, fill= Class)) + geom_boxplot()
ggplot(dataset_fin, aes(x = Class, y = specobjid, fill= Class)) + geom_boxplot()
ggplot(dataset_fin, aes(x = Class, y = redshift, fill= Class)) + geom_boxplot()
ggplot(dataset_fin, aes(x = Class, y = plate, fill= Class)) + geom_boxplot()
ggplot(dataset_fin, aes(x = Class, y = mjd, fill= Class)) + geom_boxplot()
ggplot(dataset_fin, aes(x = Class, y = fiberid, fill= Class)) + geom_boxplot()

#Scatterplots show the correlation among each variables

## put (absolute) correlations on the upper panels,
## with size proportional to the correlations.
panel.cor <- function(x, y, digits=2, prefix="", cex.cor) {
  usr <- par("usr"); on.exit(par(usr))
  par(usr = c(0, 1, 0, 1))
  r <- abs(cor(x, y))
  txt <- format(c(r, 0.123456789), digits=digits)[1]
  txt <- paste(prefix, txt, sep="")
  if(missing(cex.cor)) cex.cor <- 0.8/strwidth(txt)*r
  text(0.5, 0.5, txt, cex = cex.cor)
}
## put histograms on the diagonal 
panel.hist <- function(x, ...) {
  usr <- par("usr"); on.exit(par(usr))
  par(usr = c(usr[1:2], 0, 1.5) )
  h <- hist(x, plot = FALSE)
  breaks <- h$breaks; nB <- length(breaks)
  y <- h$counts; y <- y/max(y)
  rect(breaks[-nB], 0, breaks[-1], y, col="cyan", ...)
}

pairs(dataset_fin[,c("ra","dec","u","g","r","i","z","run","camcol","field")], 
      upper.panel=panel.cor, diag.panel=panel.hist)
pairs(dataset_fin[,c("specobjid","redshift","plate","mjd","fiberid")], 
      upper.panel=panel.cor, diag.panel=panel.hist)


#--------------------Dimension Reduction (PCA)--------------------#
pca.dataset_fin <- prcomp(dataset_fin[,1:15])
pca.dataset_fin
summary(pca.dataset_fin)
plot(pca.dataset_fin, col=heat.colors(15), main="PCA")
plot(pca.dataset_fin$sdev, type="b", main = "Scree plot for PCA", 
     ylab="Eigenvalues", xlab="Number of principal component")
abline(h=1)


#--------------------SOMs and Data Reduction--------------------#

#preprocessed data
#*some code are duplicated with the data preparation section,
# but we used different names, so there is no error
trainset = cbind(train_Transformed, response_train)
testset = cbind(test_Transformed, response_test)
colnames(trainset)[16] = "class"
colnames(testset)[16] = "class"

#rejoining the scaled training & test set together
datasetset = rbind(trainset,testset)
summary(datasetset)

#Derive principal components
pctr=prcomp(trainset[,1:15])
summary(pctr)
plot(pctr,col=rainbow(8),main="PCA")
plot(pctr$sdev,pch=4,type="b",main = "Scree plot for PCA",ylab="Eigenvalues",xlab="Number
     of principal component")
abline(h=1)

train_pca = predict(pctr,trainset[,1:15])
test_pca = predict(pctr,testset[,1:15])

#Create whitened datasets
whiten_params = preProcess(train_pca,method=c("center","scale"))
train_whitened = cbind(predict(whiten_params,train_pca),response_train)
test_whitened = cbind(predict(whiten_params,test_pca),response_test)

colnames(train_whitened)[16]="class"
colnames(test_whitened)[16]="class"
train_whitened<-as.data.frame(train_whitened)
pairs(train_whitened[,1:8],col=as.numeric(train_whitened$class)+1)

#----------SELF ORGANIZING MAPS----------#

library(class)
library(kohonen)
som_grid = somgrid(xdim=5, ydim=5, topo="hexagonal")
som_model = som(as.matrix(train_whitened[,-16]), grid=som_grid, rlen=500)

#SOM plots
plot(som_model,type="changes")
plot(som_model,type="count")
plot(som_model,type="dist.neighbours")
par(mfrow=c(2,2))
plot(som_model,type="property",property=getCodes(som_model,1)[,1],main=colnames(getCodes(som_model,1))[1])
plot(som_model,type="property",property=getCodes(som_model,1)[,2],main=colnames(getCodes(som_model,1))[2])
plot(som_model,type="property",property=getCodes(som_model,1)[,3],main=colnames(getCodes(som_model,1))[3])
plot(som_model,type="property",property=getCodes(som_model,1)[,4],main=colnames(getCodes(som_model,1))[4])
par(mfrow=c(1,1))

#Data for SOM nodes
som_nodes = som_model$codes


#--------------------Clustering--------------------#

#----------K-MEANS CLUSTERING----------#
#Visualize clusters on whitened data
train_whitened<-as.data.frame(train_whitened)
pairs(train_whitened[,-9:-16],col=as.numeric(train_whitened$class)+1)


#K-means clustering from 2 to 9 clusters
#index.DB function
index.DB<-function(x,cl,d=NULL,centrotypes="centroids",p=2,q=2){
  if(sum(c("centroids","medoids")==centrotypes)==0)
    stop("Wrong centrotypes argument")
  if("medoids"==centrotypes && is.null(d))
    stop("For argument centrotypes = 'medoids' d cannot be null")
  if(!is.null(d)){
    if(!is.matrix(d)){
      d<-as.matrix(d)
    }
    row.names(d)<-row.names(x)
  }
  if(is.null(dim(x))){
    dim(x)<-c(length(x),1)
  }
  x<-as.matrix(x)
  n <- length(cl)
  k <- max(cl)
  #print(n)
  dAm<-d
  centers<-matrix(nrow=k,ncol=ncol(x))
  if (centrotypes=="centroids"){
    for(i in 1:k)
    {
      for(j in 1:ncol(x))
      {
        centers[i,j]<-mean(x[cl==i,j])
      }
    }
  }
  else if (centrotypes=="medoids"){
    #print("start")
    #print(dAm)
    for (i in 1:k){
      clAi<-dAm[cl==i,cl==i]
      if (is.null(clAi)){
        centers[i,]<-NULL
      }
      else{
        #print("przed centers")
        #print(x[cl==i,])
        #print(clAi)
        centers[i,]<-.medoid(x[cl==i,],dAm[cl==i,cl==i])
        #print("po centers")
        #print(centers[i])
      }
    }   
    #print("stop")
  }
  else{
    stop("wrong centrotypes argument")
  }
  S<-rep(0,k)
  for(i in 1:k){                             # For every cluster
    ind <- (cl==i)
    if (sum(ind)>1){
      centerI<-centers[i,]
      centerI<-rep(centerI,sum(ind))
      centerI<-matrix(centerI,nrow=sum(ind),ncol=ncol(x),byrow=TRUE)
      S[i] <- mean(sqrt(apply((x[ind,] - centerI)^2,1,sum))^q)^(1/q)
    }
    else
      S[i] <- 0                         
  }
  M<-as.matrix(dist(centers,p=p))
  R <- array(Inf,c(k,k))
  r = rep(0,k)
  for (i in 1:k){
    for (j in 1:k){
      R[i,j] = (S[i] + S[j])/M[i,j]
    }
    r[i] = max(R[i,][is.finite(R[i,])])
  } 
  DB = mean(r[is.finite(r)])        
  resul<-list(DB=DB,r=r,R=R,d=M,S=S,centers=centers)
  resul
}

db_index = matrix(,nrow=8,ncol=2)
db_index[,1]=c(2:9)
colnames(db_index)=c("Number of clusters","DB index")

for (i in 2:9) {
  totwithinss_best = 100000000000000000000
  #K-means clustering looped over different random initializations
  for (j in 1:5) {
    clust_temp = kmeans(as.matrix(train_whitened[,-16]),i)
    if (sum(clust_temp$size==0)==0 & clust_temp$tot.withinss<totwithinss_best){
      clust_best = clust_temp
      totwithinss_best = clust_temp$tot.withinss
    }
    rm(clust_temp)
  }
  #Davies-Bouldin's Index
  db = index.DB(as.matrix(train_whitened[,-16]),clust_best$cluster)
  db_index[i-1,2] = db$DB
  assign(paste("clust",i,sep=""),clust_best)
  rm(clust_best)
}
rm(totwithinss_best)
rm(i)
rm(j)

db_index

#Graphs of clusters in PC1, PC2 space
par(mfrow=c(3,3),mar=c(1.5,1.5,1.5,1.5))
plot(train_whitened$PC1,train_whitened$PC2,col=clust2$cluster+1,main="2 clusters",xlab="PC1",ylab="PC2")
plot(train_whitened$PC1,train_whitened$PC2,col=clust3$cluster+1,main="3 clusters",xlab="",ylab="")
plot(train_whitened$PC1,train_whitened$PC2,col=clust4$cluster+1,main="4 clusters",xlab="",ylab="")
plot(train_whitened$PC1,train_whitened$PC2,col=clust5$cluster+1,main="5 clusters",xlab="",ylab="")
plot(train_whitened$PC1,train_whitened$PC2,col=clust6$cluster+1,main="6 clusters",xlab="",ylab="")
plot(train_whitened$PC1,train_whitened$PC2,col=clust7$cluster+1,main="7 clusters",xlab="",ylab="")
plot(train_whitened$PC1,train_whitened$PC2,col=clust8$cluster+1,main="8 clusters",xlab="",ylab="")
plot(train_whitened$PC1,train_whitened$PC2,col=clust9$cluster+1,main="9 clusters",xlab="",ylab="")
plot(db_index[,1],db_index[,2],type="o",xlab="Number of clusters",ylab="DB Index",main="DB Index")

#In our case, five clusters minimizes the DB index
par(mfrow=c(1,1))

#----------Visualizing training set based on 5 clusters----------#

#pairs(train_fin[,-15],col=clust5$cluster+1)
#In the original training data, it appears that clusters are most defined by the field and redshift
plot(as.numeric(trainset$field),as.numeric(trainset$redshift),col=clust5$cluster+1,xlab="field number",ylab="final redshift",main="Training set")

#Predict clusters for SOM nodes
SOM_clust = cl_predict(clust5,as.data.frame(som_nodes))
plot(som_model,type="property",property=SOM_clust,ncolors=4,palette.name=rainbow,main="SOM node clusters")

#----------Applying 5 clusters to test set----------#

#Predict clusters for test set data
test_clust = cl_predict(clust5,test_whitened[,-16])
#There are no type 5 observations in the test set
test_whitened<- as.data.frame(test_whitened)
#Plot test set data in PC1, PC2 space
plot(test_whitened$PC1,test_whitened$PC2,col=test_clust+1,main="Test set",xlab="PC1",ylab="PC2")

#Examine clusters by field and redshift
test_clust1=cl_predict(clust5,test_whitened[,-16])
plot(as.numeric(testset$field),as.numeric(testset$redshift),col=test_clust1+1,xlab="field number",ylab="final redshift",main="Test set")
#Clusters are still highly defined by these categories in the test set

#----------Hierarchical clustering----------#
c.dist <- dist(train_whitened[,1:6])
# single linkage
c.hclust.single <- hclust(c.dist, method = "single")
c.hclust.single$labels <- train_whitened$class
plot(c.hclust.single, main = "Single Linkage")
# complete linkage
c.hclust.comp <- hclust(c.dist, method = "complete" )
c.hclust.comp$labels <- train_whitened$class
plot(c.hclust.comp, main = "Complete Linkage")
# average linkage
c.hclust.avg<-hclust(c.dist, method = "ave" )
c.hclust.avg$labels <- train_whitened$class
plot(c.hclust.avg, main = "Average Linkage")
rect.hclust(c.hclust.avg, k = 5, border = "blue")
# comparing complete linkage and average linkage
# complete linkage first
in.clust.comp <- rect.hclust(c.hclust.comp, k = 5, border = "red")
H.clust.comp <- rep(0,8000)
H.clust.comp[in.clust.comp[[1]]] <- "2"
H.clust.comp[in.clust.comp[[2]]] <- "1"
H.clust.comp[in.clust.comp[[3]]] <- "1"
H.clust.comp[in.clust.comp[[4]]] <- "3"
H.clust.comp[in.clust.comp[[5]]] <- "2"
library(mda)
confusion(H.clust.comp,train_whitened$class)

# average linkage first
in.clust.avg <- rect.hclust(c.hclust.avg, k = 5, border = "blue")
H.clust.avg <- rep(0,8000)
H.clust.avg[in.clust.avg[[1]]] <- "2"
H.clust.avg[in.clust.avg[[2]]] <- "1"
H.clust.avg[in.clust.avg[[3]]] <- "3"
H.clust.avg[in.clust.avg[[4]]] <- "1"
H.clust.avg[in.clust.avg[[5]]] <- "2"
confusion(H.clust.avg,train_whitened$class)


#--------------------Classification--------------------#

#----------Neural Network----------#
m_train <- model.matrix(~., data=train_fin)
m_test <- model.matrix(~.,data=test_fin)
n <- colnames(m_train)
f <- as.formula(paste("ClassQSO + ClassSTAR ~ ", paste(n[!n %in% c("ClassQSO","ClassSTAR","(Intercept)")], collapse = "+")))

# Find the best number of neurons
nn <- NULL
nn_pred <- NULL
layers <- NULL
misclass_test <- NULL
misclass_train <- NULL
library(neuralnet)
for (i in 4:12){
  nn[[i]] <- neuralnet(f,data=m_train,hidden=i,linear.output=FALSE,rep=5,stepmax=1e+06)
  print(i)
  best <- which.min(nn[[i]]$result.matrix[1,])
  misclass_train[[i]] <- mean(abs(round(
    nn[[i]]$net.result[[best]]) - m_train[,c("ClassQSO","ClassSTAR")]))
  nn_pred[[i]] <- neuralnet::compute(nn[[i]],m_test[,!n %in% c("ClassQSO","ClassSTAR","(Intercept)")],rep=best)
  misclass_test[[i]] <- mean(abs(round(nn_pred[[i]]$net.result) - m_test[,c("ClassQSO","ClassSTAR")]))
}
error <- as.data.table(t(rbind(misclass_test,misclass_train)))
colnames(error) <- c("test","train")
error1=error[4:12,]
error1
plot(c(4:12),(1-error1$test)*100,
     type="b",
     ylim=c(99,100),
     col="blue",
     xlab="Number of nodes",
     ylab="% classified correctly")
points(c(4:12),(1-error1$train)*100,type="b",col="red")
title("Neural net performance different nodes")
legend("right",legend=c("Test","Training"),col=c("red","blue"),lty=1:2)

# add Hidden layers
nn <- NULL
nn_pred <- NULL
hid.layer <- NULL
misclass_test <- NULL
misclass_train <- NULL
for (i in 1:10){
  if (i==1){
    hid.layer <- 9
  }else{
    hid.layer <- c(layers,9)
  }
  nn[[i]] <- neuralnet(f,data=m_train,hidden=hid.layer,linear.output=FALSE,rep=5,stepmax=1e+07)
  print(i)
  best <- which.min(nn[[i]]$result.matrix[1,])
  misclass_train[[i]] <- mean(abs(round(nn[[i]]$net.result[[best]]) - m_train[,c("ClassQSO","ClassSTAR")]))
  nn_pred[[i]] <- neuralnet::compute(nn[[i]],m_test[,!n %in% c("ClassQSO","ClassSTAR","(Intercept)")],rep=best)
  misclass_test[[i]] <- mean(abs(round(nn_pred[[i]]$net.result) - m_test[,c("ClassQSO","ClassSTAR")]))
}
error <- as.data.table(t(rbind(misclass_test,misclass_train)))
colnames(error) <- c("test","train")
plot(c(1:10),(1-error$test)*100,
     type="b",
     ylim=c(98.5,100),
     col="blue",
     xlab="Number of layers",
     ylab="% classified incorrectly")
points(c(1:10),(1-error$train)*100,type="b",col="red")
title("Neural net performance with additional layers ")
legend("right",legend=c("Test","Training"),col=c("red","blue"),lty=1:2)

#----------KNN----------#
knn_QSO <- NULL
knn_STAR<- NULL
knn_error <- NULL
library(class)
for (i in 1:30){
  knn_QSO[[i]] <- knn(m_train[,colnames(m_test)!=c("ClassQSO","ClassSTAR")],
                      m_test[,colnames(m_test)!=c("ClassQSO","ClassSTAR")],
                      m_train[,"ClassQSO"],k=i)
  knn_STAR[[i]] <- knn(m_train[,colnames(m_test)!=c("ClassQSO","ClassSTAR")],
                       m_test[,colnames(m_test)!=c("ClassQSO","ClassSTAR")],
                       m_train[,"ClassSTAR"],k=i)
  knn_error[[i]] <- mean(abs((as.numeric(knn_QSO[[i]])-1)-m_test[,"ClassQSO"])+abs((as.numeric(knn_STAR[[i]])-1)-m_test[,"ClassSTAR"]))
}

knn_error

plot(c(1:30),(1-knn_error)*100,
     type="b",
     xlab="Number of nearest neighbours",
     ylab="% rate of successful classification",
     col="blue"
)
title("kNN performance")

#----------Classification Tree----------#
library(tree)
tree.model <- tree(Class ~., data = train_fin)
tree.model
summary(tree.model)
plot(tree.model, type = "uniform")
text(tree.model, all=T)
#distributional prediction
prediction <- predict(tree.model, test_fin)
head(prediction)
#point prediction
maxidx <- function(arr) {
  return(which(arr == max(arr)))
}
idx <- apply(prediction, c(1), maxidx)
prediction <- c('galaxy', 'qso', 'star')[idx]
table(prediction, test_fin$Class)

pruned.tree <- prune.tree(tree.model, best = 3)
plot(pruned.tree, type = "uniform")
text(pruned.tree, all=T)
pruned.prediction <- predict(pruned.tree, test_fin, type="class")
table(pruned.prediction, test_fin$Class)

#----------Random Forest----------#
library("randomForest")
r <- randomForest(Class ~., data=train_fin)
print(r)
RFprediction <- predict(r, test_fin)
table(test_fin$Class, RFprediction)