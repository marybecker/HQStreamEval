## Accumulated Attributed Algorithms and Functions
## Data - NHD flowline and catchment watershed data set
##
## Original code and applied algorithms developed by Timothy Becker in 2013
## Code Modified by Mary Becker (Last Updated 3/12/22)
##
## Input:  -A table of unique HydroIDs mapped to non-unique NextDownIDs
##         -The Down-Stream Terminals (DST) are marked by having some
##          HydroID lets say :x mapped to NextDownID x, or HydroID==NextDownID
##         -The Up-Stream Terminals (UST) are marked by not being referred
##          to in the NextDownID list, in other words UST are never
##          in the NextDownID column.
##         -A table of HydroIDs and a set of Attributes: P1, P2, P3
##
## Output: -The Accumulated Upstream Values for every Attribute
##         Algorithm: Dynamic Programming with BFS --> O(|V|)

base <- 'analysis/data/'
lc   <- 'coreforest'

#import flow network files for a major basin
mbasin <- 'statewide';
fileType <- '.csv'
mbasin_lookup <- paste0(base,'hydroID_nextdownID_',mbasin,fileType)
if (fileType == '.csv') 
  lookup   <- read.table(mbasin_lookup, header=T,sep=',');
if (fileType == '.txt')
  lookup   <- read.table(mbasin_lookup, header=T);
lookup<- lookup[order(lookup$HydroID),]

#import params for each flow network catchment 
params   <- read.table(paste0(base,lc,'_statewide_allyrs.csv'), header=T,sep=',')
params[is.na(params)] <- 0
params[dim(params)[1]+1,] <- c(1,0,0,0,0,0,0,0,0)# add row for hydroID 1 and 0 for each param
params <- params[order(params$HydroID),]

#Check that there are the same number of hydroIDs in each dataframe
dim(params)[1] == dim(lookup)[1]

c_names  <- colnames(lookup);
r_names  <- lookup[,'HydroID'];
lookup <- as.matrix(lookup);
n <- dim(lookup)[1];


params   <- as.matrix(params[,2:dim(params)[2]])
rownames(params) <- r_names; 
m        <- dim(params)[1];
p        <- dim(params)[2];

if(n != m) "ERROR"

#enumerated hydro_id and next_down_id indecies
nd_i <- as.integer(matrix(0, nrow=n, ncol=1));
for(i in 1:n){ 
	#all the nextdown idicies that the hydro ids point to...
	w <- which(lookup[,'NextDownID']==lookup[i,'HydroID'],arr.ind=T);
	nd_i[w] <- as.integer(matrix(i, nrow=length(w), ncol=1)); 
}
names(nd_i) <- lookup[,'HydroID'];
hy_i <- seq(1,n,1);
names(hy_i) <- names(nd_i);

#find all the nodes that point to themselves these are downstream terminals...
down_t <- list();
for(i in 1:n){ if(hy_i[i]==nd_i[i]){ down_t <- append(down_t, i); } }
down_t <- as.integer(down_t);
#find all the upstream terminals
up_t <- as.integer(setdiff(hy_i, nd_i));

#makes empty adjacency list
alist  <- vector('list',n)
names(alist) <- names(hy_i);
#builds the upstream adjacency list, down_t has all the root nodes
for(i in 1:n){
	temp_l <- hy_i[nd_i==i];
	if((length(temp_l) == 1) && (temp_l==i)){ alist[[i]] <- 0; }
	else{
		if(length(temp_l) > 0){ alist[[i]] <- hy_i[setdiff(temp_l,i)]; }
		else{ alist[[i]] <- 0; } 
	}
}
clist <- matrix(0,nrow=m, ncol=p);                    
rownames(clist) <- r_names;
colnames(clist) <- colnames(params);

Stream_Graph<-setClass('Stream_Graph',
                       representation(Alist='list',Nodes='matrix', Params='matrix', 
                                      N='integer', P='integer'));
stream <- Stream_Graph(Alist=alist, Nodes=clist, Params=params, N=n, P=p);

#Breadth-First Graph Search with accumulated calculation
#G -> The Stream_Graph object
#x -> the current node
bfs<-function(G, x){
	if(G@Alist[[x]][1] == 0){ #compute base case
		for(i in 1:G@P){ G@Nodes[x,i] <- G@Params[x,i]; }
	}
	else{
		for(i in 1:length(G@Alist[[x]])) { G <- bfs(G, G@Alist[[x]][i]); }
		for(i in 1:G@P){ G@Nodes[x,i] <- G@Params[x,i] + sum(G@Nodes[G@Alist[[x]],i]); }
	}
	G
}

#new calculation...
time <- proc.time();
#for each rooted tree in the forest...
for(i in down_t){ stream <- bfs(stream, i); }
time <- proc.time() - time;
time[3]

#n * p matrix with accum answers
result    <- stream@Nodes;
result[1:2,]
result_df <- as.data.frame(result)
result_df$HydroID <- rownames(result_df)

for(i in 2:8){
  lc_yr <- paste0(strsplit(names(result_df)[i],"_")[[1]][1],"_",
                  strsplit(names(result_df)[i],"_")[[1]][2],"_pct")
  result_df[lc_yr] <- result[,i] / result_df[,1] 
}

result_df <- result_df[,grep("HydroID",colnames(result_df)):dim(result_df)[2]]

result.name <- paste0(base,'lc_results/',mbasin,'_',lc,'_accum_attr.csv')
write.csv(result_df,result.name,row.names=FALSE)

