###############################################################################
# 输入kegg id 或 kegg 名称就可以获取KEGG节点、KEGG和gene关系,还有这些gene
#
###############################################################################
#keggids = c("hsa01100","hsa00230", "Pentose phosphate pathway")

gene_from_kegg <- function(keggids, all = TRUE, kegg_GO_info){

  keggids = unique(keggids)
  
  suppressPackageStartupMessages(library(dplyr))
  suppressPackageStartupMessages(library(dbplyr))

  # 获取KEGG节点-----
  source("Functions/get_keggInfo.R")
  KEGG_info <- get_keggInfo(keggids, kegg_GO_info)
  
  #获取gene_to_KEGG的关系-----
  keggids <- unique(KEGG_info$KEGGID)
  source("Functions/get_gene_to_KEGG.GO.R")
  gene_to_kegg_info <- get_gene_to_KEGG.GO(kegg_GO_info, keggids = keggids, type = "KEGG")
  
  #获取基因节点--------
  entrezids <- unique(gene_to_kegg_info$ENTREZID)
  source("Functions/get_geneIDsInfo.R")
  geneIDs_info <- get_geneIDsInfo(entrezids, kegg_GO_info)
  
  #设置返回的结果是否只需要基因的信息,默认是所有信息
  if (all){
    #获取gene_to_KEGG的关系-----
    gene_to_kegg_info <- left_join(gene_to_kegg_info,KEGG_info)
    gene_to_kegg_info <- left_join(gene_to_kegg_info,geneIDs_info)
    return(list(geneIDs_info = geneIDs_info,
           KEGG_info = KEGG_info,
           gene_to_kegg_info = gene_to_kegg_info))
    
  }else{
    return(list(geneIDs_info = geneIDs_info))
  }

}


