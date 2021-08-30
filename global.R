#################################################
# install packages
#################################################
if (!requireNamespace("BiocManager", quietly = TRUE))
	install.packages("BiocManager", dependencies = TRUE)
	
requiredPackages <- c("visNetwork", "stringr", "ggalluvial", "ggplot2", "shiny","DT", 
						"tidyverse","dplyr","xlsx", "readr", "tidyr", "RColorBrewer","RSQLite","downloader")			  
newPackages <- requiredPackages[!(requiredPackages %in% installed.packages()[,"Package"])]
if(length(newPackages)) BiocManager::install(newPackages, ask = TRUE)


#################################################
# 如果文件不存在，下载数据
#################################################
# 如果不存在这个data/databases/kegg_GO_info文件夹，就创建
if (!dir.exists("data/databases/kegg_GO_info")){
  dir.create("data/databases/kegg_GO_info", recursive = TRUE)  
}
if (!dir.exists("data/databases/user_data")){
  dir.create("data/databases/user_data", recursive = TRUE)  
}

# 如果文件不存在就下载
if (!file.exists("data/databases/kegg_GO_info/kegg_GO_info.sqlite")){
  downloader::download(url = "https://zenodo.org/record/5336148/files/kegg_GO_info.sqlite?download=1",
                       destfile = "data/databases/kegg_GO_info/kegg_GO_info.sqlite", mode = "wb", quiet = TRUE)
}

# 下载COPD-data
if (!file.exists("data/databases/user_data/COPD-data.sqlite")){
  downloader::download(url = "https://zenodo.org/record/5336148/files/COPD-data.sqlite?download=1",
                       destfile = "data/databases/user_data/COPD-data.sqlite",mode = "wb", quiet = TRUE)
}


#################################################
# 在这个文件的所有变量，都能用于server.R和ui.R
#################################################
library(shiny) #shiny包必用
library(tidyverse) #使用read_csv来读取文件
library(dplyr) #用于数据库查询操作和数据的整理
library(dbplyr) 
library(visNetwork) #用于作图
library(xlsx) #用于输出excel文件
# library(easyalluvial) # 用于alluvial作图的
# library(parcats) # 用于alluvial作图的
library(ggalluvial)
library(ggplot2)

# 默认情况下，shiny只允许上传的文件不超过5MB
# 如果需要更改shiny上传文件的大小限制，使用shiny.maxRequestSize option. 
# options(shiny.maxRequestSize = 30*1024^2)
# 表示允许上传的文件不超过30MB
options(shiny.maxRequestSize = 500*1024^2)


source("Functions/import_data.R")
# 获取所有数据库的名称，如果上传新的数据后，将会更新这个变量。更新这个变量使用<<- 来赋予全局变量的
all_db_names <- unlist(strsplit(list.files("data/databases/user_data/"), ".sqlite"))