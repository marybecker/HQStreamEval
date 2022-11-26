import json

#[2] Traverse the Tree---------------------------------------------------
def up_dfs(R,i):
    L = [i]
    if(R[i][0]==0): return L       #base case (no children)
    else:                          #general case
        for j in range(len(R[i])):
            L += [up_dfs(R,j)]     #get the children of children
        return L
#------------------------------------------------------------------------

#[optional] append rows of zero data
def write_upstream_al_json(R,path):
    with open(path,'w') as f:
        json.dump(R,f)
        return True

path = '/home/tbecker/Downloads/ct_catchments.csv'
with open(path,'r') as f:
    raw = [row.replace('\n','').split(',')[1:3] for row in f.readlines()]
data = raw[1:]

#[1] Build Adjacency [List------------------------------------------------
Rev,fids = {},set([])
for i in range(len(data)): #find the parent to child edges
    fids.add(data[i][0])   #keep all fids...
    if data[i][1] in Rev:  Rev[data[i][1]] += [data[i][0]]
    else:                  Rev[data[i][1]]  = [data[i][0]]
for fid in fids.difference(set(Rev)): Rev[fid] = [0] #add terminal
#-------------------------------------------------------------------------
write_upstream_al_json(Rev,'/home/tbecker/Downloads/ct_catchments_upstream_al.json')