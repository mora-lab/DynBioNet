# req(input$query_gene)
# req(input$gnb_dbname)
# gene_nodes <- genes_neighbor_rel()$gene_nodes 
# temporal_rel <- genes_neighbor_rel()$temporal_rel
# req(gene_nodes)
# req(temporal_rel)
# qgene <- input$query_gene
# 
# 获取用户指定的数据库的具体信息-------
# source("Functions/basic_info.R")
# basic_info <- basic_info(userdb = input$gnb_dbname)
# geneID_type <- basic_info$geneID_type
# qgroup <- input$query_group
# 
# qgene <- gene_nodes %>% filter(ENTREZID %in% qgene | SYMBOL %in% qgene) %>% select(all_of(geneID_type)) %>% unique()
# 
# # temporal_rel <- temporal_rel %>% filter(fromNode %in% qgene | toNode %in% qgene)
# temporal_rel_A <- temporal_rel %>% filter(fromNode %in% qgene) %>% select(toNode, all_of(qgroup))
# colnames(temporal_rel_A) <- c("genes","timepoints")
# temporal_rel_B <- temporal_rel %>% filter(toNode %in% qgene) %>% select(fromNode, all_of(qgroup))
# colnames(temporal_rel_B) <- c("genes","timepoints")
# temporal_rel <- rbind(temporal_rel_A, temporal_rel_B) %>% distinct()


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
	x <- na.omit(x) #删除NA值
    x_list <- strsplit(x$timepoints, split = ", ")
    x_list_name <- x$genes
    names(x_list) <- x_list_name
    
    tps <- sort(unique(unlist(x_list)))
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
