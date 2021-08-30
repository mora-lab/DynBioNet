# dbname <- "my_data"
# geneids <- "ABCB6"
# groups <- c("COPD_smoker") #, "nonsmoker"
# timepoints <- c("M0", "M03")
# weights <- c(0, 0.7)
# plotObject <- c("genes_to_genes","genes_to_kegg","genes_to_GO")

# groups <- NULL#c("COPD_smoker") #, "nonsmoker"
# timepoints <- c("M0") #, "M3"
# keggids = NULL
# goids = NULL#c("GO:0000015")

gene_neighborhoods_rel <- function(dbname, geneids, groups, timepoints, weights, plotObject){
  
  # 连接用户数据库-----
  source("Functions/connect_userdb.R")
  dbcon <- connect_userdb(userdb = dbname)
  
  # 获取用户指定的数据库的具体信息-------
  source("Functions/basic_info.R")
  basic_info <- basic_info(userdb = dbname)
  
  # 基因可以是entrezid、也可以是symbol。获取基因的信息
  source("Functions/get_geneIDsInfo.R")
  genes <- get_geneIDsInfo(geneIds = geneids, dbcon)
  
  # 根据数据库的基因id类型，来选择需要查询的基因id
  if (basic_info$geneID_type == "SYMBOL"){ 
    geneids <- genes %>% pull(SYMBOL) %>% unique() 
  }else{
    geneids <- genes %>% pull(ENTREZID) %>% unique() 
  }
  
  # 设置nodes_edges_list来存储visNetwork作图的nodes、edges表格=========
  nodes_edges_list <- list()
  
  # 如果要求gene-to-gene是要作图的，则查找基因的关系========
  if ("genes_to_genes" %in% plotObject ){
    # 根据基因、groups、timepoints、weights查询关系
    # 获取gene-to-gene的表格-----
    source("Functions/get_gene_to_gene.R")
    # 这里先根据groups、timepoints、geneids、weights依次对表格进行筛选，
    # 然后再根据groups和timepoints对边的影响，取交集
    gene_to_gene_info <- get_gene_to_gene(geneids = geneids, 
                                          groups = groups, 
                                          timepoints = timepoints, 
                                          weights = weights, 
                                          dbcon = dbcon, 
                                          all = TRUE) #all的选择使筛选基因的条件时，只要求边的其中一段有这些基因即可。
    
    # 根据gene_to_gene的edgeid来筛选表格-----
    qedgeids <- gene_to_gene_info %>% pull(edgeid) %>% unique()
    # 形成edgeid-weight的矩阵格式（就，输出表格的形式）
    source("Functions/get_gene_to_gene2.R")
    gene_to_gene_info2 <- get_gene_to_gene2(edgeids = qedgeids,
                                            timepoints = timepoints,
                                            groups = groups, 
                                            dbcon = dbcon)
    # 如果是0行，设置为NULL
    if (nrow(gene_to_gene_info2) > 0){
      # 重新获取变量geneids。这时是添加了gene------
      geneids = unique(append(gene_to_gene_info2$fromNode, gene_to_gene_info2$toNode))
      # 注意，如果gene-to-gene不要求输出的话，
      # 那么基因id则就是用户输入的基因id,而不是从基因关系中获得的基因。
      
      # 转换成visNetwork作图需要的节点nodes、edges------
      source("Functions/get_nodes_edges_gg.R")
      nodes_edges_list[["genes_to_genes"]] <- get_nodes_edges_gg(gene_to_gene_info2,
                                                                 groups = groups,
                                                                 timepoints = timepoints,
                                                                 dbcon = dbcon, 
                                                                 basic_info$geneID_type)
      
      #---获取temporal neighborhood membership-------
      temporal_rel <- gene_to_gene_info2 %>% select(fromNode, toNode, all_of(groups))
    }else{
      nodes_edges_list[["genes_to_genes"]] <- NULL;
      temporal_rel <- NULL
    }
    
    # 转换成visNetwork作图需要的节点=========
  }
  
  # 根据plot的要求==========
  # 如果对gene-to-kegg作图，根据基因id，获取gene-to-kegg的关系
  if ("genes_to_kegg" %in% plotObject){
    source("Functions/kegg.GO_from_gene.R")
    gene_to_kegg_info <- kegg.GO_from_gene(geneids = geneids, dbcon, type = "KEGG")
    # 转换成visNetwork作图需要的节点nodes、edges
    if (nrow(gene_to_kegg_info$gene_to_kegg_info) > 0){
      # nodes、edges----
      source("Functions/get_nodes_edges_kegg.R")
      nodes_edges_list[["genes_to_kegg"]] <- get_nodes_edges_kegg(gene_to_kegg_info,basic_info$geneID_type)
    }else{
      nodes_edges_list[["genes_to_kegg"]] <- NULL
    }

  }
  # 如果对gene-to-GO作图，根据基因id，获取gene-to-GO的关系==========
  if ("genes_to_GO" %in% plotObject){
    source("Functions/kegg.GO_from_gene.R")
    gene_to_GO_info <- kegg.GO_from_gene(geneids = geneids, dbcon, type = "GO")
    # 转换成visNetwork作图需要的节点
    if (nrow(gene_to_GO_info$gene_to_GO_info) > 0 ){ #假如gene-to-GO有的话
      # nodes、edges----
      source("Functions/get_nodes_edges_go.R")
      nodes_edges_list[["genes_to_GO"]] <- get_nodes_edges_go(gene_to_GO_info, basic_info$geneID_type)
    }else{
      nodes_edges_list[["genes_to_GO"]] <- NULL
    }
  }
  
  # 去除genes_to_genes、genes_to_kegg、genes_to_GO三者中的是NULL的====
  nodes_edges_list <- nodes_edges_list[!sapply(nodes_edges_list, is.null)]
  plotObject <- names(nodes_edges_list) #重定义plotObject
  
  # 单独获取nodes_list、edges_list、gene_nodes_list。以便使用do.call来快速合并表格
  nodes_list <- list(); for (pO in plotObject){ nodes_list[[pO]] <- nodes_edges_list[[pO]]$nodes };rm(pO)
  edges_list <- list(); for (pO in plotObject){ edges_list[[pO]] <- nodes_edges_list[[pO]]$edges };rm(pO)
  gene_nodes_list <- list(); for (pO in plotObject){ gene_nodes_list[[pO]] <- nodes_edges_list[[pO]]$gene_nodes };rm(pO)
  
  # 假设都没有nodes或edges时，就设置为NULL
  if (length(nodes_list) > 0){ nodes <- do.call(rbind, nodes_list) %>% distinct() }else{nodes <- NULL}
  if (length(edges_list) > 0){edges <- do.call(rbind, edges_list) %>% distinct()}else{edges <- NULL}
  nodes_edges <- list(nodes = nodes,edges = edges)
  if (length(gene_nodes_list) > 0){ 
    gene_nodes <- do.call(rbind, gene_nodes_list) %>% distinct(); 
    rownames(gene_nodes) = 1:nrow(gene_nodes) #将行名改成1，2，3...
  } else{gene_nodes <- NULL}
  
  
  # kegg-nodes------- 如果在图中，才会显示nodes-----
  if("genes_to_kegg" %in% plotObject ){
    kegg_nodes <- nodes_edges_list[["genes_to_kegg"]]$kegg_nodes 
    rownames(kegg_nodes) <- 1:nrow(kegg_nodes) #将行名改成1，2，3...
  }else{
    kegg_nodes <- data.frame(KEGGID = numeric(0), DESCRPTION = numeric(0))
  }
  # go_nodes----------如果在图中，才会显示nodes-----
  if("genes_to_GO" %in% plotObject){
    go_nodes <- nodes_edges_list[["genes_to_GO"]]$go_nodes
    rownames(go_nodes) <- 1:nrow(go_nodes) #将行名改成1，2，3...
  }else{
    go_nodes <- data.frame(GOID = numeric(0), TERM = numeric(0), ONTOLOGY = numeric(0))
  }
  
  # edges_info --------显示图中的边的信息--------------
  edges_info_list <- list(); for (pO in plotObject){ edges_info_list[[pO]] <- nodes_edges_list[[pO]]$edges_info};rm(pO)
  
  if (length(edges_info_list) > 0){ #edges_info_list不为空，再执行这个命令
    if ("genes_to_genes" %in% plotObject ){
      coln = nodes_edges_list[["genes_to_genes"]][["coln"]]
      if ("genes_to_kegg" %in% plotObject){ edges_info_list[["genes_to_kegg"]][coln] <- NA }
      if ("genes_to_GO" %in% plotObject){ edges_info_list[["genes_to_GO"]][coln] <- NA }
    }
    edges_info <- do.call(rbind, edges_info_list)
    rownames(edges_info) <- 1:nrow(edges_info) #将行名改成1，2，3...
  }else{edges_info <- NULL}
  
  # 当gene-to-gene关系需要作图，并且groups只有一个时，重新定义nodes_edges$nodes的基因节点的group列，可以使这些基因节点表现出不同的颜色。
  # 这些颜色是根据基因节点的gene-to-gene的关系类型来决定的。
  if ("genes_to_genes" %in% plotObject &  length(groups) == 1 ){
    # 重新定义nodes_edges$nodes的基因节点的group列
    source("Functions/define_nodes_group.R")
    x <- define_nodes_group(gene_to_gene_info2, groups) %>% arrange(id)
    ids <- x$id
    x_nodes <- nodes_edges$nodes %>% filter(id %in% ids) %>% arrange(id)
    x_nodes[, "group"] <- x[, "group"]
    # 先删除这些基因节点再合并变更后的基因节点
    nodes_edges$nodes <- nodes_edges$nodes %>% filter(! id %in% ids)
    nodes_edges$nodes <- rbind(nodes_edges$nodes, x_nodes)
  }
  
  
  
  #关闭数据库连接-----
  DBI::dbDisconnect(dbcon)
  
  # 结果， 返回visNetwork图需要的表格数据nodes和edges、查看表格的Genode、KEGG node GO node、edge information==============
  return(list(nodes_edges = nodes_edges, 
              kegg_nodes = kegg_nodes, 
              gene_nodes = gene_nodes, 
              go_nodes = go_nodes, 
              edges_info = edges_info,
              temporal_rel = temporal_rel))
  
}