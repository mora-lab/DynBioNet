################################################################################
# title: kegg.GO_from_gene
# target: 只需要输入gene entrezID或Symbol ID就可以获取GO、KEGG、gene_to_GO、gene_to_KEGG、gene的信息
# input： geneids, 可以是entrezID, 也可以是symbol id，或者两者的混合
#         kegg_GO_info是SQLiteConnection  
#         type: 可以是c("KEGG", "GO")、"KEGG"、"GO". 有KEGG的话，会返回包含KEGG、gene_to_kegg信息。
#                有GO的话，会返回包含GO、gene_to_GO信息
# output： list,包含GO、KEGG、gene_to_GO、gene_to_KEGG、gene的信息
# time: May 6, 2021
# author: xiaowei
################################################################################

#geneids = c("1", "3", "17", "AANAT" )
kegg.GO_from_gene <- function(geneids, kegg_GO_info, type = c("KEGG", "GO")){
  suppressPackageStartupMessages(library(dplyr))
  suppressPackageStartupMessages(library(dbplyr))
  
  geneids = unique(geneids)
  
  results <- list()
  #gene节点---
  source("Functions/get_geneIDsInfo.R")
  results[["geneIDs_info"]] <- get_geneIDsInfo(geneIds = geneids, kegg_GO_info)
  
  #entrezids---
  entrezids = unique(results[["geneIDs_info"]]$ENTREZID)

  if ("KEGG" %in% type){
    #gene-to-kegg=========================
    #获取gene_to_KEGG的关系-----
    source("Functions/get_gene_to_KEGG.GO.R")
    results[["gene_to_kegg_info"]] <- get_gene_to_KEGG.GO(kegg_GO_info, entrezids = entrezids, type = "KEGG")
    
    # 获取KEGG节点-----
    keggids <- unique(results[["gene_to_kegg_info"]]$KEGGID)
    source("Functions/get_keggInfo.R")
    results[["KEGG_info"]] <- get_keggInfo(keggids, kegg_GO_info)
    # if(length(keggids) == 0) {
    #   results[["KEGG_info"]] = NULL
    # }else{
    #   source("Functions/get_keggInfo.R")
    #   results[["KEGG_info"]] <- get_keggInfo(keggids, kegg_GO_info)
    # }
    results[["gene_to_kegg_info"]] <- left_join(results[["gene_to_kegg_info"]],results[["KEGG_info"]])
    results[["gene_to_kegg_info"]] <- left_join(results[["gene_to_kegg_info"]],results[["geneIDs_info"]])
    
  }
  
  if ("GO"  %in% type){
    #gene-to-GO=========================
    #获取gene_to_GO的关系-----
    results[["gene_to_GO_info"]] <- get_gene_to_KEGG.GO(kegg_GO_info, entrezids = entrezids, type = "GO")
    
    # 获取GO节点-----
    goids <- unique(results[["gene_to_GO_info"]]$GOID)
    source("Functions/get_goInfo.R")
    results[["GO_info"]] <- get_goInfo(goids, kegg_GO_info)
    
    results[["gene_to_GO_info"]] <- left_join(results[["gene_to_GO_info"]], results[["GO_info"]])
    results[["gene_to_GO_info"]] <- left_join(results[["gene_to_GO_info"]], results[["geneIDs_info"]])
    
  }
  
  return(results)
}



















