#==============================================================================
# function: get_geneIDsInfo
# target: 只需要输入基因的entrezid或symbol id就可以获取基因的ID信息，可以混合在一起
# input: gene entrezid or symbol ; a connected to kegg_GO_info database
# output: GeneIDsInfo
# time: May 6, 2021
# author: xiaowei
#==============================================================================

get_geneIDsInfo <- function(geneIds, kegg_GO_info){
  suppressPackageStartupMessages(library(dplyr))
  suppressPackageStartupMessages(library(dbplyr))
  
  tbl(kegg_GO_info, "hsa_geneIDs") %>%
    filter(ENTREZID %in% geneIds | SYMBOL %in% geneIds) %>% 
    collect() %>% 
    as.data.frame() %>%
    distinct()
}
