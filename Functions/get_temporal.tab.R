################################################################################
# title: get_temporal.tab
# target: 获取gene neighbor 的时间变化表格
# Input:
# - dbname：数据库名称
# - qgene：需要查询的基因
# - qgroup：指定其组的名称
# - gene_nodes：gene_neighborhoods_rel()结果中的gene_nodes
# - x：gene_neighborhoods_rel()结果中的temporal_rel 
# Output: 基因-时间的矩阵表格
# 
################################################################################



# qgene <- "SLCO2B1"
#  x <- temporal_rel
# qgroup <- "nonsmoker"

get_temporal.tab <- function(dbname,qgene,qgroup, gene_nodes, x){
  # 获取用户指定的数据库的具体信息-------
  source("Functions/basic_info.R")
  basic_info <- basic_info(dbname)
  geneID_type <- basic_info$geneID_type
  #qgroup <- input$query_group
  
  qgene <- gene_nodes %>% filter(ENTREZID %in% qgene | SYMBOL %in% qgene) %>% select(all_of(geneID_type)) %>% unique()
  
  # 把基因对应的行给筛选出来------
  x_A <- x %>% filter(fromNode %in% qgene) %>% select(toNode, all_of(qgroup))
  colnames(x_A) <- c("genes","timepoints")
  x_B <- x %>% filter(toNode %in% qgene) %>% select(fromNode, all_of(qgroup))
  colnames(x_B) <- c("genes","timepoints")
  x <- rbind(x_A, x_B) %>% distinct()
  
  if (nrow(x) > 0){
    # 整理每一行的时间点，并形成一个新的表格
    x <- na.omit(x)
    x_list <- strsplit(x$timepoints, split = ", ")
    x_list_name <- x$genes
    names(x_list) <- x_list_name
    
    #tps <- sort(unique(unlist(x_list))) #只包含有的时间点
    tps <- sort(basic_info$timepoints) #使用所有时间点的
    y = as.data.frame(matrix(data = "no", nrow = nrow(x), ncol = length(tps), dimnames = list(x_list_name, tps) ))
    
    for (i in 1:nrow(x)){
      row_index <- x_list_name[i]
      col_index <- x_list[[i]]
      y[row_index, col_index] = "yes"
    }
    
    y$Neighbor_genes  <- rownames(y); rownames(y) = NULL
    y <- y %>% relocate(Neighbor_genes, all_of(tps))
  }else{y = NULL}
  
  #
  return(y)
}
