################################################################################
# title: get_gene_to_gene
# target: 用来筛选基因和基因的关系
# input:
# - geneids: edges指定ID类型的gene
# - weights： 比如：c(1.0, 2.3)
# - timepoints： 比如： c("M0", "M3")
# - groups： c("group1", "group2")
# - all: 如果是TRUE，那么将返回所有跟这些基因有关的边，如果是FALSE,就要求，只返回geneids内的基因之间的关系
# output: edges筛选后的表格
# author: xiaowei
# time: August 11,2021
################################################################################

get_gene_to_gene <- function(geneids=NULL, weights=NULL, timepoints=NULL, groups=NULL, 
                             all=FALSE,
                             dbcon){
  suppressPackageStartupMessages(library(dplyr))
  suppressPackageStartupMessages(library(dbplyr))
  
  
  # 根据groups来筛选
  if (!is.null(groups)){
    x <- tbl(dbcon, "edges") %>% filter(group %in% groups)
  }else{x <- tbl(dbcon, "edges")}
  
  # 根据timepoints来筛选
  if (!is.null(timepoints)){
    x <- x %>% filter(timepoint %in% timepoints)
  }
  
  # 根据geneids来筛选
  if (!is.null(geneids)){
    if (all){
      x <- x %>% filter(fromNode %in% geneids | toNode %in% geneids ) #只需要有就可以
    }else{
      x <- x %>% filter(fromNode %in% geneids) %>% filter(toNode %in% geneids) #两个基因都得属于geneids中的
    }
  }
  
  
  # 根据weights来筛选
  if (!is.null(weights) & "weight" %in% colnames(x)){
    min_w = weights[1]
    max_w = weights[2]
    x <- x %>% filter(weight >= min_w & weight <= max_w)  
  }
  
  # 如果groups是多个，timepoint是多个时，取交集
  if (!is.null(timepoints) & length(timepoints) > 1){
    edgeids_index <- x %>% pull(edgeid) %>% unique()
    if (!is.null(groups) & length(groups) > 1){
      for (g in groups){
        for (t in timepoints){
          edgeids_index <- x %>% filter(timepoint == t & group == g) %>% 
            pull(edgeid) %>% unique() %>% intersect(edgeids_index)
        }  
      }
    }else{
      for (t in timepoints){
        edgeids_index <- x %>% filter(timepoint == t) %>% 
          pull(edgeid) %>% unique() %>% intersect(edgeids_index)
      }
    }
    
      
      x <- x %>% filter(edgeid %in% edgeids_index)  
    
  }
  
  # 返回结果------------------------
  x <- x %>% collect() %>% 
    as.data.frame() %>%
    distinct()
  

  return(x)
}


##########
#dplyr使用时，不能出现[]之类的







