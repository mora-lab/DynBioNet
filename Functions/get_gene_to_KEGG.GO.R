################################################################################
# title: get_gene_to_KEGG.GO
# input： 只要输入keggids， goids， entrezids 其中一个就可以获取相应的关系（gene_to_GO或gene_to_KEGG)
#        type可以是"KEGG"或"GO"
#         kegg_GO_info是SQLiteConnection  
# output： gene_to_GO或gene_to_KEGG的数据框
# time: May 6, 2021
# author: xiaowei
################################################################################

get_gene_to_KEGG.GO <- function(kegg_GO_info, keggids = NULL, goids = NULL, entrezids = NULL, type = "KEGG"){
  
  suppressPackageStartupMessages(library(dplyr))
  suppressPackageStartupMessages(library(dbplyr))
  
  if (type == "KEGG"){
    x = tbl(kegg_GO_info, "hsa_gene_to_KEGG")
    if (!is.null(keggids)){ x <- x %>% filter(KEGGID %in% keggids ) }
    if (!is.null(entrezids)){ x <- x %>% filter(ENTREZID %in% entrezids ) }
  }
  
  if (type == "GO"){
    x = tbl(kegg_GO_info, "hsa_gene_to_GO")
    if (!is.null(goids)) {x <- x %>% filter(GOID %in% goids ) }
    if (!is.null(entrezids)) {x <- x %>% filter(ENTREZID %in% entrezids ) }
  }
  
  x = x %>% collect() %>% as.data.frame() %>% distinct()
  return(x)
  
}





