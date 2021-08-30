plot_gene_expression <- function(dbname,qgene ){
  
  # 连接数据库----
  source("Functions/connect_userdb.R")
  dbcon <- connect_userdb(dbname)
  
  # 选择指定基因的exprs----
  #qgene = "ACP5"
  exprs <- tbl(dbcon, "exprs") %>% filter(gene %in% qgene) %>% select(-gene) %>%
    collect() %>% 
    as.data.frame() %>%
    distinct()
  
  if (nrow(exprs) >0 ){
    exprs <- as.data.frame(t(exprs)) 
    colnames(exprs) <- "value"
    exprs$sample <- rownames(exprs)
    exprs$value <- as.numeric(exprs$value)
    
    # design----
    design <- tbl(dbcon, "design") %>%
      collect() %>% 
      as.data.frame() %>%
      distinct()
    
    # 合并exprs和design-----
    exprs <- merge(exprs, design, by = "sample", all.x = TRUE)
    
    
    # plot------
    library(ggplot2)
    ggplot(exprs, aes(x=timepoint, y=value, fill=group)) + 
      geom_violin() + 
      ggtitle(paste(qgene, "gene expression", sep = " ")) +
      theme(plot.title = element_text(hjust = 0.5)) #标题居中
  }else{
    NULL
  }
  
}

# plot_gene_expression("my_data", "ACP5")
# plot_gene_expression("my_data", "TANK")
# dbname = "my_data";qgene = "aaaaa"
