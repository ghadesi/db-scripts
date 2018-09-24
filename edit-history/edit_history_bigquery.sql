# create table with edit history of posts (title and body edits, comments)
#standardsql
SELECT *
FROM (
	SELECT
	  pv.PostId as PostId,
	  pv.PostTypeId as PostTypeId,
	  PostHistoryId as EventId,
	  CASE
		WHEN pv.PostHistoryTypeId=2 THEN "InitialBody"
		ELSE "BodyEdit"
	  END as Event,
	  UserId,
	  pv.CreationDate AS CreationDate
	FROM `sotorrent-org.2018_09_23.PostVersion` pv
	JOIN `sotorrent-org.2018_09_23.PostHistory` ph
	ON pv.PostHistoryId = ph.Id
	UNION ALL
	SELECT
	  tv.PostId as PostId,
	  tv.PostTypeId as PostTypeId,
	  PostHistoryId as EventId,
	  CASE
		WHEN tv.PostHistoryTypeId=1 THEN "InitialTitle"
		ELSE "TitleEdit"
	  END as Event,
	  UserId,
	  tv.CreationDate as CreationDate
	FROM `sotorrent-org.2018_09_23.TitleVersion` tv
	JOIN `sotorrent-org.2018_09_23.PostHistory` ph
	ON tv.PostHistoryId = ph.Id
	UNION ALL
	SELECT
	  PostId,
	  PostTypeId,
	  c.Id as EventId,
	  "Comment" AS Event,
	  UserId,
	  c.CreationDate as CreationDate
	FROM `sotorrent-org.2018_09_23.Comments` c
	JOIN `sotorrent-org.2018_09_23.Posts` p
	ON c.PostId = p.Id
);

-> `sotorrent-org.2018_09_23.EditHistory`


# create helper table that makes it easier to retrieve the parent id of a thread
#standardsql
SELECT
  Id as PostId,
  PostTypeId,
  CASE
    WHEN PostTypeId=1 THEN Id
    WHEN PostTypeId=2 THEN ParentId
  END as ParentId
FROM `sotorrent-org.2018_09_23.Posts`
WHERE PostTypeId=1  # only consider questions and answers
  OR PostTypeId=2; 

-> `sotorrent-org.2018_09_23.Threads`


# query to retrieve edit history of a thread using the post id of a question or an answer
#standardsql
SELECT *
FROM `sotorrent-org.2018_09_23.EditHistory`
WHERE PostId IN (
	SELECT PostId
	FROM `sotorrent-org.2018_09_23.Threads`
	WHERE ParentId = (
	  SELECT ParentID
	  FROM `sotorrent-org.2018_09_23.Threads`
	  WHERE PostId=3758880  # this is an answer id, the question id 3758606 yields the same result
	)
)
ORDER BY CreationDate;
