"ADD JAR /usr/lib/hive-hcatalog/share/hcatalog/hive-hcatalog-core.jar;
USE mikhail;
CREATE EXTERNAL TABLE `TestSearchSatisfaction2` (`json_string` string)
  PARTITIONED BY (
    year int,
    month int,
    day int,
    hour int
  )
  STORED AS INPUTFORMAT
    'org.apache.hadoop.mapred.SequenceFileInputFormat'
  OUTPUTFORMAT
    'org.apache.hadoop.hive.ql.io.HiveIgnoreKeyTextOutputFormat'
  LOCATION
    '/wmf/data/raw/eventlogging/eventlogging_TestSearchSatisfaction2';"

x <- character()
for (day in 1:11) {
  for (hour in 0:23) {
    x <- c(x, sprintf("ALTER TABLE TestSearchSatisfaction2
  ADD PARTITION (year=2016,month=9,day=%0.0f,hour=%0.0f)
  LOCATION '/wmf/data/raw/eventlogging/eventlogging_TestSearchSatisfaction2/hourly/2016/09/%02.0f/%02.0f';", day, hour, day, hour))
  }
}
cat(paste0(x, collapse = '\n'))
