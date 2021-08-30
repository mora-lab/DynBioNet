function(input, output, session) {
  
  #######################################################
  # 1. 上传数据This for the upload_data_UI -----------
  #######################################################
  import_data_tab <- eventReactive(input$submit, {
    # 1.1 检查是否是NULL， 如果是NULL,则退出执行----
    req(input$user_db_name)
    # req(input$design)
    # req(input$exprs)  不用要求基因表达数据一定得上传
    # req(input$modules) 也不用要求模块必须得上传
    # req(input$edges)
    # req(input$geneID_type)  
    
    # 2.读取modules, edges, design 文件----------
    library(tidyverse)
    if(!is.null(input$design)){
      design = readr::read_csv(input$design$datapath) %>% distinct()
    }else{
      design = NULL  
      }
    if(!is.null(input$exprs)){
      exprs = readr::read_csv(input$exprs$datapath) %>% distinct() 
      }else{
        exprs = NULL
    }
    
    if(!is.null(input$edges)){
      edges = readr::read_csv(input$edges$datapath) %>% distinct()
    }else{
      edges = NULL
    }
    if(!is.null(input$modules)){
      modules = readr::read_csv(input$modules$datapath) %>% distinct()
    }else{
      modules = NULL  
    }
    
    list( design = design, exprs = exprs, edges = edges, modules = modules)
    
  })
  
  observeEvent(input$submit,{
    
    # 1.1 检查是否是NULL， 如果是NULL,则退出执行----
    req(input$user_db_name)
    # req(input$design)
    # req(input$exprs)  不用要求基因表达数据一定得上传
    # req(input$modules) 也不用要求模块必须得上传
    # req(input$edges)
    # req(input$geneID_type)  
    
    # 1.2 如果是都已经上传，点击submit就可以执行----
    import_data_tab <- import_data_tab()
    source("Functions/import_data.R")
    import_data(db_name = input$user_db_name,
                design = import_data_tab$design,
                exprs = import_data_tab$exprs,
                modules = import_data_tab$modules,
                edges = import_data_tab$edges,
                geneID_type = input$geneID_type)
    
    
    
    # 1.3 更新数据库的输入值----
    all_db_names <<- unlist(strsplit(list.files("data/databases/user_data/"), ".sqlite"))
    # 1.4 更新选项-选择数据库-----
    updateSelectInput(session, "dbname",choices = all_db_names, selected = input$db_name)
    updateSelectInput(session, "gnb_dbname",choices = all_db_names, selected =input$db_name)
    updateSelectInput(session, "al_dbname",choices = all_db_names, selected = input$db_name )
    print("GOOD!")
    
  })
  
  #==========================================
  # 查看上传的文件表格-----
  #==========================================
  #----design_file----------------------------
  output$design_file <- DT::renderDataTable({
    design_file <- import_data_tab()$design
    req(design_file)
    DT::datatable(design_file, options = list(pageLength = 10,
                                              scrollX = TRUE )) # 设置水平滚动条
  })
  #-----exprs_file---------------------------
  output$exprs_file <- DT::renderDataTable({
    exprs_file <- import_data_tab()$exprs
    req(exprs_file)
    DT::datatable(exprs_file, options = list(pageLength = 10, scrollX = TRUE))
  })
  #-----edges_file---------------------------
  output$edges_file <- DT::renderDataTable({
    edges_file <- import_data_tab()$edges
    req(edges_file)
    DT::datatable(edges_file, options = list(pageLength = 10, scrollX = TRUE))
  })
  #-----modules_file---------------------------
  output$modules_file <- DT::renderDataTable({
    modules_file <- import_data_tab()$modules
    req(modules_file)
    DT::datatable(modules_file, options = list(pageLength = 10, scrollX = TRUE))
  })



  
  #######################################################
  # 2. 选项值更新（设置输入值的选择） Genes Relationships in KEGG Pathway/GO Term----------
  #######################################################
  # 主要目的是因为数据库的输入值变了，相应的选项值也要发生改变，这里选用update*系列来更新选项值

  observe({

    # 2.1 获取用户指定的数据库的基本信息-----
    userdb <- input$dbname #用户选择的数据库
    source("Functions/basic_info.R")
    basic_info <- basic_info(userdb)
    
    # 2.2 连接数据库--------------
    source("Functions/connect_userdb.R")
    dbcon <- connect_userdb(userdb)
    print(all_db_names)
    

    #2.3 设置选择KEGG通路选项，可多选----
    kegg_table <- tbl(dbcon, "hsa_kegg") %>% collect() %>% as.data.frame() %>% distinct()
    kegg_choices <- append(sort(unique(kegg_table$KEGGID)), sort(unique(kegg_table$DESCRPTION)));rm(kegg_table)
    updateSelectizeInput(session, "KEGGID", choices = kegg_choices, server = TRUE)
    
    #2.4 设置选择GO选项,可多选----
    go_table <- tbl(dbcon, "go_data") %>% select(GOID, TERM) %>% collect() %>% as.data.frame() %>% distinct()
    go_choices <- append(unique(go_table$GOID), unique(go_table$TERM)); rm(go_table)
    updateSelectizeInput(session, 'GOID', choices = go_choices, server = TRUE)
    

    #2.5 设置时间选项，多选----
    timepoints_select <- basic_info$timepoints
    updateCheckboxGroupInput(session, "timepoints",choices = timepoints_select, selected = timepoints_select[1] )
    
    #2.6 设置组别选项,组别设置成可多选----
    group_choices <- basic_info$groups
    updateSelectInput(session, "groups", choices = group_choices, selected = group_choices[1])
    
    #2.7 设置weight选项----
    weights_select <- basic_info$weights
    if (!is.null(weights_select)){
      weights_select[1] <- floor(weights_select[1] ) #地板，不大于该数字的最大值
      weights_select[2] <- ceiling(weights_select[2]) #天花板，不小于该数字的最小整数
      updateSliderInput(session, "Weight", min = weights_select[1], max = weights_select[2], value = weights_select)
    }else{
      removeUI(selector = "div:has(> #Weight)")
    }
    
    
  })

  #######################################################
  # 3. 选项值更新（设置输入值的选择） Genes Neighborhoods Relationships----------
  #######################################################
  observe({

    # 3.1 获取用户指定的数据库的基本信息----
    userdb <- input$gnb_dbname #用户选择的数据库
    source("Functions/basic_info.R")
    basic_info <- basic_info(userdb)
    print(userdb)

    # 3.2 连接数据库--------------
    source("Functions/connect_userdb.R")
    dbcon <- connect_userdb(userdb)


    # 3.3 设置选择gene选项，可多选----

    genes <- tbl(dbcon, "hsa_geneIDs") %>% select(ENTREZID, SYMBOL) %>% collect() %>% as.data.frame() %>% distinct()
    genes <- sort(unique(append(genes$ENTREZID, genes$SYMBOL)))
    updateSelectizeInput(session, "gnb_genes", choices = genes, server = TRUE)

    #3.4 设置时间选项，多选----
    timepoints_select <- basic_info$timepoints
    updateCheckboxGroupInput(session, "gnb_timepoints",choices = timepoints_select, selected = timepoints_select[1] )


    #3.5 设置组别选项,组别设置成可多选----
    group_choices <- basic_info$groups
    updateSelectInput(session, "gnb_groups", choices = group_choices, selected = group_choices[1])

    #3.6 设置weight选项----
    weights_select <- basic_info$weights
    if (!is.null(weights_select)){
      weights_select[1] <- floor(weights_select[1] ) #地板，不大于该数字的最大值
      weights_select[2] <- ceiling(weights_select[2]) #天花板，不小于该数字的最小整数
      updateSliderInput(session, "gnb_Weight", min = weights_select[1], max = weights_select[2], value = weights_select) 
    }else{
      removeUI(selector = "div:has(> #gnb_Weight)")
    }

  })
  
  #######################################################
  # 4. 选项值更新（设置输入值的选择） Alluvial Diagram----------
  #######################################################
  observe({
    
    #4.1 获取用户指定的数据库的基本信息----
    userdb <- input$al_dbname #用户选择的数据库
    source("Functions/basic_info.R")
    basic_info <- basic_info(userdb)

    #4.2 设置组别选项,组别设置成可多选----
    group_choices <- basic_info$groups
    updateSelectInput(session, "al_groups", choices = group_choices, selected = group_choices[1])


  })
  
  ##############################################################################
  # 5. Genes Relationships in KEGG pathway/GO Term界面----------
  ##############################################################################
  #=========================================================
  # 5.1 所需的表格结果------
  #=========================================================
  genes_rel_for_KEGG.GO <- reactive({
    
    # 只有这些参数都存在的情况下，才会执行命令
    req(input$dbname)
    req(input$groups) #groups必须得选择才能运行
    req(input$plotObject)
    
    # 使用genes_relationships_for_KEGG.GO()来执行这个界面所需要的表格结果
    source("Functions/genes_relationships_for_KEGG.GO.R")
    dbname = input$dbname
    keggids = input$KEGGID
    goids = input$GOID
    groups = input$groups
    timepoints = input$timepoints
    weights = input$Weight
    plotObject = input$plotObject
    x <- genes_relationships_for_KEGG.GO(dbname, keggids, goids, groups, timepoints, weights, plotObject)
    
    return(x)
  })
  
  
  #=========================================================
  # 5.2 visNetwork-------
  #=========================================================

  output$visNetwork_plot <- renderVisNetwork({
    #------------作图-------------------------------
    nodes_edges <- genes_rel_for_KEGG.GO()$nodes_edges
    req(nodes_edges$nodes)
    req(nodes_edges$edges)
    source("Functions/plot_visNetwork.R")
    plot_visNetwork(nodes = nodes_edges$nodes, 
                    edges = nodes_edges$edges)
  })
  
  #========================================================
  # plot gene expression data
  #========================================================
  output$gene_expression_plot <- renderPlot({
    req(input$dbname)
    req(input$current_node_id)
    print(input$current_node_id)
    
    source("Functions/plot_gene_expression.R")
    plot_gene_expression(input$dbname, input$current_node_id$node)  
    
  })
  
  # output$shiny_return <- renderPrint({
  #   input$current_node_id
  # })
  
  #=========================================================
  # 5.3 node and edge information output------
  #=========================================================
  
  #------gene nodes----------------------------------
  # display 10 rows initially
  # 这个应该后面需要更改的是，根据boss的要求，添加表达数据的信息。
  # ideas是新增一个函数，用来获取这个基因对应的表达信息，然后再输出到界面上。
  output$node_genes_information <- DT::renderDataTable({
    gene_nodes <- genes_rel_for_KEGG.GO()$gene_nodes
    req(gene_nodes)
    DT::datatable(gene_nodes, options = list(pageLength = 10))
  })
  
  #-----kegg nodes------------------------------------
  output$node_kegg_information <- DT::renderDataTable({
    kegg_nodes = genes_rel_for_KEGG.GO()$kegg_nodes
    req(kegg_nodes)
    DT::datatable(kegg_nodes, options = list(pageLength = 10))
  })
  
  #-----GO nodes--------------------------------------
  output$node_go_information <- DT::renderDataTable({
    go_nodes <- genes_rel_for_KEGG.GO()$go_nodes
    req(go_nodes)
    DT::datatable(go_nodes, options = list(pageLength = 10))
  })
  
  #-----edge info-------------------------------------
  output$edges_information <- DT::renderDataTable({
    edges_info <- genes_rel_for_KEGG.GO()$edges_info
    req(edges_info)
    DT::datatable(edges_info, options = list(pageLength = 10))
  })
  
  #=========================================================
  # 5.4 node and edge information download------
  #=========================================================
  
  #------gene nodes------------------------------------
  output$download_gene_nodeTable <- downloadHandler(
    
    filename = function(){ "gene_Nodes_gene_relationships_in_kegg_GO.xls"},
    content = function(file){
      gene_nodes <- genes_rel_for_KEGG.GO()$gene_nodes
      library(xlsx)
      write.xlsx(gene_nodes,file, sheetName = "Gene node")}
  )

  # ------kegg nodes-----------------------------------
  output$download_kegg_nodeTable <- downloadHandler(
    filename = function(){ "kegg_Nodes_gene_relationships_in_kegg_GO.xls"},
    content = function(file){
      kegg_nodes = genes_rel_for_KEGG.GO()$kegg_nodes
      library(xlsx)
      write.xlsx(kegg_nodes,file, sheetName = "kegg node")}
  )
  
  #-------GO nodes-------------------------------------
  output$download_GOnodeTable <- downloadHandler(
    filename = function(){ "GO_Nodes_gene_relationships_in_kegg_GO.xls"},
    content = function(file){
      go_nodes <- genes_rel_for_KEGG.GO()$go_nodes
      library(xlsx)
      write.xlsx(go_nodes,file, sheetName = "GO_node")}
  )
  #-------edge info------------------------------------
  output$download_edgeTable <- downloadHandler(
    filename = function(){"Edges_gene_relationships_in_kegg_GO.xls" },
    content = function(file){
      edges_info <- genes_rel_for_KEGG.GO()$edges_info
      write.xlsx(edges_info, file, sheetName = "Edge")}
  )
  #=========================================================
  # 5.5 summary the plot information such like gene number, edge number------
  #=========================================================

  stats_info <- reactive({
    nd <- genes_rel_for_KEGG.GO()
    edge <- genes_rel_for_KEGG.GO()$edges_info
    list(gene_num = nrow(nd$gene_nodes),
         kegg_num = nrow(nd$kegg_nodes),
         GO_num = nrow(nd$go_nodes),
         edge_gg_num = nrow(edge[edge$relationship == "Gene-Gene",]),
         edge_gk_num = nrow(edge[edge$relationship == "Gene-KEGG",]),
         edge_ggo_num = nrow(edge[edge$relationship == "Gene-GO",])
    )
  })
  #=========================================================
  # 5.6 Output those summary the plot information when the number large than 0------
  #=========================================================
  output$gene_num <- renderText({req(stats_info()$gene_num); if(stats_info()$gene_num >0 ){paste0(stats_info()$gene_num, " genes")}})
  output$kegg_num <- renderText({req(stats_info()$kegg_num); if (stats_info()$kegg_num >0){paste0(stats_info()$kegg_num, " KEGG pathway")}})
  output$go_num <- renderText({req(stats_info()$GO_num); if (stats_info()$GO_num >0){paste0(stats_info()$GO_num, " GO Term")}})
  output$gg_edge_num <- renderText({req(stats_info()$edge_gg_num); if (stats_info()$edge_gg_num >0){paste0(stats_info()$edge_gg_num, " edges for genes to genes")}})
  output$gk_gene_num <- renderText({req(stats_info()$edge_gk_num); if (stats_info()$edge_gk_num >0){paste0(stats_info()$edge_gk_num, " edges for genes to KEGG")}})
  output$ggo_edge_num <- renderText({req(stats_info()$edge_ggo_num); if (stats_info()$edge_ggo_num >0){paste0(stats_info()$edge_ggo_num, "  edges for genes to GO")}})
  
  #=========================================================
  #5.7 output network coordination scores
  #=========================================================
  #------------------number of gene-to-gene relationship-----------------------
  output$net_gg_edge_num <- renderText({ req(stats_info()$edge_gg_num);stats_info()$edge_gg_num  })
  #-----------------weight sum -----------------------------------------------
  output$weight_sum <- renderText({
    # 如果groups和timepoints没有的话，就不输出
    req(input$groups)
    req(input$timepoints)
    req(genes_rel_for_KEGG.GO()$edges_info)
    source("Functions/sum_weights.R")
    sum_weights(edges_info = genes_rel_for_KEGG.GO()$edges_info, groups = input$groups, timepoints = input$timepoints)
  })
  
  ##############################################################
  # 6. gene neighborhoods relationships-----------
  ##############################################################
  #=============================================
  # 6.1 所需的表格结果------
  #=============================================
  genes_neighbor_rel <- reactive({
    req(input$gnb_dbname)
    req(input$gnb_genes)
    
    source("Functions/gene_neighborhoods_rel.R")
    dbname <- input$gnb_dbname
    geneids <- input$gnb_genes
    groups <- input$gnb_groups
    timepoints <- input$gnb_timepoints
    weights <- input$gnb_Weight
    plotObject <- input$gnb_plotObject
    x <- gene_neighborhoods_rel(dbname, geneids, groups, timepoints, weights, plotObject)
    return(x)
  })
  
  #=========================================================
  # 6.2 visNetwork-------
  #=========================================================
  
  output$gnb_visNetwork_plot <- renderVisNetwork({
    #------------作图-------------------------------
    nodes_edges <- genes_neighbor_rel()$nodes_edges
    req(nodes_edges$nodes)
    req(nodes_edges$edges)
    source("Functions/plot_gnb_visNetwork.R")
    plot_gnb_visNetwork(nodes = nodes_edges$nodes, 
                    edges = nodes_edges$edges)
  })
  
  
  #========================================================
  # plot gene expression data
  #========================================================
  output$gnb_gene_expression_plot <- renderPlot({
    req(input$gnb_dbname)
    req(input$gnb_current_node_id)
    # print(input$gnb_current_node_id)
    source("Functions/plot_gene_expression.R")
    plot_gene_expression(input$gnb_dbname, input$gnb_current_node_id$node)  
    
  })
  
  #=========================================================
  # 6.3 node and edge information output------
  #=========================================================
  
  #------gene nodes----------------------------------
  # display 10 rows initially
  # 这个应该后面需要更改的是，根据boss的要求，添加表达数据的信息。
  # ideas是新增一个函数，用来获取这个基因对应的表达信息，然后再输出到界面上。
  output$gnb_node_genes_information <- DT::renderDataTable({
    gene_nodes <- genes_neighbor_rel()$gene_nodes
    req(gene_nodes)
    DT::datatable(gene_nodes, options = list(pageLength = 10))
  })
  
  #-----kegg nodes------------------------------------
  output$gnb_node_kegg_information <- DT::renderDataTable({
    kegg_nodes = genes_neighbor_rel()$kegg_nodes
    req(kegg_nodes)
    DT::datatable(kegg_nodes, options = list(pageLength = 10))
  })
  
  #-----GO nodes--------------------------------------
  output$gnb_node_go_information <- DT::renderDataTable({
    go_nodes <- genes_neighbor_rel()$go_nodes
    req(go_nodes)
    DT::datatable(go_nodes, options = list(pageLength = 10))
  })
  
  #-----edge info-------------------------------------
  output$gnb_edges_information <- DT::renderDataTable({
    edges_info <- genes_neighbor_rel()$edges_info
    req(edges_info)
    DT::datatable(edges_info, options = list(pageLength = 10))
  })
  
  #=========================================================
  # 6.4 node and edge information download------
  #=========================================================
  
  #-----------gene node-----------------------
  output$gnb_download_gene_nodeTable <- downloadHandler(
    filename = function(){ "gene_Nodes_gene_neighbor.xls"},
    content = function(file){
      gene_nodes <- genes_neighbor_rel()$gene_nodes
      req(gene_nodes)
      library(xlsx)
      write.xlsx(gene_nodes,file, sheetName = "Gene node")
      return(file)
    }
  )
  #-----------KEGG node-----------------------
  output$gnb_download_kegg_nodeTable <- downloadHandler(
    filename = function(){ "kegg_Nodes_gene_neighbor.xls"},
    content = function(file){
      kegg_nodes <- genes_neighbor_rel()$kegg_nodes
      req(kegg_nodes)
      library(xlsx)
      write.xlsx(kegg_nodes,file, sheetName = "kegg node")
      return(file)
    }
  )
  #----------GO node--------------------------
  output$gnb_download_GO_nodeTable <- downloadHandler(
    filename = function(){ "GO_Nodes_gene_neighbor.xls"},
    content = function(file){
      go_nodes <- genes_neighbor_rel()$go_nodes
      req(go_nodes)
      library(xlsx)
      write.xlsx(go_nodes,file, sheetName = "GO_node")
      return(file)
    }
  )
  #---------edge------------------------------
  output$gnb_download_edgeTable <- downloadHandler(
    filename = function(){"Edges_gene_gene_neighbor.xls" },
    content = function(file){
      edges_info <- genes_neighbor_rel()$edges_info
      req(edges_info)
      library(xlsx)
      write.xlsx(edges_info, file, sheetName = "Edge")
    }
  )
  
  #=========================================================
  # 6.5 summary the plot information such like gene number, edge number------
  #=========================================================
  
  gnb_stats_info <- reactive({
    nd <- genes_neighbor_rel()
    edge <- genes_neighbor_rel()$edges_info
    list(gene_num = nrow(nd$gene_nodes),
         kegg_num = nrow(nd$kegg_nodes),
         GO_num = nrow(nd$go_nodes),
         edge_gg_num = nrow(edge[edge$relationship == "Gene-Gene",]),
         edge_gk_num = nrow(edge[edge$relationship == "Gene-KEGG",]),
         edge_ggo_num = nrow(edge[edge$relationship == "Gene-GO",]),
         edge_ggo_num_per_gene = nrow(edge[edge$relationship == "Gene-GO",])/nrow(nd$gene_node),
         edge_gk_num_per_gene = nrow(edge[edge$relationship == "Gene-KEGG",])/nrow(nd$gene_node)
    )
  })
  
  #=========================================================
  # 6.6 Output those summary the plot information when the number large than 0------
  #=========================================================
  output$gnb_gene_num <- renderText({req(gnb_stats_info()$gene_num); if(gnb_stats_info()$gene_num >0 ){paste0(gnb_stats_info()$gene_num, " genes")}})
  output$gnb_kegg_num <- renderText({req(gnb_stats_info()$kegg_num); if (gnb_stats_info()$kegg_num >0){paste0(gnb_stats_info()$kegg_num, " KEGG pathway")}})
  output$gnb_go_num <- renderText({req(gnb_stats_info()$GO_num); if (gnb_stats_info()$GO_num >0){paste0(gnb_stats_info()$GO_num, " GO Term")}})
  output$gnb_gg_edge_num <- renderText({req(gnb_stats_info()$edge_gg_num); if (gnb_stats_info()$edge_gg_num >0){paste0(gnb_stats_info()$edge_gg_num, " edges for genes to genes")}})
  output$gnb_gk_gene_num <- renderText({req(gnb_stats_info()$edge_gk_num); if (gnb_stats_info()$edge_gk_num >0){paste0(gnb_stats_info()$edge_gk_num, " edges for genes to KEGG")}})
  output$gnb_ggo_edge_num <- renderText({req(gnb_stats_info()$edge_ggo_num); if (gnb_stats_info()$edge_ggo_num >0){paste0(gnb_stats_info()$edge_ggo_num, "  edges for genes to GO")}})
  
  #=========================================================
  #6.7 output network coordination scores
  #=========================================================
  #------------------number of gene-to-gene relationship-----------------------
  output$gnb_net_gg_edge_num <- renderText({ req(gnb_stats_info()$edge_gg_num);gnb_stats_info()$edge_gg_num  })
  #-----------------weight sum -----------------------------------------------
  output$gnb_weight_sum <- renderText({
    # 如果groups和timepoints没有的话，就不输出
    req(input$gnb_groups)
    req(input$gnb_timepoints)
    req(genes_neighbor_rel()$edges_info)
    source("Functions/sum_weights.R")
    sum_weights(edges_info = genes_neighbor_rel()$edges_info, groups = input$gnb_groups, timepoints = input$gnb_timepoints)
  })
  
  #===========number of GO/KEGG =====================================
  output$gnb_net_go_num <- renderText({paste0("GO term: ",gnb_stats_info()$GO_num)})
  output$gnb_net_kegg_num <- renderText({paste0("KEGG pathway: ",gnb_stats_info()$kegg_num)})
  #===========number of GO/KEGG per gene=====================================
  output$gnb_net_kegg_num_per_gene <- renderText({paste0("KEGG pathway: ",round(gnb_stats_info()$edge_gk_num_per_gene),2)})
  output$gnb_net_go_num_per_gene <- renderText({paste0("GO term: ",round(gnb_stats_info()$edge_ggo_num_per_gene),2)})
  
  #-------------------
  #更新query_gene选项值
  #-------------------
  observe({ updateSelectInput(session, "query_gene", choices = input$gnb_genes, selected = input$gnb_genes[1])})
  observe({ updateSelectInput(session, "query_group", choices = input$gnb_groups, selected = input$gnb_groups[1])})
  
  #query_gene
  output$temporal_information <- DT::renderDataTable({
    
    req(input$query_gene)
    req(input$gnb_dbname)
    gene_nodes <- genes_neighbor_rel()$gene_nodes 
    temporal_rel <- genes_neighbor_rel()$temporal_rel
    req(gene_nodes)
    req(temporal_rel)

    source("Functions/get_temporal.tab.R")
    temporal_rel <- get_temporal.tab(dbname = input$gnb_dbname,
                                     qgene = input$query_gene,
                                     qgroup = input$query_group, 
                                     gene_nodes, x = temporal_rel)
    ###看看怎么把temporal_rel表格转换成boss要求的那种吧。
    DT::datatable(temporal_rel, options = list(pageLength = 10))
  })
  
  #############################################################################
  # 7. alluvial 图
  #############################################################################
  # 获取alluvial图的绘制数据
  alluvial.data <- reactive({
    req(input$al_dbname)
    req(input$al_groups)
    
    source("Functions/get_alluvial.data.R")
    get_alluvial.data(dbname = input$al_dbname, groups = input$al_groups)
  })
  
  # #alluvial 图--parcats---------
  # output$alluvial_plot <- render_parcats({
  #   alluvial.data <- alluvial.data()
  #   req(alluvial.data)
  #   parcats---------
  # 使用parcats包做图的话，才会用到
  # timepoints <- sort(unique(alluvial.data$timepoint))
  # # 将数组转换成依据时间来分布的列
  # alluvial.data <- tidyr::spread(alluvial.data, timepoint, module) %>% relocate(gene, all_of(timepoints))
  #   p = alluvial_wide(alluvial.data, id = gene, max_variables = ncol(alluvial.data))
  #   parcats(p, marginal_histograms = TRUE, data_input = alluvial.data, arrangement = "freeform")
  # })
  
  # alluvial 图--ggalluvial----------
  output$alluvial_plot <- renderPlot({
    alluvial.data <- alluvial.data()
    req(alluvial.data)
    source("Functions/plot_alluvail.data.R")
    plot_alluvail.data(alluvial.data)
  })
  
  #############################################################################
  #3.3 output alluvial.data information
  ############################################################################# 
  #alluvial data --------------------
  output$alluvial_tab <- DT::renderDataTable({
    alluvial.data = alluvial.data()
    req(alluvial.data)
    timepoints <- sort(unique(alluvial.data$timepoint))
    # 将数组转换成依据时间来分布的列
    alluvial.data <- tidyr::spread(alluvial.data, timepoint, module) %>% relocate(gene, all_of(timepoints))
    DT::datatable(alluvial.data, options = list(pageLength = 10))
  })
  
  #############################################################################
  #3.4 output alluvial.data download
  ############################################################################# 
  output$download_alluvial.data <- downloadHandler(
    filename = function(){paste0(input$al_groups,"_alluvial_data",".xls") },
    content = function(file){
      library(xlsx)
      alluvial.data = alluvial.data()
      req(alluvial.data)
      timepoints <- sort(unique(alluvial.data$timepoint))
      # 将数组转换成依据时间来分布的列
      alluvial.data <- tidyr::spread(alluvial.data, timepoint, module) %>% relocate(gene, all_of(timepoints))
      write.xlsx(alluvial.data,
                 file, sheetName = "alluvial.data")
    }
  )
  
}

