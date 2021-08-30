################################################################################
# title: gene_from_GO
# target: 只需要输入goids或go term就可以获取GO、gene_to_GO、gene三者的信息
# input： goids可以是GO id,也可以是GO Term，也可以是两者的混合
#         kegg_GO_info是SQLiteConnection  
#         all=TRUE是用来返回GO、gene_to_GO、gene三者的信息，FALSE的话，只返回gene信息
# output： list,包含gene_to_GO_info、GO_info、geneIDs_info
# time: May 6, 2021
# author: xiaowei
################################################################################

#goids = c("reproduction", "GO:0000009","GO:0000017")

gene_from_GO <- function(goids, all = TRUE, kegg_GO_info){
  
  goids = unique(goids)
  
  suppressPackageStartupMessages(library(dplyr))
  suppressPackageStartupMessages(library(dbplyr))

  # 获取GO节点-----
  source("Functions/get_goInfo.R")
  GO_info <- get_goInfo(goids, kegg_GO_info)
  
  #获取gene_to_GO的关系-----
  goids <- unique(GO_info$GOID)
  source("Functions/get_gene_to_KEGG.GO.R")
  gene_to_GO_info <- get_gene_to_KEGG.GO(goids = goids, type = "GO", kegg_GO_info)

  #获取基因节点--------
  entrezids <- unique(gene_to_GO_info$ENTREZID)
  source("Functions/get_geneIDsInfo.R")
  geneIDs_info <- get_geneIDsInfo(entrezids, kegg_GO_info)
  
  #设置返回的结果是否只需要基因的信息,默认是所有信息
  if (all){
    #获取gene_to_GO的关系-----
    gene_to_GO_info <- left_join(gene_to_GO_info,GO_info)
    gene_to_GO_info <- left_join(gene_to_GO_info,geneIDs_info)
    return(list(geneIDs_info = geneIDs_info,
                GO_info = GO_info,
                gene_to_GO_info = gene_to_GO_info))
    
  }else{
    return(list(geneIDs_info = geneIDs_info))
  }
  
}

