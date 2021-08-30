#############################################################
# title: sum_weights
# target: 用来输出对每个时间点、每个组别的weight值求和
# input: 
#  - edges_info: 函数genes_relationships_for_KEGG.GO()结果中edges_info
#  - groups: 指定的groups
#  - timepoints: 指定的时间点
# Output:
#  - weight_sum_word: 描述每个组别每个时间点weight的总和
#############################################################

sum_weights <- function(edges_info, groups, timepoints){
  edge_gg <- edges_info %>% filter(relationship == "Gene-Gene") %>% select(-c(from, to, relationship)) #如果没有，怎么办，待会做
  sum_weights <- round(colSums(edge_gg, na.rm = TRUE),2) #每一列求和，并且保留两位小数
  
  
  status_timepoint_weight <- c() #用作相应的列的索引
  word_status_timepoint <- c() # 句子at M0 in COPD_smoker group， 以便后面对其添加
  for (g in groups){
    status_timepoint_weight = append(status_timepoint_weight, paste0(g, "_",timepoints, "_weight"))
    word_status_timepoint <- append(word_status_timepoint,paste0(" at ", timepoints, " in ", g, " group "))
  }
  
  weight_sum_word <- c() #合成xxx at time in group ...
  for (i in 1:length(sum_weights)){
    weight_sum_word <- append(weight_sum_word , paste0(sum_weights[i], word_status_timepoint[i]))
  }
  weight_sum_word <- paste0(weight_sum_word, collapse = ", ")
  
  return(weight_sum_word)
  
}