############################################################
# title: connect_userdb
# target: 用来连接用户上传后的数据库,或者新建数据库
# Input: 
# - userdb, 字符串.
# Output: 
# - 在data/databases/user_data的目录下会有一个sqlite的文件
############################################################
connect_userdb <- function(userdb ){
  DBI::dbConnect(RSQLite::SQLite()
                 ,paste0("data/databases/user_data/",userdb, ".sqlite")
  ) 
}