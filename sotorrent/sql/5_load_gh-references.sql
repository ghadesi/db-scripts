SET foreign_key_checks = 0;
# load file exported from BigQuery (see also https://cloud.google.com/sql/docs/mysql/import-export/)
LOAD DATA INFILE  '<PATH>PostReferenceGH.csv' INTO TABLE `PostReferenceGH`
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '\"'
ESCAPED BY '\"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(FileId, Repo, RepoOwner, RepoName, Branch, Path, FileExt, Size, Copies, PostId, @CommentId, SOUrl, GHUrl)
SET CommentId = nullif(@CommentId, '');
SET foreign_key_checks = 1;

SET foreign_key_checks = 0;
# load file exported from BigQuery (see also https://cloud.google.com/sql/docs/mysql/import-export/)
LOAD DATA INFILE  '<PATH>GHMatches.csv' INTO TABLE `GHMatches`
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '\"'
ESCAPED BY '\"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(FileId, PostIds, @MatchedLine)
SET MatchedLine = REPLACE(@MatchedLine, '&#xD;&#xA;', '\n');
SET foreign_key_checks = 1;

SET foreign_key_checks = 0;
# load file exported from BigQuery (see also https://cloud.google.com/sql/docs/mysql/import-export/)
LOAD DATA INFILE  '<PATH>GHCommits.csv' INTO TABLE `GHCommits`
CHARACTER SET utf8mb4
FIELDS TERMINATED BY ','
OPTIONALLY ENCLOSED BY '\"'
ESCAPED BY '\"'
LINES TERMINATED BY '\n'
IGNORE 1 LINES
(CommitId, Repo, RepoOwner, RepoName, PostId, @CommentId, SOUrl, GHUrl)
SET CommentId = nullif(@CommentId, '');
SET foreign_key_checks = 1;
