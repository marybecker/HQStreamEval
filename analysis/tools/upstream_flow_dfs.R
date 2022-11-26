data <- read.csv('ct_catchments.csv',stringsAsFactors=F);
data <- data[,2:dim(data)[2]]
data[1:10,]
colnames(data) <- c('fid','nid','shape','km');

#[1] Build Adjacency [List-----------
Rev <- vector(mode='list',length=0);
for(i in 1:dim(data)[1]){
  fid<-toString(data[i,'fid']);
  Rev[[fid]] <- c(0);
}
for(i in 1:dim(data)[1]){
  nid<-toString(data[i,'nid']);
  Rev[[nid]] <- c();
}
for(i in 1:dim(data)[1]){
  fid<-toString(data[i,'fid']);
  nid<-toString(data[i,'nid']);
  Rev[[nid]] <- c(Rev[[nid]],fid);
}#----------------------------------

#[2]Traverse the Tree (AL)----------
up_dfs<-function(Ref,i){
  L <- c(i); #visiting node i
  children <- Rev[[i]];
  if(children[1]==0){ #base case
    L                 #stops and returns
  } else {            #general case
    for(j in 1:length(children)){
      L <- c(L,up_dfs(Rev,children[j]));
    }
  }
  L
}#----------------------------------