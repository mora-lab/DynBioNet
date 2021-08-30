################################################################################
# title: 
# target: 当groups只有一个的时候，用来重新定义visNetwork图中基因Node表格group列，这里只是将group的值找到而已。
# input: 
# - gene_to_gene: get_gene_to_gene2()的结果。
# - groups: 用户指定groups是什么。在运行这个函数时，groups只能有一个值。
# Output: 一个表格，包含两列：Gene, group
# time: August 23, 2021
# author: xiaowei
################################################################################
define_nodes_group <- function(gene_to_gene, groups){
  
  x <- rbind(gene_to_gene %>% select(fromNode, all_of(groups)) %>% rename(id = fromNode),
             gene_to_gene %>% select(toNode, all_of(groups)) %>% rename(id = toNode))
  names(x) = c("id", "by_group" )
  x <- x %>% group_by(id) %>%       
    summarise(group = paste( sort(unique(by_group)), collapse = "; "))
  head(x)
  
  return(x)
  
}