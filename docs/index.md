# A/B Test of BM25 Search Ranking
<a href = 'https://meta.wikimedia.org/wiki/User:EBernhardson_(WMF)'>Erik Bernhardson</a> (Engineering)  
<a href = 'https://www.mediawiki.org/wiki/User:DCausse_(WMF)'>David Causse</a> (Engineering)  
<a href = 'https://meta.wikimedia.org/wiki/User:TJones_(WMF)'>Trey Jones</a> (Engineering & Review)  
<a href = 'https://meta.wikimedia.org/wiki/User:MPopov_(WMF)'>Mikhail Popov</a> (Analysis & Report)  
<a href = 'https://meta.wikimedia.org/wiki/User:DTankersley_(WMF)'>Deb Tankersley</a> (Product Management)  
<a href = 'https://meta.wikimedia.org/wiki/User:CXie_(WMF)'>Chelsy Xie</a> (Review)  
`r as.character(Sys.Date(), '%d %B %Y')`  


```r
library(magrittr) # install.packages("magrittr")
library(data.table) # install.packages("data.table")
# devtools::install_github("hadley/ggplot2")
library(tidyverse) # install.packages("tidyverse")
# ^ for dplyr, tidyr, broom, etc.
library(binom) # install.packages("binom")
```

## Executive Summary

...

## Background

...

## Methods

Lorem ipsum dolor sit amet, consectetur adipiscing elit. Etiam interdum luctus velit ac euismod. Donec molestie ipsum at lorem pharetra porttitor. Sed nec finibus nisi, convallis laoreet leo. Curabitur tempus neque porttitor, pulvinar nisi ac, pulvinar augue. Quisque ac venenatis purus. In mollis ligula eget velit laoreet rhoncus. Sed eget nisi tempor quam rhoncus tempus. Nullam eleifend justo tellus, eget tempor lectus sodales id. Quisque quis lorem pharetra, rhoncus libero eget, rhoncus nisl. Duis massa dolor, luctus nec purus sed, euismod condimentum neque. Maecenas laoreet mauris at dui consequat gravida. Curabitur ut consequat lacus. In libero sem, dignissim ac ultricies eget, ornare eu ex. Phasellus sed lacus malesuada, luctus sapien et, gravida risus. Phasellus sed tempor metus. Morbi a dignissim tellus.

```sql
SELECT
  LEFT(`timestamp`, 8) AS date,
  event_subTest AS test_group,
  `timestamp` AS ts,
  event_uniqueId AS event_id,
  event_mwSessionId AS session_id,
  event_searchSessionId AS search_id,
  event_pageViewId AS page_id,
  event_searchToken AS cirrus_id,
  CAST(event_query AS CHAR CHARACTER SET utf8) AS query,
  event_hitsReturned AS n_results_returned,
  event_msToDisplayResults AS load_time,
  CASE WHEN event_action = 'searchResultPage' THEN 'SERP' ELSE 'click' END AS action,
  event_position AS position_clicked
FROM TestSearchSatisfaction2_15700292
WHERE
  LEFT(`timestamp`, 8) >= '20160830' AND LEFT(`timestamp`, 8) <= '20160910'
  AND event_source = 'fulltext'
  AND LEFT(event_subTest, 4) = 'bm25'
  AND (
    (event_action = 'searchResultPage' AND event_hitsReturned IS NOT NULL AND event_msToDisplayResults IS NOT NULL)
    OR
    (event_action = 'click' AND event_position IS NOT NULL AND event_position > -1)
  )
ORDER BY date, wiki, session_id, search_id, page_id, action DESC, timestamp;
```


```r
overlapping_results <- function(x) {
  if (all(is.na(x))) {
    return(diag(length(x)))
  }
  input <- strsplit(stringr::str_replace_all(x, "[\\[\\]]", ""), ",")
  output <- vapply(input, function(y) {
    temp <- vapply(input, function(z) { length(intersect(z, y)) }, 0L)
    # Normalize by diving by number of possible matches
    # e.g. if two queries have two results each that are
    #      exactly the same, that's worth more than if
    #      two queries have 20 results each but have
    #      only three in common
    temp <- temp/pmin(rep(length(y), length(input)), vapply(input, length, 0L))
    temp[is.na(x)] <- 0L
    return(temp)
  }, rep(0.0, length(input)))
  diag(output) <- 1L
  return(output)
}

cluster_queries <- function(queries, results, threshold = NULL, linkage = c("complete", "single", "average"), debug = FALSE) {
  if (length(queries) < 2) {
    return(1)
  }
  ## Debugging:
  # queries <- temp$query
  input <- data.frame(query = queries, stringsAsFactors = FALSE)
  x <- do.call(rbind, lapply(input$query, function(x) {
    # Compute for each x in input$query the normalized edit distance from x to input$query:
    normalized_distances <- adist(tolower(x), tolower(input$query), fixed = TRUE)/max(nchar(input$query))
    # Return:
    return(normalized_distances)
  }))
  # Decrease distance of queries that share results:
  overlaps <- overlapping_results(results)
  x <- x * (10^(-overlaps))
  # ^ if two queries have the exact same results, we make the new
  #   edit distance 0.1 of what their original edit distance is
  # Create distance object:
  y <- x[lower.tri(x, diag = FALSE)]
  d <- structure(
    y, Size = length(queries), Labels = queries, Diag = FALSE, Upper = FALSE,
    method = "levenshtein", class = "dist", call = match.call()
  )
  clustering_tree <- hclust(d, method = linkage[1])
  # When using average linkage, we may end up with funky trees
  #   that cannot be properly cut. So this logic helps against
  #   errors and yieds NAs instead.
  clusters <- tryCatch(
    cutree(clustering_tree, h = threshold),
    error = function(e) { return(NA) })
  if (all(is.na(clusters))) {
    clusters <- rep(clusters, nrow(input))
    names(clusters) <- input$query
  }
  output <- left_join(
    input,
    data.frame(query = names(clusters),
               cluster = as.numeric(clusters),
               stringsAsFactors = FALSE),
    by = "query")
  ## Debugging:
  if (debug) {
    return(
      list(
        original_distances = x / (10^(-overlaps)),
        overlaps = overlaps,
        modified_distances = d,
        output = output,
        hc = clustering_tree
      )
    )
  }
  return(output$cluster)
}
```

Sed finibus magna eu turpis laoreet, eu convallis ex convallis. Suspendisse potenti. Maecenas bibendum nunc at leo iaculis laoreet. Cras eros libero, sollicitudin sed ligula quis, molestie rutrum est. Aenean pharetra volutpat luctus. Nulla facilisi. Ut rutrum, augue ac faucibus maximus, dui sem lacinia lectus, ut egestas dui ligula sed enim. Nunc tincidunt velit eu augue tincidunt maximus. Nam nec ante nec lacus iaculis fringilla eu non turpis. Duis id urna vehicula, mattis urna sed, condimentum neque. Nunc eget lectus elementum, imperdiet odio suscipit, tristique mauris.

### PaulScore

PaulScore[[1]](#ref-1) is computed via the following steps:

#. Pick scoring factor $0 < F < 1$.
#. For $i$-th search session $S_i$ $(i = 1, \ldots, n)$ containing $m$ queries $Q_1, \ldots, Q_m$ and search result sets $\mathbf{R}_1, \ldots, \mathbf{R}_m$:
    (#) For each $j$-th search query $Q_j$ with result set $\mathbf{R}_j$, let $\nu_j$ be the query score: $$\nu_j = \sum_{k~\in~\{\text{0-based positions of clicked results in}~\mathbf{R}_j\}} F^k.$$
    (#) Let user's average query score $\bar{\nu}_{(i)}$ be $$\bar{\nu}_{(i)} = \frac{1}{m} \sum_{j = 1}^m \nu_j.$$
#. Then the PaulScore is the average of all users' average query scores: $$\text{PaulScore}(F)~=~\frac{1}{n} \sum_{i = 1}^n \bar{\nu}_{(i)}.$$

To test for statistical significance, we approximate the distribution of PaulScore$(F)$ via [boostrapping](https://en.wikipedia.org/wiki/Bootstrapping_(statistics)).


```r
approx_paulscore <- function(positions, F) {
  positions <- positions[!is.na(positions)] # when operating on 'events' dataset, SERP events won't have positions
  return(sum(F^positions))
}
```

## Results


```r
# Import events fetched from MySQL
load(path("data/ab-test_bm25.RData"))
events$test_group <- factor(
  events$test_group,
  levels = c("bm25:control", "bm25:allfield", "bm25:inclinks", "bm25:inclinks_pv", "bm25:inclinks_pv_rev"),
  labels = c("Control Group (tf–idf)", "Same query builder as control group but using BM25 as similarity function", "Using per-field query building with incoming links as QIF", "Using per-field query builder with incoming links and pageviews as QIFs", "Track typos in first 2 characters"))
cirrus <- readr::read_tsv(path("data/ab-test_bm25_cirrus-results.tsv.gz"), col_types = "ccc")
events <- left_join(events, cirrus, by = c("event_id", "page_id"))
rm(cirrus)
```


```r
# Correct for when user uses pagination or uses back button to go back to SERP after visiting a result.
# Start by assigning the same page_id to different SERPs that have exactly the same query:
temp <- events %>%
  filter(action == "SERP") %>%
  group_by(session_id, search_id, query) %>%
  mutate(new_page_id = min(page_id)) %>%
  ungroup %>%
  select(c(page_id, new_page_id)) %>%
  distinct
# We also need to do the same for associated click events:
events <- left_join(events, temp, by = "page_id"); rm(temp)
# Find out which SERPs are duplicated:
temp <- events %>%
  filter(action == "SERP") %>%
  arrange(new_page_id, ts) %>%
  mutate(dupe = duplicated(new_page_id, fromLast = FALSE)) %>%
  select(c(event_id, dupe))
events <- left_join(events, temp, by = "event_id"); rm(temp)
events$dupe[events$action == "click"] <- FALSE
# Remove duplicate SERPs and re-sort:
events <- events[!events$dupe & !is.na(events$new_page_id), ] %>%
  select(-c(page_id, dupe)) %>%
  rename(page_id = new_page_id) %>%
  arrange(date, session_id, search_id, page_id, desc(action), ts)
```

investigate if the multiple pages are from people going to the next page of the SERP


```r
# Summarize on a page-by-page basis:
searches <- events %>%
  group_by(`test group` = test_group, session_id, search_id, page_id) %>%
  filter("SERP" %in% action) %>% # filter out searches where we have clicks but not SERP events
  summarize(ts = ts[1], query = query[1],
            results = ifelse(n_results_returned[1] > 0, "some", "zero"),
            clickthrough = "click" %in% action,
            `first clicked result's position` = ifelse(clickthrough, position_clicked[2], NA),
            `result page IDs` = result_pids[1],
            `PaulScore (F=0.1)` = approx_paulscore(position_clicked[-1], 0.1),
            `PaulScore (F=0.5)` = approx_paulscore(position_clicked[-1], 0.5),
            `PaulScore (F=0.9)` = approx_paulscore(position_clicked[-1], 0.9)) %>%
  arrange(ts)
# Cluster queries
safe_clust <- function(search_id, page_ids, queries, results, threshold, linkage) {
  clusters <- cluster_queries(queries, results, threshold, linkage)
  if (length(clusters) != length(page_ids)) {
    stop("Number of cluster labels does not match number of searches for search session ", unlist(search_id)[1])
  } else {
    return(clusters)
  }
}
```


```r
searches %<>%
  group_by(`test group`, session_id, search_id) %>%
  mutate(
    cluster_single = safe_clust(search_id, page_id, query, `result page IDs`, 0.3, "single"),
    cluster_average = safe_clust(search_id, page_id, query, `result page IDs`, 0.433, "average"),
    cluster_complete = safe_clust(search_id, page_id, query, `result page IDs`, 0.377, "complete")
  )
```


```r
most_common <- function(x) {
  if (all(is.na(x))) {
    return(as.character(NA))
  } else {
     return(names(sort(table(x), decreasing = TRUE))[1])
  }
}
query_reformulations_single <- searches %>%
  group_by(`test group`, session_id, search_id, cluster_single) %>%
  # Count number of similar searches made in a single search session
  # (multiple search sessions per MW session allowed)
  summarize(
    reformulations = n() - 1,
    clickthrough = any(clickthrough),
    results = ifelse("some" %in% results, "some", "zero"),
    `most popular position clicked first` = most_common(`first clicked result's position`),
    `Avg PaulScore (F=0.1)` = mean(`PaulScore (F=0.1)`, na.rm = TRUE),
    `Avg PaulScore (F=0.5)` = mean(`PaulScore (F=0.5)`, na.rm = TRUE),
    `Avg PaulScore (F=0.9)` = mean(`PaulScore (F=0.9)`, na.rm = TRUE)
  ) %>%
  ungroup
query_reformulations_complete <- searches %>%
  group_by(`test group`, session_id, search_id, cluster_complete) %>%
  # Count number of similar searches made in a single search session
  # (multiple search sessions per MW session allowed)
  summarize(
    reformulations = n() - 1,
    clickthrough = any(clickthrough),
    results = ifelse("some" %in% results, "some", "zero"),
    `most popular position clicked first` = most_common(`first clicked result's position`),
    `Avg PaulScore (F=0.1)` = mean(`PaulScore (F=0.1)`, na.rm = TRUE),
    `Avg PaulScore (F=0.5)` = mean(`PaulScore (F=0.5)`, na.rm = TRUE),
    `Avg PaulScore (F=0.9)` = mean(`PaulScore (F=0.9)`, na.rm = TRUE)
  ) %>%
  ungroup
query_reformulations_average <- searches %>%
  ungroup %>%
  filter(!is.na(cluster_average)) %>%
  group_by(`test group`, session_id, search_id, cluster_average) %>%
  # Count number of similar searches made in a single search session
  # (multiple search sessions per MW session allowed)
  summarize(
    reformulations = n() - 1,
    clickthrough = any(clickthrough),
    results = ifelse("some" %in% results, "some", "zero"),
    `most popular position clicked first` = most_common(`first clicked result's position`),
    `Avg PaulScore (F=0.1)` = mean(`PaulScore (F=0.1)`, na.rm = TRUE),
    `Avg PaulScore (F=0.5)` = mean(`PaulScore (F=0.5)`, na.rm = TRUE),
    `Avg PaulScore (F=0.9)` = mean(`PaulScore (F=0.9)`, na.rm = TRUE)
  ) %>%
  ungroup
```


```r
bind_rows("Average linkage" = query_reformulations_average,
          "Complete linkage" = query_reformulations_complete,
          "Single linkage" = query_reformulations_single,
          .id = "linkage") %>%
  mutate(`query reformulations` = forcats::fct_lump(factor(reformulations), 3, other_level = "3+")) %>%
  group_by(linkage, `test group`, `query reformulations`) %>%
  tally %>%
  mutate(proportion = n/sum(n)) %>%
  ggplot(aes(x = `query reformulations`, y = proportion, fill = `test group`)) +
  geom_bar(stat = "identity", position = "dodge") +
  scale_y_continuous(labels = scales::percent_format()) +
  scale_fill_brewer("Test Group", palette = "Set1", guide = guide_legend(ncol = 2)) +
  facet_wrap(~ linkage, ncol = 3) +
  labs(y = "Proportion of searches", x = "Approximate number of query reformulations per search session",
       title = "Number of query reformulations by test group and linkage",
       subtitle = "Queries were grouped via hierarchical clustering using average/complete/single linkage and edit distance adjusted by search results in common") +
  theme(legend.position = "bottom")
```

![](index_files/figure-html/query_reformulations_edas-1.png)<!-- -->


```r
zrr_pages <- searches %>%
  group_by(`test group`, results) %>%
  tally %>%
  spread(results, n) %>%
  mutate(`zero results rate` = zero/(some + zero)) %>%
  ungroup
zrr_pages <- cbind(zrr_pages, as.data.frame(binom:::binom.bayes(zrr_pages$zero, n = zrr_pages$some + zrr_pages$zero)[, c("mean", "lower", "upper")]))
zrr_pages %>%
  ggplot(aes(x = reorder(`test group`, -`mean`), y = `mean`)) +
  geom_bar(stat = "identity", fill = "cornflowerblue") +
  geom_pointrange(aes(ymin = lower, ymax = upper)) +
  scale_y_continuous(labels = scales::percent_format()) +
  labs(x = "Test Group", y = "Zero Results Rate",
       title = "Zero results rate by test group",
       subtitle = "Defined as proportion of searches that did not yield any results") +
  coord_flip()
```

![](index_files/figure-html/zrr_eda-1.png)<!-- -->


```r
bootstrap_mean <- function(x, m) {
  n <- length(x)
  return(replicate(m, mean(x[sample.int(n, n, replace = TRUE)])))
}
set.seed(0) # for reproducibility
paulscores <- searches %>%
  ungroup %>%
  select(c(`test group`, `PaulScore (F=0.1)`, `PaulScore (F=0.5)`, `PaulScore (F=0.9)`)) %>%
  gather(`F value`, `PaulScore(F)`, -`test group`) %>%
  mutate(`F value` = sub("^PaulScore \\(F=(0\\.[159])\\)$", "F = \\1", `F value`)) %>%
  group_by(`test group`, `F value`) %>%
  summarize(
    Average = mean(`PaulScore(F)`),
    `Bootstrapped 95% Interval` = paste0(quantile(bootstrap_mean(`PaulScore(F)`, 1000), c(0.025, 0.975)), collapse = ",")
  ) %>%
  extract(
    `Bootstrapped 95% Interval`,
    into = c("Lower", "Upper"),
    regex = "(.*),(.*)",
    convert = TRUE
  )
```


```r
paulscores %>%
  ggplot(aes(x = `F value`, y = Average, color = `test group`)) +
  geom_pointrange(aes(ymin = Lower, ymax = Upper), position = position_dodge(width = 0.7)) +
  scale_color_brewer("Test Group", palette = "Set1", guide = guide_legend(ncol = 1)) +
  scale_y_continuous(limits = c(0.2, 0.35)) +
  labs(x = NULL, y = "Average PaulScore(F)",
       title = "Average PaulScore(F) by test group and value of F",
       subtitle = "") +
  geom_text(aes(label = sprintf("%.3f", Average), y = Upper + 0.01, vjust = "bottom"),
            position = position_dodge(width = 0.7)) +
  theme_minimal() +
  theme(legend.position = "bottom")
```

![](index_files/figure-html/paulscores_eda-1.png)<!-- -->

Lorem ipsum dolor sit amet, consectetur adipiscing elit. Etiam interdum luctus velit ac euismod. Donec molestie ipsum at lorem pharetra porttitor. Sed nec finibus nisi, convallis laoreet leo. Curabitur tempus neque porttitor, pulvinar nisi ac, pulvinar augue. Quisque ac venenatis purus. In mollis ligula eget velit laoreet rhoncus. Sed eget nisi tempor quam rhoncus tempus. Nullam eleifend justo tellus, eget tempor lectus sodales id. Quisque quis lorem pharetra, rhoncus libero eget, rhoncus nisl. Duis massa dolor, luctus nec purus sed, euismod condimentum neque. Maecenas laoreet mauris at dui consequat gravida. Curabitur ut consequat lacus. In libero sem, dignissim ac ultricies eget, ornare eu ex. Phasellus sed lacus malesuada, luctus sapien et, gravida risus. Phasellus sed tempor metus. Morbi a dignissim tellus.

### Engagement

Sed finibus magna eu turpis laoreet, eu convallis ex convallis. Suspendisse potenti. Maecenas bibendum nunc at leo iaculis laoreet. Cras eros libero, sollicitudin sed ligula quis, molestie rutrum est. Aenean pharetra volutpat luctus. Nulla facilisi. Ut rutrum, augue ac faucibus maximus, dui sem lacinia lectus, ut egestas dui ligula sed enim. Nunc tincidunt velit eu augue tincidunt maximus. Nam nec ante nec lacus iaculis fringilla eu non turpis. Duis id urna vehicula, mattis urna sed, condimentum neque. Nunc eget lectus elementum, imperdiet odio suscipit, tristique mauris.

### PaulScore Results

Sed finibus magna eu turpis laoreet, eu convallis ex convallis. Suspendisse potenti. Maecenas bibendum nunc at leo iaculis laoreet. Cras eros libero, sollicitudin sed ligula quis, molestie rutrum est. Aenean pharetra volutpat luctus. Nulla facilisi. Ut rutrum, augue ac faucibus maximus, dui sem lacinia lectus, ut egestas dui ligula sed enim. Nunc tincidunt velit eu augue tincidunt maximus. Nam nec ante nec lacus iaculis fringilla eu non turpis. Duis id urna vehicula, mattis urna sed, condimentum neque. Nunc eget lectus elementum, imperdiet odio suscipit, tristique mauris.

## References

### Reading

<ol><li id="ref-1"><a href = "https://www.mediawiki.org/wiki/Wikimedia_Discovery/Search/Glossary#PaulScore">Definition of PaulScore</a> on Wikimedia Discovery/Search/Glossary</li></ol>

### Software

<ol start = "2" style = "list-style-type: decimal"><li id="ref-5">R Core Team (2016). _R: A Language and Environment for StatisticalComputing_. R Foundation for Statistical Computing, Vienna,Austria.  https://www.R-project.org/</li><li id="ref-6">Bache SM and Wickham H (2014). _magrittr: A Forward-Pipe Operatorfor R_. R package version 1.5, https://CRAN.R-project.org/package=magrittr</li><li id="ref-7">Wickham H (2009). _ggplot2: Elegant Graphics for Data Analysis_.Springer-Verlag New York. ISBN 978-0-387-98140-6, http://ggplot2.org</li><li id="ref-8">Wickham H and Francois R (2016). _dplyr: A Grammar of DataManipulation_. R package version 0.5.0, https://CRAN.R-project.org/package=dplyr</li><li id="ref-9">Wickham H (2016). _tidyr: Easily Tidy Data with `spread()` and`gather()` Functions_. R package version 0.6.0, https://CRAN.R-project.org/package=tidyr</li><li id="ref-10">Wickham H, Hester J and Francois R (2016). _readr: Read TabularData_. R package version 1.0.0, https://CRAN.R-project.org/package=readr</li><li id="ref-11">Dorai-Raj S (2014). _binom: Binomial Confidence Intervals ForSeveral Parameterizations_. R package version 1.1-1, https://CRAN.R-project.org/package=binom</li><li id="ref-12">Allaire J, Cheng J, Xie Y, McPherson J, Chang W, Allen J, WickhamH, Atkins A and Hyndman R (2016). _rmarkdown: Dynamic Documentsfor R_. R package version 1.0, https://CRAN.R-project.org/package=rmarkdown</li><li id="ref-13">Xie Y (2016). _knitr: A General-Purpose Package for Dynamic ReportGeneration in R_. R package version 1.14, http://yihui.name/knitr/</li><li id="ref-14">Xie Y (2015). _Dynamic Documents with R and knitr_, 2nd edition.Chapman and Hall/CRC, Boca Raton, Florida. ISBN 978-1498716963, http://yihui.name/knitr/</li><li id="ref-15">Xie Y (2014). "knitr: A Comprehensive Tool for ReproducibleResearch in R." In Stodden V, Leisch F and Peng RD (eds.),_Implementing Reproducible Computational Research_. Chapman andHall/CRC. ISBN 978-1466561595, http://www.crcpress.com/product/isbn/9781466561595</li></ol>