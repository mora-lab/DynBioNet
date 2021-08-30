#==============================================================================
# function: get_keggInfo
# target: 只需要输入keggid或者kegg的名称就可以获取kegg的信息
# input: keggids: keggid or kegg name; 
#        kegg_GO_info: a connected to kegg_GO_info database
# output: keggInfo
# time: May 6, 2021
# author: xiaowei
#==============================================================================
get_keggInfo <- function(keggids, kegg_GO_info){
  suppressPackageStartupMessages(library(dplyr))
  suppressPackageStartupMessages(library(dbplyr))
  
  tbl(kegg_GO_info, "hsa_kegg") %>% 
    filter(KEGGID %in% keggids | DESCRPTION %in% keggids ) %>% 
    collect() %>% 
    as.data.frame() %>%
    distinct()
}
