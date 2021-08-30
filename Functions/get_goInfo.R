#==============================================================================
# function: get_goInfo
# target: 只需要输入GO id或GO Term就可以获取GO节点的信息
# input: goids: goid or go Term; 
#       kegg_GO_info: a connected to kegg_GO_info database
# output: GOInfo
# time: May 6, 2021
# author: xiaowei
#==============================================================================
get_goInfo <- function(goids, kegg_GO_info){
  suppressPackageStartupMessages(library(dplyr))
  suppressPackageStartupMessages(library(dbplyr))
  
  tbl(kegg_GO_info, "go_data") %>% 
    filter(GOID %in% goids | TERM %in% goids ) %>% 
    collect() %>% 
    as.data.frame() %>%
    distinct()
}

