################################################################################
#1. Input
################################################################################
#1.0 设置连接数据库的名称--------------
gnb_db_input <- selectizeInput(inputId = "al_dbname", label = "Select your data", choices = all_db_names )
#设置组别选项,组别设置成单选==================================================
al_select_groups <- selectInput("al_groups", "Groups:",NULL,multiple = F )

################################################################################
#2. OutPut
################################################################################
#2.1 plot
alluvial_plot <- plotOutput("alluvial_plot",height = "800px") #使用的是ggalluvial包来做alluvial图
# alluvial_plot <- parcatsOutput("alluvial_plot",height = "800px",inline = TRUE) #使用parcats包来做alluvial图
#2.2 tabe
alluvial_tab <- tabsetPanel(type = "tabs",
            tabPanel('Alluvial data',DT::dataTableOutput('alluvial_tab')),
            tabPanel('Download',
                     downloadButton("download_alluvial.data", "download alluvial data")#, ##下载数据
                     )
            )

################################################################################
#3. Layout
################################################################################

alluvial_diagram_UI <- fluidPage(
  column(12,
         sidebarPanel(gnb_db_input,
                      al_select_groups),
         mainPanel(alluvial_plot)
         ),
  column(12,alluvial_tab)
  
  
)