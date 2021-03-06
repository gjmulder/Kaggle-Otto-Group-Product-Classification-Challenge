## <https://www.kaggle.com/c/otto-group-product-classification-challenge/data>

cat("\014"); rm(list = ls(all = TRUE)); gc(reset=TRUE)
library(h2o)

localH2O = h2o.init(max_mem_size = paste0(round(memory.limit()/1024),"g"),
                     nthreads=-1)

train <- read.csv("./data/train.csv.gz")

for(i in 2:94){
        train[,i] <- as.numeric(train[,i])
        train[,i] <- sqrt(train[,i]+(3/8))
}


test <- read.csv("./data/test.csv.gz")

for(i in 2:94){
        test[,i] <- as.numeric(test[,i])
        test[,i] <- sqrt(test[,i]+(3/8))
}



train.hex <- as.h2o(localH2O,train)
test.hex  <- as.h2o(localH2O,test[,2:94])

predictors <- 2:(ncol(train.hex)-1)
response   <- ncol(train.hex)

submission <- read.csv("./data/sampleSubmission.csv.gz")  
submission[,2:10] <- 0

Iterations <- 5
time.start <- Sys.time()
for(i in 1:Iterations){
        print(i)
        model <- h2o.deeplearning(x=predictors,
                                  y=response,
                                  data=train.hex,
                                  classification=T,
                                  activation="RectifierWithDropout",
                                  hidden=c(1024,512,256),
                                  hidden_dropout_ratio=c(0.5,0.5,0.5),
                                  input_dropout_ratio=0.05,
                                  epochs=50,
                                  l1=1e-5,
                                  l2=1e-5,
                                  rho=0.99,
                                  epsilon=1e-8,
                                  train_samples_per_iteration=2000,
                                  max_w2=10,
                                  seed=1)
        submission[,2:10] <- submission[,2:10] + as.data.frame(h2o.predict(model,test.hex))[,2:10]
        print(i)
        ## Save submission to disk
        write.csv(submission,file="./data/submission.csv",row.names=FALSE) 
        
        time.now <- Sys.time();
        time.diff <- difftime(time.now,time.start,units="secs")
        cat('ETC:', round((time.diff/t)*(dim(tuneGrid)[1]-t)),'[sec] \n')
}      


