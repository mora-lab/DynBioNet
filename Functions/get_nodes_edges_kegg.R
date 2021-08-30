#####################################################################
# title: get_nodes_edges_kegg
# target: 用来获取对gene_to_kegg作图的需要
# input: 
#  - gene_to_kegg：gene_from_KEGG()的结果
#  - geneIDtype: 依据上传的基因ID类型来指定输出的基因类别是symbol还是entrez
# Output:
#  - nodes: visNetwork作图需要的nodes
#  - edges: visNetwork作图需要的edges
#  - kegg_nodes: 需要显示KEGG的表格数据
#  - gene_nodes: 需要显示Gene Nodes的表格数据
#  - edges_info: 需要显示Gene-KEGG关系的表格数据
# author: Xiaowei
# time: August 20, 2021
######################################################################
get_nodes_edges_kegg <- function(genes_to_kegg, geneIDtype = "SYMBOL"){
  
  library(dplyr)
  #------------genes nodes--------------------------------------------------
  gene_nodes <- genes_to_kegg$geneIDs_info %>% 
    mutate(label = SYMBOL, 
           group = "gene",
           title = paste0("symbol: ", "<b>",SYMBOL, "</b> <br> ",
                          "geneName:", "<b>",GENENAME, "</b> " ),
           shape = "ellipse")  
  if (geneIDtype == "SYMBOL"){
    gene_nodes <- gene_nodes %>% rename(id = SYMBOL) 
  }else{
    gene_nodes <- gene_nodes %>% rename(id = ENTREZID) 
  }
  gene_nodes <- gene_nodes %>% select(id,label,group,title,shape) 
  
  
  #------------作图用kegg nodes--------------------------------------------------
  # kegg_nodes
  kegg_nodes <- genes_to_kegg$KEGG_info %>% 
    mutate(label = KEGGID,
           title = paste0("ID: <b>", KEGGID, "</b><br>",
                          "Description: <b>", DESCRPTION, "</b>"),
           group = "kegg",
           shape = "database") %>%
    rename(id = KEGGID) %>% 
    select(id,label,group,title,shape)
  
  # 合并genes_nodes、kegg nodes --------------------------------------
  nodes <- rbind(gene_nodes, kegg_nodes) %>% distinct()
  
  
  #----------作图用gk_edges-------------------------------------------
  edges <- genes_to_kegg$gene_to_kegg_info %>% 
    mutate(color = "black",
           title = "belongKEGG",
           dashes = TRUE) 
  if (geneIDtype == "SYMBOL"){
    edges <- edges %>% rename(from = SYMBOL, to = KEGGID)   
  }else{
    edges <- edges %>% rename(from = ENTREZID, to = KEGGID)   
  }
  edges <- edges %>% select(from,to,title,color,dashes)
  
  #---------表格用keggg_info-------------------------
  kegg_nodes <- genes_to_kegg$KEGG_info
  
  #---------表格用gene_info--------------------------
  gene_nodes <- genes_to_kegg$geneIDs_info
  
  #---------表格用edges_info-------------------------
  edges_info <- edges %>% select(from, to) %>% mutate(relationship = "Gene-KEGG")
  
  #---------返回结果---------------------------------
  return(list(nodes = nodes, edges = edges, 
              gene_nodes = gene_nodes, 
              kegg_nodes = kegg_nodes,
              edges_info = edges_info))
  
}
