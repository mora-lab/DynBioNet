#####################################################################
# title: genes_relationships_for_KEGG.GO
# target: 这个函数的主要目的是根据Genes relationships in kegg pathway/GO term界面的输入参数，获取相应的数据格式
# input: 
#  - dbname: 界面上对数据库的选择，必选，如果没有的话，后面的将不会发生变化
#  - keggids: 界面上对kegg的选择，可以是keggid，也可以是kegg pathway的名称，支持多个，也可以不选，即NULL
#  - goids: 界面上对goids的选择，可以是goid, 也可以是go Term的名称，支持多个，也可以不选，即NULL
#  - groups: 指定group的名称，可以是一个或多个。必选，如果没有的话，后面的将不会发生变化
#  - timepoints: 指定timepoints，可以是0个、一个或多个
#  - weights: 指定weights的最小值和最大值，也可以是NULL
#  - plotObject: 作图的对象，可以是gene_to_gene, gene_to_kegg, gene_to_GO。 不选的话，也不会执行命令
# Output:
#  - nodes_edges: 包含visNetwork作图需要的nodes、edges
#  - kegg_nodes: 需要显示KEGG的表格数据
#  - gene_nodes: 需要显示Gene Nodes的表格数据
#  - go_nodes: 需要显示GO的表格数据
#  - edges_info: 需要显示plotObject要求的关系类型的表格数据
# author: Xiaowei
# time: August 20, 2021
#####################################################################


genes_relationships_for_KEGG.GO <- function(dbname, keggids, goids, groups, timepoints, weights, plotObject){
  
  # 连接用户数据库-----
  source("Functions/connect_userdb.R")
  dbcon <- connect_userdb(userdb = dbname)
  
  # 获取用户指定的数据库的具体信息-------
  source("Functions/basic_info.R")
  basic_info <- basic_info(userdb = dbname)
  
  # 如果keggids存在，获取keggids相关的关系--gene_to_KEGG----
  source("Functions/gene_from_kegg.R")
  if(!is.null(keggids)){
    gene_to_kegg_info <- gene_from_kegg(keggids = keggids, all = TRUE, dbcon)
  }else{
    gene_to_kegg_info = NULL
  }
  
  
  # 如果goids存在，获取goids相关的关系--gene_to_GO----
  source("Functions/gene_from_GO.R")
  if (!is.null(goids)){
    gene_to_GO_info <- gene_from_GO(goids = goids, all = TRUE, dbcon)  
  }else{
    gene_to_GO_info <- NULL
  }
  
  # 获取gene_to_gene的关系===========================
  # 获取geneids这个参数----
  # (1)keggids或goids两者中至少有一个存在时，只关注与其相关的基因之间是否有关系, 先获取相关的基因--------
  
  # a.如果上传的基因id是Symbol--------------
  
  if (basic_info$geneID_type == "SYMBOL"){
    if (!is.null(keggids)){
      genes_A <- gene_to_kegg_info$geneIDs_info %>% pull(SYMBOL) %>% unique()
    }else{genes_A <- c()  }
    
    if (!is.null(goids)){
      genes_B <- gene_to_GO_info$geneIDs_info %>% pull(SYMBOL) %>% unique()
    }else{genes_B <- c()  }
  }
  
  # b.如果上传的基因id是entrezid--------------
  if (basic_info$geneID_type == "ENTREZID"){
    if (!is.null(keggids)){
      genes_A <- gene_to_kegg_info$geneIDs_info %>% pull(ENTREZID) %>% unique()
    }else{genes_A <- c()  }
    
    if (!is.null(goids)){
      genes_B <- gene_to_GO_info$geneIDs_info %>% pull(ENTREZID) %>% unique()
    }else{ genes_B <- c()   }
  }
  
  # c.获取edges使用的基因ids------------
  geneids <- append(genes_A, genes_B); rm(genes_A, genes_B)
  
  
  # (2)keggids或goids两者都不存在时，只关注所有基因之间关系的变化，那么这里geneids就是NULL---------
  if (is.null(keggids) & is.null(goids)){geneids = NULL}
  
  # 获取gene-to-gene的表格-----
  source("Functions/get_gene_to_gene.R")
  # 这里先根据groups、timepoints、geneids、weights依次对表格进行筛选，
  # 然后再根据groups和timepoints对边的影响，取交集
  gene_to_gene_info <- get_gene_to_gene(geneids = geneids, 
                                        groups = groups, 
                                        timepoints = timepoints, 
                                        weights = weights, 
                                        dbcon = dbcon) 
  
  # 根据gene_to_gene的edgeid来筛选表格-----
  qedgeids <- gene_to_gene_info %>% pull(edgeid) %>% unique()
  # 形成edgeid-weight的矩阵格式（就，输出表格的形式）
  source("Functions/get_gene_to_gene2.R")
  gene_to_gene_info2 <- get_gene_to_gene2(edgeids = qedgeids,
                                          timepoints = timepoints,
                                          groups = groups, 
                                          dbcon = dbcon)
  # 如果是0行，设置为NULL
  if (nrow(gene_to_gene_info2) == 0) {gene_to_gene_info2 = NULL}
  
  
  
  # 根据plot的对象来合并表格=========================
  nodes_edges_list <- list(genes_to_genes = gene_to_gene_info2,
                           genes_to_kegg = gene_to_kegg_info,
                           genes_to_GO = gene_to_GO_info)
  nodes_edges_list <- nodes_edges_list[plotObject] #根据plotObject筛选对应的数据
  
  # 去除genes_to_genes、genes_to_kegg、genes_to_GO三者中的是NULL的
  nodes_edges_list <- nodes_edges_list[!sapply(nodes_edges_list, is.null)]
  plotObject <- names(nodes_edges_list) #重定义plotObject
  
  # 转换成含有nodes、edges的表格
  if ("genes_to_genes" %in% plotObject ){
    source("Functions/get_nodes_edges_gg.R")
    nodes_edges_list[["genes_to_genes"]] <- get_nodes_edges_gg(gene_to_gene = nodes_edges_list[["genes_to_genes"]],
                                                               groups = groups,
                                                               timepoints = timepoints,
                                                               dbcon = dbcon, 
                                                               basic_info$geneID_type)
  }
  
  if ("genes_to_kegg" %in% plotObject){
    source("Functions/get_nodes_edges_kegg.R")
    nodes_edges_list[["genes_to_kegg"]] <- get_nodes_edges_kegg(nodes_edges_list[["genes_to_kegg"]],basic_info$geneID_type)
  }
  
  if ("genes_to_GO" %in% plotObject){
    source("Functions/get_nodes_edges_go.R")
    nodes_edges_list[["genes_to_GO"]] <- get_nodes_edges_go(nodes_edges_list[["genes_to_GO"]], basic_info$geneID_type)
    #go_nodes <- nodes_edges_list[["genes_to_GO"]]$go_nodes
  }
  
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
  if(!is.null(keggids) & "genes_to_kegg" %in% plotObject ){
    kegg_nodes <- nodes_edges_list[["genes_to_kegg"]]$kegg_nodes 
    rownames(kegg_nodes) <- 1:nrow(kegg_nodes) #将行名改成1，2，3...
    }else{
    kegg_nodes <- data.frame(KEGGID = numeric(0), DESCRPTION = numeric(0))
  }
  # go_nodes----------如果在图中，才会显示nodes-----
  if(!is.null(goids) & "genes_to_GO" %in% plotObject){
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
    
    # 重新定义边-------------
  }
  
  #关闭数据库连接
  DBI::dbDisconnect(dbcon)
  
  # 结果， 返回visNetwork图需要的表格数据nodes和edges、查看表格的Genode、KEGG node GO node、edge information==============
  return(list(nodes_edges = nodes_edges, 
              kegg_nodes = kegg_nodes, 
              gene_nodes = gene_nodes, 
              go_nodes = go_nodes, 
              edges_info = edges_info))
  
}


# dbname <- "my_data"
# keggids <- c("hsa05132", "hsa05323", "hsa04060","hsa03010")
# goids <- c("GO:0005515", "GO:0005829")
# groups <- c("COPD_smoker") #, "nonsmoker"
# timepoints <- c("M0", "M3")
# weights <- c(0, 0.7)
# plotObject <- c("genes_to_genes","genes_to_kegg","genes_to_GO")

# groups <- NULL#c("COPD_smoker") #, "nonsmoker"
# timepoints <- c("M0") #, "M3"
# keggids = NULL
# goids = NULL#c("GO:0000015")