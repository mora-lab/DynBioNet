###########################################################
# title: import_data
# target: 这个函数用于将输入的文件存储到数据库中
#  time: August 13, 2021
#
###########################################################

# db_name <- "my_data" 
# modules <- "data/example_files/modules.csv"
# edges <- "data/example_files/edges.csv"
# design <- "data/example_files/design.csv"
# exprs <- "data/example_files/exprs.csv"
# geneID_type = "SYMBOL"

import_data <- function(db_name, modules, edges, design, exprs, geneID_type = "SYMBOL"){
  
  #=============================================================================
  # 1.连接/创建数据库-------------
  #=============================================================================
  # db_name <- "copd.db" #设置数据库名称
  # 连接或创建数据库
  rel.db <- DBI::dbConnect(RSQLite::SQLite()
                           ,paste0("data/databases/user_data/",db_name, ".sqlite")
  )
  
  
  #=============================================================================
  # 2.读取modules, edges, design 文件----------
  #=============================================================================
  # library(tidyverse)
  # modules <- readr::read_csv(modules) %>% distinct()
  # edges <- readr::read_csv(edges) %>% distinct()
  # design <- readr::read_csv(design) %>% distinct()
  # exprs <- readr::read_csv(exprs) %>% distinct()
  
  #=============================================================================
  # 3.将modules、edges、expression_data存放在RSQLite数据库中----
  #=============================================================================
  # 如果存在，那么就存放在数据库中
  if(!is.null(modules)){copy_to(rel.db, modules, overwrite = TRUE, temporary = FALSE);rm(modules) } # module
  if(!is.null(exprs)){copy_to(rel.db, exprs, overwrite = TRUE, temporary = FALSE);rm(exprs) } #表达数据
  if(!is.null(design)){copy_to(rel.db, design, overwrite = TRUE, temporary = FALSE) } #表型数据
  
  
  #=============================================================================
  # 4.定义数据库的基因ID是ENTREZID还是SYMBOL--------
  #=============================================================================
  geneID_type <- data.frame(type = geneID_type)
  copy_to(rel.db, geneID_type, overwrite = TRUE, temporary = FALSE) #说明基因ID是SYMBOL还是ENTREZID
  
  
  #=============================================================================
  # 5.整理edges文件，将其拆分成gg_edges, weight_tab、groups_tab三个表格---
  # 每个表格都含有 edgeid： 来标识唯一边
  # weight_tab: 列是组-时间-weight.行的内容指明该边的在这个时间点、这个组中weight
  # groups_tab: 列是groups,行的内容是指明每一条边分别在每个组中在哪些时间点
  #=============================================================================
  if(!is.null(edges)){
    # 5.1 将gene_to_gene单独领出来，这样独立存在，并设置edgeid来作为唯一标识
    gg_edges <- edges %>% select(fromNode, toNode) %>% unique() 
    gg_edges$edgeid <- 1:nrow(gg_edges)
    # head(gg_edges)
    
    # 5.2 设法将edgeid标注在edges表格中---------------------------------
    edges <- edges %>% mutate(from_to = paste(fromNode, toNode, sep="_"))
    # head(edges)
    gg_edges <- gg_edges %>% mutate(from_to = paste(fromNode, toNode, sep="_"))
    # head(gg_edges)
    
    edges <- merge(edges, gg_edges[,c("edgeid", "from_to")], by = "from_to", all.x = T) %>% select(-from_to)
    # head(edges)
    gg_edges <- gg_edges %>% select(-from_to)
    # 5.3 将edges存储到数据库中-----
    copy_to(rel.db, edges, overwrite = TRUE, temporary = FALSE) # 边
    
    # 5.4 edges瘦身 ----
    # edges <-  edges %>% select(weight, timepoint, group, edgeid)
    
    # 5.5 建立weights_tab的表格，包含每组、每个时间点的weight值----------
    groups <- unique(edges$group)
    timepoints <- unique(edges$timepoint)
    
    if ("weight" %in% colnames(edges)){ #存在weight才会这样子做。
      weights_tab <- gg_edges %>% select(edgeid)
      
      for (g in groups){
        for (t in timepoints){
          # 选择该时间点、该组的weight和edgeid信息
          y <- edges[which(edges$group == g & edges$timepoint == t), c("weight","edgeid")]
          # 将这组weight合并到weights_tab中。并设置其列名为组—时间-weight
          weights_tab <- merge(weights_tab, y, by="edgeid", all.x = T ) 
          coln <- paste(g, t, "weight",sep = "_")
          #print(coln)
          index <- which(colnames(weights_tab) == "weight")
          colnames(weights_tab)[index] <- coln
          #head(weights_tab)
          rm(coln, index)
        }
      }
    }
    
    
    # 5.6 建立group-edgeids的数据框信息----------------------------------------
    groups_tab <- gg_edges %>% select(edgeid)
    for (g in groups){
      # 取出某一个group的timepoint,edgeid两列
      y <- edges[which(edges$group == g), c("timepoint","edgeid")] 
      idx <- unique(y$edgeid) #确定唯一的edgeid
      # 函数get_tps来合并所有时间点，变成一个字符串
      get_tps <- function(id){paste(sort(y$timepoint[which(y$edgeid == id)]), collapse = ", ")} 
      gtp <- unlist(lapply(idx, FUN = get_tps)) #获取每条边在时间点的存在
      y <- data.frame(edgeid = idx, g=gtp) #组成data.frame
      names(y)[2] = g
      groups_tab <- merge(groups_tab,y, by = "edgeid", all.x = TRUE)
      rm(g, y,idx, gtp)
    }
    
    # # 将gg_edges、groups_tab、weights_tab存放在RSQLite数据库中------------------------
    # copy_to(rel.db, gg_edges, overwrite = TRUE, temporary = FALSE)
    # copy_to(rel.db, groups_tab, overwrite = TRUE, temporary = FALSE)
    # copy_to(rel.db, weights_tab, overwrite = TRUE, temporary = FALSE)
    
    # 5.7 将合并gg_edges、groups_tab、weights_tab为edges2,将edges2存放在RSQLite数据库中------------------------
    if ("weight" %in% colnames(edges)){
      edges2 <- gg_edges %>% left_join(groups_tab, by = "edgeid") %>% 
        left_join(weights_tab, by = "edgeid")  ##存在weight才会有weights_tab
    }else{
      edges2 <- gg_edges %>% left_join(groups_tab, by = "edgeid")
    }
    
    
    copy_to(rel.db, edges2, overwrite = TRUE, temporary = FALSE)  
    rm(gg_edges, groups_tab)
    if ("weight" %in% colnames(edges2)){rm(weights_tab)}
    
    #=============================================================================
    #6. 根据基因对geneID_info、gene_to_KEGG、gene_to_GO、GO_info、KEGG_info进行筛选和保存------
    #=============================================================================
    # 6.1 连接kegg_GO_info数据库------
    kegg_GO_info <- DBI::dbConnect(RSQLite::SQLite(), "data/databases/kegg_GO_info/kegg_GO_info.sqlite")
    src_dbi(kegg_GO_info)
    
    # 6.2 筛选基因 and 保存--------
    genes <- unique(append(edges2$fromNode, edges2$toNode))
    source("Functions/get_geneIDsInfo.R")
    hsa_geneIDs <- get_geneIDsInfo(geneIds = genes, kegg_GO_info) %>% distinct()
    copy_to(rel.db, hsa_geneIDs, overwrite = TRUE, temporary = FALSE)  
    # 6.3 筛选gene_to_kegg and 保存-----------
    entrezids <- unique(hsa_geneIDs$ENTREZID); rm(hsa_geneIDs)
    source("Functions/get_gene_to_KEGG.GO.R")
    hsa_gene_to_KEGG <- get_gene_to_KEGG.GO(entrezids = entrezids, type = "KEGG", kegg_GO_info = kegg_GO_info)
    copy_to(rel.db, hsa_gene_to_KEGG, overwrite = TRUE, temporary = FALSE)  
    # 6.4 筛选kegg and 保存------------
    source("Functions/get_keggInfo.R")
    hsa_kegg <- get_keggInfo(keggids = unique(hsa_gene_to_KEGG$KEGGID), kegg_GO_info)
    copy_to(rel.db, hsa_kegg, overwrite = TRUE, temporary = FALSE);rm(hsa_gene_to_KEGG,hsa_kegg)  
    # 6.5 筛选gene_to_GO and 保存------------------
    hsa_gene_to_GO <- get_gene_to_KEGG.GO(entrezids = entrezids, type = "GO", kegg_GO_info = kegg_GO_info)
    copy_to(rel.db, hsa_gene_to_GO, overwrite = TRUE, temporary = FALSE)  
    # 6.6 筛选GO and 保存-----------------
    source("Functions/get_goInfo.R")
    go_data <- get_goInfo(goids = unique(hsa_gene_to_GO$GOID), kegg_GO_info = kegg_GO_info)
    copy_to(rel.db, go_data, overwrite = TRUE, temporary = FALSE);rm(go_data)  
    # 6.7 关闭kegg_GO_info数据库连接
    DBI::dbDisconnect(kegg_GO_info)
    
    
  }  
  
  #=============================================================================
  # 关闭数据库连接
  #=============================================================================
  #查看这个数据库有什么表格 
  dbplyr::src_dbi(rel.db)
  #关闭数据库连接
  DBI::dbDisconnect(rel.db)
  
}
