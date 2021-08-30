#两部分，一部分是input参数，一部分是output参数


################################################################################
#1. input
################################################################################
#1.0 设置连接数据库的名称--------------
db_input <- selectInput(inputId = "dbname", label = "Select your data",  choices = all_db_names, selected = "my_data")

#1.1 设置选择KEGG通路选项，可多选=========================================================
select_kegg <- selectizeInput("KEGGID", "KEGG ID or KEGG pathway:",NULL, multiple = T)

#1.2 设置选择GO选项,可多选===============================================================
select_go <- selectizeInput("GOID", "GO ID or GO Term:", choice = NULL, multiple = TRUE)


#1.3 设置时间选项，多选============================================================
select_time_point <- checkboxGroupInput("timepoints", "Timepoints:", NULL)

#1.4 设置组别选项,组别设置成可多选==================================================
select_groups <- selectInput("groups", "Groups:", NULL, selected = "COPD_smoker",multiple = T)

#1.5 设置weight选项=================================================================
# select_weight <- sliderInput("Weight", "Weight:",min = 0, max = 1, value = c(0,1) )
select_weight <- uiOutput("weight_ui")

#1.6 设置画图的对象是genes_to_genes, 还是genes_to_kegg/go==============================
plotObject_choices <- c("genes to genes" = "genes_to_genes",
                        "genes to KEGG " = "genes_to_kegg",
                        "genes to GO " = "genes_to_GO")
plotObject <- selectInput("plotObject", "Plot: ",
                          plotObject_choices, selected = "genes_to_genes", multiple = T)


################################################################################
#2. outPut
################################################################################
#2.1 设置输出visNetwork结果
visNetwork_plot <- visNetworkOutput("visNetwork_plot",  height = "800px")


#2.2 图的信息
plot_info <- p(strong(h5("In this plot: \n")),
               strong(textOutput("gene_num")), "\n",
               strong(textOutput("kegg_num")),"\n",
               strong(textOutput("go_num")),"\n",
               strong(textOutput("gg_edge_num")),"\n",
               strong(textOutput("gk_gene_num")),"\n",
               strong(textOutput("ggo_edge_num"))
               )

#2.3 设置数据下载按钮
button_download_gene_nodes <- downloadButton("download_gene_nodeTable", "download gene nodes information")
button_download_kegg_nodes <- downloadButton("download_kegg_nodeTable", "download KEGG nodes information")
button_download_GO_nodes <- downloadButton("download_GOnodeTable", "download GO nodes information")
button_download_edges <- downloadButton("download_edgeTable", "download edges information")
button_download_edges <- downloadButton("download_edgeTable", "download edges information")


#2.4 network coordination scores
netScore <- p(h4("C1. Number of gene-gene edges: "), strong(textOutput("net_gg_edge_num")), "\n", 
              h4("C2. Sum of gene-gene edge weights: "), strong(textOutput("weight_sum")),  "\n"
)


#2.5 --------#查看节点/edges数据--------------
nodes_edge_information <- tabsetPanel(type = "tabs",
                                tabPanel("Node information",
                                         tabsetPanel(tabPanel('Gene Node', DT::dataTableOutput('node_genes_information')),
                                                     tabPanel('KEGG Node',DT::dataTableOutput('node_kegg_information')),
                                                     tabPanel('GO Node', DT::dataTableOutput('node_go_information')),
                                                     tabPanel('Gene Expression', plotOutput("gene_expression_plot"))
                                                     #tabPanel('Gene Exprssion', verbatimTextOutput("shiny_return"))
                                                     )
                                         ),
                                tabPanel('Edge information', DT::dataTableOutput('edges_information')),
                                tabPanel('Network coordination scores', netScore),
                                tabPanel('Download', button_download_gene_nodes,
                                         button_download_kegg_nodes,
                                         button_download_GO_nodes,
                                         button_download_edges)
                                )



################################################################################
#3. layout
################################################################################
genes_relationships_in_pathway_UI  <- fluidPage(
  column(12,
         sidebarPanel(
           db_input, #数据库的名称
           select_kegg, #根据kegg来选择
           select_go, #根据GO来选择
           select_groups, ##设置组别选项
           select_time_point,#设置时间选项，多选
           conditionalPanel(condition = "input.timepoints.length > 0",select_weight),
		   #select_weight,
		   
           plotObject, #作图对象
           plot_info #总结图中的信息
           ),
         mainPanel(visNetwork_plot)
         ),

  column(12,nodes_edge_information)
)
