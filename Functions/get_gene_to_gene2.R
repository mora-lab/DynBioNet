################################################################################
# title: get_gene_to_gene
# target: 用来获取edgeids所对应的weight表格
# input:
# - edgeids: edges的id
# - timepoints： 比如： c("M0", "M3")
# - groups： c("group1", "group2")
# - all: 如果是TRUE，那么将返回所有跟这些基因有关的边，如果是FALSE,就要求，只返回geneids内的基因之间的关系
# output: edges筛选后的表格
# author: xiaowei
# time: August 12,2021
################################################################################


get_gene_to_gene2 <- function(edgeids=NULL,
                              timepoints=NULL, 
                              groups=NULL,
                              dbcon){
  
  
  x <- tbl(dbcon, "edges2")
  # 根据edgeids筛选边------------
  if (!is.null(edgeids)){
    x <- x %>% filter(edgeid %in% edgeids)
  }
  
  # 根据groups和timepoints来筛选,如果不存在就全选
  if (is.null(groups)){groups = tbl(dbcon, "edges") %>% pull(group) %>% unique()}
  if (is.null(timepoints)){timepoints = tbl(dbcon, "edges") %>% pull(timepoint) %>% unique()}
  
  gt <- c()
  # 选择weight列名
  if (length(grep("weight", colnames(x))) != 0){
    for (g in groups){
      for (t in timepoints){
        gt <- append(gt, paste(g, t, "weight",sep = "_"))
      }
    }  
  }
  
  
  # 筛选------------------------
  select_cols <- append(groups, gt)
  x <- x %>% select(fromNode, toNode, edgeid,all_of(select_cols));rm(select_cols)
  
  # 返回结果------------------------
  x <- x %>% collect() %>% 
    as.data.frame() %>%
    distinct()
  return(x)

}