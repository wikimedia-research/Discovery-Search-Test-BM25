## REMOTELY
# Query:
events <- wmf::mysql_read("# BM25 A/B test EL data
  SELECT
    LEFT(`timestamp`, 8) AS date,
    event_subTest AS test_group,
    `timestamp` AS ts,
    event_uniqueId AS event_id,
    event_mwSessionId AS session_id,
    event_searchSessionId AS search_id,
    event_pageViewId AS page_id,
    event_searchToken AS cirrus_id,
    event_query AS query,
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
    );", "log")
# Fix dates & times:
events$date <- lubridate::ymd(events$date)
events$ts <- lubridate::ymd_hms(events$ts)
# Remove duplicate events:
events <- events[order(events$event_id, events$ts), ]
events <- events[!duplicated(events$event_id, fromLast = FALSE), ]
# Sort:
events <- events[order(events$date, events$session_id, events$ts), ]
# Save:
save(events, file = "ab-test_bm25.RData", ascii = FALSE, compress = "gzip")
## LOCALLY
# Transfer:
dir.create("data")
system("ssh-add -A && scp stat2:/home/bearloga/ab-test_bm25.RData data/")

## REMOTELY
results <- wmf::query_hive("ADD JAR hdfs:///wmf/refinery/current/artifacts/refinery-hive.jar;
CREATE TEMPORARY FUNCTION array_sum AS 'org.wikimedia.analytics.refinery.hive.ArraySumUDF';
SELECT
  event_logs.page_id AS page_id,
  event_logs.event_id AS event_id,
  search_results.page_id AS result_pids
FROM (
  SELECT
    get_json_object(json_string, '$.event.searchToken') AS cirrus_id,
    get_json_object(json_string, '$.event.subTest') AS group_id,
    get_json_object(json_string, '$.event.pageViewId') AS page_id,
    get_json_object(json_string, '$.event.uniqueId') AS event_id
  FROM mikhail.TestSearchSatisfaction2
  WHERE year = 2016 AND month = 9
    AND get_json_object(json_string, '$.event.source') = 'fulltext'
    AND get_json_object(json_string, '$.event.action') = 'searchResultPage'
    AND INSTR(get_json_object(json_string, '$.event.subTest'), 'bm25') > 0
) AS event_logs
LEFT JOIN (
  SELECT
    id,
    CASE
      WHEN backendusertests[0] = 'bm25:bm25_allfield' THEN 'bm25:allfield'
      WHEN backendusertests[0] = 'bm25:bm25_inclinks' THEN 'bm25:inclinks'
      WHEN backendusertests[0] = 'bm25:bm25_inclinks_pv' THEN 'bm25:inclinks_pv'
      WHEN backendusertests[0] = 'bm25:bm25_inclinks_pv_rev' THEN 'bm25:inclinks_pv_rev'
      ELSE 'bm25:control'
    END AS test_group,
    CASE
      WHEN array_sum(requests.hitstotal, -1) = 0 THEN NULL
      ELSE hits.pageid
    END AS page_id
  FROM wmf_raw.CirrusSearchRequestSet
  WHERE year = 2016 AND month = 9
    AND source = 'web' AND wikiid = 'enwiki'
    AND ARRAY_CONTAINS(requests.querytype, 'full_text')
    AND SIZE(backendusertests) = 1
    AND INSTR(backendusertests[0], 'bm25') > 0
    AND NOT ARRAY_CONTAINS(requests.hitstotal, -1)
) AS search_results
ON (event_logs.cirrus_id = search_results.id AND event_logs.group_id = search_results.test_group);")
# Clean-up:
results <- results[results$event_id != "", ]
results$result_pids[results$result_pids == "NULL"] <- NA
results$result_pids[results$result_pids == "[]"] <- NA
# Save:
readr::write_tsv(results, "ab-test_bm25_cirrus-results.tsv")
system("gzip -f ab-test_bm25_cirrus-results.tsv")
## LOCALLY
# Transfer:
system("ssh-add -A && scp stat2:/home/bearloga/ab-test_bm25_cirrus-results.tsv.gz data/")
