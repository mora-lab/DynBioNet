#####################################################################
# title: get_nodes_edges_gg
# target: 用来获取对gene_to_gene作图的需要
# input: 
#  - gene_to_gene：get_gene_to_gene2()的结果
#  - groups: 分组信息
#  - timepoints: 选择的时间点
#  - dbcon: 选择相应的数据库连接。connect_userdb()的结果
#  - geneIDtype: 依据上传的基因ID类型来指定输出的基因类别是symbol还是entrez
# Output:
#  - nodes: visNetwork作图需要的nodes
#  - edges: visNetwork作图需要的edges
#  - gene_nodes: 需要显示Gene Nodes的表格数据
#  - edges_info: 需要显示Gene-KEGG关系的表格数据
#  - coln: gene_nodes中关于timepoints和groups合成的列名，用于后续合并Gene Nodes的时候使用
# author: Xiaowei
# time: August 20, 2021
######################################################################
get_nodes_edges_gg <- function(gene_to_gene, groups,timepoints,dbcon, geneIDtype = "SYMBOL"){
  
  #------------genes nodes--------------------------------------------------
  # gene_nodes #后面还需要获取表达信息
  genes <- unique(append(gene_to_gene$fromNode, gene_to_gene$toNode))
  source("Functions/get_geneIDsInfo.R")
  gene_nodes <- get_geneIDsInfo(genes, dbcon)
  #在这里需要注意的是，genes的数量可能是大于gene_nodes的数量，也就是说genes在get_geneIDsInfo()可能获取不到基因的关系，
  #从而导致了gene_nodes的数量减少（即我们与用户的数据匹配之后，我们的数据库里面没有用户的基因的。）
  #这个时候可以考虑添加NA来处理。或者移除这部分在数据库中不存在的基因和它们的关系。
  #不过，我们考虑将那些些在我们数据库不存在的基因中添加进gene_nodes中。
  if (geneIDtype == "SYMBOL"){
    diff_genes <- genes[!genes %in% gene_nodes$SYMBOL ]
  }else{
    diff_genes <- genes[!genes %in% gene_nodes$ENTREZID ]
  }
  
  if (length(diff_genes) > 0 ){
    diff_genes <- data.frame(ENTREZID = diff_genes, SYMBOL = diff_genes, GENENAME = NA)
    gene_nodes <- rbind(gene_nodes, diff_genes)
  }
  
  # 为visNetwork图的nodes设置----
  nodes <- gene_nodes %>% 
    mutate(label = SYMBOL, 
           group = "gene", ##如果groups只有一个时，设置group就是时间点的不同，区别不同,后面再改
           title = paste0("symbol: ", "<b>",SYMBOL, "</b> <br> ",
                          "geneName:", "<b>",GENENAME, "</b> " ),
           shape = "ellipse")  
  
  # 如果gg的边是symbol-symbol，或 entrez-entrez
  if (geneIDtype == "SYMBOL"){
    nodes <- nodes %>% rename(id = SYMBOL) 
  }else{
    nodes <- nodes %>% rename(id = ENTREZID) 
  }
  nodes <- nodes %>% select(id,label,group,title,shape) 
  

  #----------作图用gg_edges-------------------------------------------
  # 函数用来合成title的
  title_for_groups_edges <- function(gene_to_gene, groups){
    x = gene_to_gene[,groups]
    if (length(groups) > 1){
      nR = 1:nrow(x)
      for (g in groups){
        x[g] = sapply(nR, FUN = function(n){if(!is.na(x[n,g])){paste0(g, ": <b>",x[n,g], "</b>")}else{NA}})
      }
      sapply(nR, FUN = function(n){paste(x[n,groups][!is.na(x[n,groups])], collapse = "<br>")})
    }else if (length(groups) == 1 ){
      nR = 1:length(x)
      sapply(nR, FUN = function(n){if(!is.na(x[n])){paste0(groups, ": <b>",x[n], "</b>")}else{NA}})
    }
  }
  # 如果groups不存在，就默认是全选
  gene_to_gene$title <- title_for_groups_edges(gene_to_gene, groups)

  
  #如果groups只有一个时，给边上色，区别不同。
  if (length(groups) == 1){
    nt <- unique(gene_to_gene[,groups])
    if (length(nt) < 15){
      # 预定义好颜色名称
      library(RColorBrewer)
      mycolors <- c(brewer.pal(8,"Dark2")[c(8,4)],brewer.pal(12,"Paired"))
      # 根据时间点的不同，选取颜色，并形成数据框格式
      nt_color <- data.frame(nt = nt,color = mycolors[1:length(nt)])
      colnames(nt_color)[1] <- groups
      gene_to_gene <- merge(gene_to_gene, nt_color, by = groups, all.x = T) #将color这一列合并到gene_to_gene中。
    }
  }
  
  # 如果没有color这一列，则定义color列
  if ("color" %in% colnames(gene_to_gene)){ 
    edges <- gene_to_gene 
  }else{  edges <- gene_to_gene %>% mutate(color = "blue") }
  # 设置dashes列、更改from、to列名，选择相应的列
  edges <- edges %>%  mutate(dashes = FALSE) %>%
    rename(from = fromNode, to = toNode) %>%
    select(from,to,title,color,dashes)
  
  
  
  #---------表格用edges_info----------------------------------
  coln <- c()
  if (length(grep("weight", colnames(gene_to_gene))) != 0){ #如果weight存在的话，可以添加weight这一列，如果没有那就不用了。
    for (g in groups){
      for (t in timepoints){
        coln <- append(coln, paste(g, t, "weight",sep = "_"))
      }
    }
  }
  
  coln <- sort(coln);
  edges_info <- gene_to_gene %>% mutate(relationship = "Gene-Gene") %>% 
    rename(from = fromNode, to = toNode) %>% 
    select(from, to, relationship, all_of(coln))
  

  #--------返回结果--------------------------------
  return(list(nodes = nodes, edges = edges, 
              gene_nodes = gene_nodes, 
              edges_info = edges_info,
              coln = coln))
  
}