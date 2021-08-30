#####################################################################
# title: get_nodes_edges_go
# target: 用来获取对gene_to_GO作图的需要
# input: 
#  - gene_to_GO：gene_from_GO()的结果
#  - geneIDtype: 依据上传的基因ID类型来指定输出的基因类别是symbol还是entrez
# Output:
#  - nodes: visNetwork作图需要的nodes
#  - edges: visNetwork作图需要的edges
#  - go_nodes: 需要显示GO的表格数据
#  - gene_nodes: 需要显示Gene Nodes的表格数据
#  - edges_info: 需要显示Gene-GO关系的表格数据
# author: Xiaowei
# time: August 20, 2021
#####################################################################
get_nodes_edges_go <- function(gene_to_GO, geneIDtype = "SYMBOL"){
  
  library(dplyr)
  #------------genes nodes--------------------------------------------------
  gene_nodes <- gene_to_GO$geneIDs_info %>% 
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
  
  #------------作图用GO nodes--------------------------------------------------
  go_nodes <- gene_to_GO$GO_info %>%
    mutate(label = GOID,
           group = paste0("go_",ONTOLOGY),
           title = paste0("ID: <b>", GOID, "</b><br>",
                          "Term: <b>", TERM, "</b><br>",
                          "Ontology: <b>", ONTOLOGY, "</b>"),
           shape = "box" 
    ) %>%
    rename(id = GOID) %>% 
    select(id,label,group,title,shape)
  
  # 合并genes_nodes、kegg nodes --------------------------------------
  nodes <- rbind(gene_nodes, go_nodes) %>% distinct()
  
  #----------作图用ggo_edges-------------------------------------------  
  edges <- gene_to_GO$gene_to_GO_info  %>% 
    mutate(color = "black",
           title = "belongGO",
           dashes = TRUE) 
  if (geneIDtype == "SYMBOL"){
    edges <- edges %>% rename(from = SYMBOL, to = GOID)   
  }else{
    edges <- edges %>% rename(from = ENTREZID, to = GOID)   
  }
  edges <- edges %>% select(from,to,title,color,dashes)
  
  #---------表格用GO_nodes------------------------------------
  go_nodes <- gene_to_GO$GO_info
  
  #---------表格用gene_nodes----------------------------------
  gene_nodes <- gene_to_GO$geneIDs_info
  #---------表格用edges_info----------------------------------
  edges_info <- edges %>% select(from, to) %>% mutate(relationship = "Gene-GO")
  
  #----返回结果-----------------------------
  return(list(nodes =nodes , edges = edges, 
              go_nodes = go_nodes, 
              gene_nodes = gene_nodes,
              edges_info = edges_info))

}