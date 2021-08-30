# #before running this shiny, there has some data need to be using in UI
# source("before_run_shiny.R")
# 
# 
# #Interface for gene relationship in kEGG pathway/GO term
source("ui/genes_relationships_in_kegg_GO_for_UI.R")
# #Interface for gene neighborhood
source("ui/genes_neighborhood_for_UI.R")
# #Interface for alluvial_diagram
source("ui/alluvial_diagram_for_UI.R")


# upload_data_UI
source("ui/upload_data_UI.R")

#The whole web interface
navbarPage(title = "Time-Course DB Query",
           tabPanel("Upload your data", upload_data_UI)
           
           ,tabPanel("Genes Relationships in KEGG Pathway/GO Term"
                    ,genes_relationships_in_pathway_UI
                    )

           ,tabPanel("Genes Neighborhoods Relationships"
                    ,gene_neighbor_UI
                    ),

           tabPanel("Alluvial Diagram"
                    ,alluvial_diagram_UI
                    ),
           #设置打开shiny默认是在Genes Relationships in KEGG Pathway/GO Term界面
           selected = "Genes Relationships in KEGG Pathway/GO Term" 
           
)


