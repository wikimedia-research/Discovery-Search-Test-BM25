## Debugging
test_query_clustering <- function(search_id, linkage, threshold) {
  temp <- cluster_queries(
    searches$query[searches$search_id == search_id],
    searches$`result page IDs`[searches$search_id == search_id],
    linkage, threshold,
    debug = TRUE)
  print(temp$hc %>%
    ggdendro::ggdendrogram(rotate = FALSE) +
    geom_hline(yintercept = threshold, linetype = "dashed") +
    scale_y_reverse(breaks = seq(1, 0, -0.1)) +
    coord_flip() +
    theme(axis.text.x = element_text(angle = 0), axis.text.y = element_text(angle = 0)))
  return(temp)
}

thresholds <- c(complete = 0.45, average = 0.433, single = 0.301)
linkage <- "single"

test_query_clustering("bebbe975a46c96b9isj8gvu9", linkage, thresholds[linkage])
test_query_clustering("0056ff08261b1676ispqfpq4", linkage, thresholds[linkage])
test_query_clustering("006dc16f0a238bf8isk1h2mc", linkage, thresholds[linkage])
test_query_clustering("0088045fe5c7756aisqe8061", linkage, thresholds[linkage])
test_query_clustering("0196e2431ac8a5b9istap4tb", linkage, thresholds[linkage])
test_query_clustering("8467b1236281c151ist6jvl2", linkage, thresholds[linkage])
test_query_clustering("8a83a2a6257da633isnslryc", linkage, thresholds[linkage])
test_query_clustering("8af09cd4f35e2a6aistiwmt7", linkage, thresholds[linkage])
test_query_clustering("3d19ce39564f4db7issy961e", linkage, thresholds[linkage])
test_query_clustering("6a550000c1d085f5isoqdao4", linkage, thresholds[linkage])
test_query_clustering("2ece69a6b4a52bc6isqc455q", linkage, thresholds[linkage])

foo <- function(linkage) {
  return({
    test_query_clustering("3d19ce39564f4db7issy961e", linkage, thresholds[linkage])$output %>%
      filter(query %in% c("brtisth gazcomapny", "brtisth gaz", "brtisth gaz", "brtisth gas", "fusion shell bg group")) %>%
      arrange(query) %>%
      mutate(cluster = LETTERS[as.numeric(factor(cluster))])
  })
}
bind_rows(
  "Single" = foo("single"),
  "Complete" = foo("complete"),
  "Average" = foo("average"),
  .id = "linkage"
) %>% spread(linkage, cluster) %>%
  select(c(query, Single, Complete, Average)) %>%
  rename(`Search query` = query) %>%
  knitr::kable(format = "markdown", align = c("l", "c", "c", "c"))


searches$query[searches$search_id == "3d19ce39564f4db7issy961e"]

for (id in sample_n(filter(tally(group_by(searches, search_id)), n == 10), 20)$search_id ) {
  test_query_clustering(id, testing_threshold)
  title(main = paste0("\n", id))
  Sys.sleep(10)
}; rm(id)
