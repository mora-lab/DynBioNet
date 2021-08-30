# dbname <- "my_data"
# groups <- "COPD_smoker"

get_alluvial.data <- function(dbname, groups){
  
  source("Functions/connect_userdb.R")
  dbcon <- connect_userdb(dbname)
  modules <- tbl(dbcon, "modules") %>% filter(group == groups) %>% 
    select(nodeName, timepoint, module) %>% 
    rename(gene = nodeName) %>%
    collect() %>% 
    as.data.frame() %>%
    distinct()
  
  #关闭数据库连接
  DBI::dbDisconnect(dbcon)
  
  return(modules)
}

# x <- get_alluvial.data(dbname, groups)
