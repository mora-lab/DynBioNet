# Gave database name for your data
ui_input_db_name <- textInput("user_db_name", "Name your project", value = "my_data")

# Input design ------
ui_input_design <- fileInput("design", "Upload design file",
                             multiple = FALSE,
                             accept = c("text/csv",
                                        "text/comma-separated-values,text/plain",
                                        ".csv"))

# Input expression data ---------
ui_input_exprs <- fileInput("exprs", "Upload expression data file",
                             multiple = FALSE,
                             accept = c("text/csv",
                                        "text/comma-separated-values,text/plain",
                                        ".csv"))


# Input edges -----------
ui_input_edges <- fileInput("edges", "Upload edges file",
                             multiple = FALSE,
                             accept = c("text/csv",
                                        "text/comma-separated-values,text/plain",
                                        ".csv"))

# Input nodes -----------
ui_input_nodes <- fileInput("modules", "Upload module file",
                             multiple = FALSE,
                             accept = c("text/csv",
                                        "text/comma-separated-values,text/plain",
                                        ".csv"))


# gene ID type --------------
ui_input_geneID_type <- selectInput("geneID_type", "Choose gene identifier",
                                    choices = c("SYMBOL", "ENTREZID"),
                                    selected = "SYMBOL")


# submit Button ------------------
ui_submit <- actionButton("submit", "Submit", 
                          icon = icon("upload",lib = "font-awesome"))

# 查看上传的数据信息-----------
unpload_files_info <- tabsetPanel(type = "tabs",
                                      tabPanel('Design file', DT::dataTableOutput('design_file')),
                                      tabPanel('Expression data file', DT::dataTableOutput('exprs_file')),
                                      tabPanel('Edge file', DT::dataTableOutput('edges_file')),
                                      tabPanel("Module file",DT::dataTableOutput('modules_file')))


upload_data_UI <- fluidPage(
  column(12,
         sidebarPanel(
           ui_input_db_name
           ,ui_input_design
           ,ui_input_exprs
           ,ui_input_edges
           ,ui_input_nodes
           ,ui_input_geneID_type
           ,ui_submit
         ),
         mainPanel(unpload_files_info  )
  )
)