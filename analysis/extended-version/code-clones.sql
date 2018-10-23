# normalize post blocks, calculate normalized line count, calculate fingerprint of normalized content
SELECT
  Id,
  PostBlockTypeId,
  PostId,
  PostTypeId,
  ParentId,
  CreationDate,
  LineCount,
  LineCountNormalized,
  FARM_FINGERPRINT(ContentNormalized) AS ContentNormalizedHash,
  Content,
  ContentNoEmptyLines,
  ContentNormalized
FROM (
  SELECT
    Id,
    PostBlockTypeId,
    PostId,
    PostTypeId,
    ParentId,
    CreationDate,
	LineCount,
    ARRAY_LENGTH(SPLIT(ContentNoEmptyLines, '&#xD;&#xA;')) AS LineCountNormalized,
    Content,
    ContentNoEmptyLines,
    REGEXP_REPLACE(ContentNoEmptyLines, r'\s|(&#xA;)|(&#xD;)|[^a-zA-Z0-9]', '') AS ContentNormalized
  FROM (
    SELECT
      pbv.Id AS Id,
  	  PostBlockTypeId,
	  PostId,
	  PostTypeId,
	  CASE
	    WHEN ParentId IS NULL THEN PostId
	    ELSE ParentId
	  END AS ParentId,
	  CreationDate,
	  LineCount,
	  Content,
	  REGEXP_REPLACE(REGEXP_REPLACE(REGEXP_REPLACE(Content,
	    r'\s*[()[\]{}]+\s*&#xD;\s*&#xA;\s*', ''), # remove lines only containing brackets
	    r'(\s*&#xD;\s*&#xA;\s*)+', '&#xD;&#xA;'), # normalize new lines
	    r'(\s*&#xD;\s*&#xA;\s*)+$', '') # remove new lines in last line
	    AS ContentNoEmptyLines
    FROM
      `sotorrent-org.2018_09_23.PostBlockVersion` pbv
    JOIN
      `sotorrent-org.2018_09_23.Posts` p
    ON
      pbv.PostId = p.Id
    WHERE
      PostHistoryId = (
	    SELECT
	      MAX(PostHistoryId)
	    FROM
		  `sotorrent-org.2018_09_23.PostVersion` pv
	    WHERE
		  pv.PostId = pbv.PostId
      )
  )
);

=> sotorrent-extension.2018_09_23.MostRecentPostBlockVersionNormalized
  

# count clones
SELECT
  ContentNormalizedHash,
  PostBlockTypeId,
  STRING_AGG(CAST(PostId AS STRING), ' ') AS PostIds,
  MIN(LineCountNormalized) AS LineCount,
  COUNT(DISTINCT ParentId) AS ThreadCount,
  ContentNormalized
FROM
	`sotorrent-extension.2018_09_23.MostRecentPostBlockVersionNormalized`
GROUP BY
	ContentNormalizedHash, ContentNormalized, PostBlockTypeId;

=> sotorrent-extension.2018_09_23.MostRecentPostBlockVersionNormalizedClones


# copy clones without content (for export)
SELECT
  ContentNormalizedHash,
  PostBlockTypeId,
  PostIds,
  LineCount,
  ThreadCount
FROM
	`sotorrent-extension.2018_09_23.MostRecentPostBlockVersionNormalizedClones`;

=> sotorrent-extension.2018_09_23.MostRecentPostBlockVersionNormalizedClonesExport


# retrieve initial sample for web visualization
SELECT
  ContentNormalizedHash,
  PostId,
  PostTypeId,
  ParentId,
  CreationDate
FROM
  `sotorrent-extension.2018_09_23.MostRecentPostBlockVersionNormalized`
WHERE 
  ContentNormalizedHash IN (
    SELECT
      ContentNormalizedHash
    FROM 
      `sotorrent-extension.2018_09_23.MostRecentPostBlockVersionNormalizedClones`
    WHERE
      PostBlockTypeId = 2 AND LineCount > 5 AND ThreadCount >= 10
)
ORDER BY ContentNormalizedHash, CreationDate, PostId;

=> sotorrent-extension.2018_09_23.CodeClonesSample


# retrieve data for inital sample
SELECT
  ContentNormalizedHash,
  ARRAY_LENGTH(SPLIT(Content, '&#xD;&#xA;')) AS LineCount,
  ThreadCount,
  Content
FROM (
  SELECT
    clones.ContentNormalizedHash AS ContentNormalizedHash,
    MIN(Content) as Content,
	MAX(ThreadCount) as ThreadCount
  FROM
    `sotorrent-extension.2018_09_23.MostRecentPostBlockVersionNormalized` post_blocks
  JOIN
    `sotorrent-extension.2018_09_23.MostRecentPostBlockVersionNormalizedClones` clones
  ON
    post_blocks.ContentNormalizedHash = clones.ContentNormalizedHash
  WHERE
    clones.PostBlockTypeId = 2 AND clones.LineCount > 5 AND ThreadCount >= 10
  GROUP BY ContentNormalizedHash
);

=> sotorrent-extension.2018_09_23.CodeClonesSampleData


# retrieve second sample for web visualization
SELECT
  ContentNormalizedHash,
  PostId,
  PostTypeId,
  ParentId,
  CreationDate
FROM
  `sotorrent-extension.2018_09_23.MostRecentPostBlockVersionNormalized`
WHERE 
  ContentNormalizedHash IN (
    SELECT
      ContentNormalizedHash
    FROM 
      `sotorrent-extension.2018_09_23.MostRecentPostBlockVersionNormalizedClones`
    WHERE
      PostBlockTypeId = 2 AND LineCount >= 20 AND ThreadCount >= 5
)
ORDER BY ContentNormalizedHash, CreationDate, PostId;

=> sotorrent-extension.2018_09_23.CodeClonesSample2


# retrieve data for second sample
SELECT
  ContentNormalizedHash,
  ARRAY_LENGTH(SPLIT(Content, '&#xD;&#xA;')) AS LineCount,
  ThreadCount,
  Content
FROM (
  SELECT
    clones.ContentNormalizedHash AS ContentNormalizedHash,
    MIN(Content) as Content,
  MAX(ThreadCount) as ThreadCount
  FROM
    `sotorrent-extension.2018_09_23.MostRecentPostBlockVersionNormalized` post_blocks
  JOIN
    `sotorrent-extension.2018_09_23.MostRecentPostBlockVersionNormalizedClones` clones
  ON
    post_blocks.ContentNormalizedHash = clones.ContentNormalizedHash
  WHERE
    clones.PostBlockTypeId = 2 AND clones.LineCount >= 20 AND ThreadCount >= 5
  GROUP BY ContentNormalizedHash
);

=> sotorrent-extension.2018_09_23.CodeClonesSample2Data


# Retrieve links from posts containing clones (second sample)
SELECT
  ContentNormalizedHash,
  clones.PostId,
  PostTypeId,
  ParentId,
  RootDomain,
  CompleteDomain,
  Url
FROM
  `sotorrent-org.2018_09_23.PostVersionUrl` post_version_url
JOIN
  `sotorrent-extension.2018_09_23.CodeClonesSample2` clones
ON
  post_version_url.PostId = clones.PostId
WHERE
  PostHistoryId = (
  SELECT
    MAX(PostHistoryId)
  FROM
    `sotorrent-org.2018_09_23.PostVersion` pv
  WHERE
    pv.PostId = post_version_url.PostId
  );
  
=> sotorrent-extension.2018_09_23.CodeClonesSample2Links
  

# Retrieve and normalize SO links (second sample)
SELECT
  ContentNormalizedHash,
  PostId,
  PostTypeId,
  ParentId,
  REGEXP_EXTRACT(Url, r'https:\/\/stackoverflow\.com\/(?:a|q)\/([\d]+)') AS LinkedPostId,
  CASE
	WHEN REGEXP_CONTAINS(Url, r'https:\/\/stackoverflow\.com\/q') THEN 1
	WHEN REGEXP_CONTAINS(Url, r'https:\/\/stackoverflow\.com\/a') THEN 2
	ELSE NULL
  END AS LinkedPostTypeId,
  Url
FROM (
  SELECT
    ContentNormalizedHash,
    PostId,
    PostTypeId,
    ParentId,
    CASE
      WHEN REGEXP_CONTAINS(Url, r'(https:\/\/stackoverflow\.com\/a\/[\d]+)')
	    THEN REGEXP_EXTRACT(Url, r'(https:\/\/stackoverflow\.com\/a\/[\d]+)')
      WHEN REGEXP_CONTAINS(Url, r'(https:\/\/stackoverflow\.com\/q\/[\d]+)')
	    THEN REGEXP_EXTRACT(Url, r'(https:\/\/stackoverflow\.com\/q\/[\d]+)')
      WHEN REGEXP_CONTAINS(Url, r'https:\/\/stackoverflow\.com\/questions\/[\d]+\/[^\s\/\#]+(?:\/|\#)([\d]+)')
	    THEN CONCAT("https://stackoverflow.com/a/", REGEXP_EXTRACT(Url, r'https:\/\/stackoverflow\.com\/questions\/[\d]+\/[^\s\/\#]+(?:\/|\#)([\d]+)'))
      WHEN REGEXP_CONTAINS(Url, r'(https:\/\/stackoverflow\.com\/questions\/[\d]+)')
	    THEN CONCAT("https://stackoverflow.com/q/", REGEXP_EXTRACT(Url, r'https:\/\/stackoverflow\.com\/questions\/([\d]+)'))
      ELSE Url
    END AS Url
  FROM (
    SELECT
      ContentNormalizedHash,
      PostId,
      PostTypeId,
      ParentId,
      REGEXP_REPLACE(LOWER(Url), r'^http:', 'https:') AS Url
    FROM
      `sotorrent-extension.2018_09_23.CodeClonesSample2Links`
    WHERE
      RootDomain = "stackoverflow.com"
   )
);

=> sotorrent-extension.2018_09_23.CodeClonesSample2LinksSO


# Count SO links per code block hash
SELECT ContentNormalizedHash, LinkedPostId, LinkedPostTypeId, COUNT(PostId) AS PostCount
FROM `sotorrent-extension.2018_09_23.CodeClonesSample2LinksSO`
WHERE LinkedPostId IS NOT NULL
GROUP BY ContentNormalizedHash, LinkedPostId, LinkedPostTypeId;

=> sotorrent-extension.2018_09_23.CodeClonesSample2LinksSOExport


# Count non-SO links per code block hash
SELECT ContentNormalizedHash, Url, COUNT(PostId) AS PostCount
FROM `sotorrent-extension.2018_09_23.CodeClonesSample2Links`
WHERE RootDomain <> "stackoverflow.com"
GROUP BY ContentNormalizedHash, Url;

=> sotorrent-extension.2018_09_23.CodeClonesSample2LinksNonSOExport



# retrieve data to analysis linking of clones
SELECT
  ContentNormalizedHash,
  PostId,
  PostTypeId,
  ParentId
FROM
  `sotorrent-extension.2018_09_23.MostRecentPostBlockVersionNormalized`
WHERE 
  ContentNormalizedHash IN (
    SELECT
      ContentNormalizedHash
    FROM 
      `sotorrent-extension.2018_09_23.MostRecentPostBlockVersionNormalizedClones`
    WHERE
      PostBlockTypeId = 2 AND LineCount > 5 AND ThreadCount >= 2
);

=> sotorrent-extension.2018_09_23.CodeClonesSampleLarge



# Retrieve and normalize SO links
SELECT
  ContentNormalizedHash,
  PostId,
  PostTypeId,
  ParentId,
  REGEXP_EXTRACT(Url, r'https:\/\/stackoverflow\.com\/(?:a|q)\/([\d]+)') AS LinkedPostId,
  CASE
	WHEN REGEXP_CONTAINS(Url, r'https:\/\/stackoverflow\.com\/q') THEN 1
	WHEN REGEXP_CONTAINS(Url, r'https:\/\/stackoverflow\.com\/a') THEN 2
	ELSE NULL
  END AS LinkedPostTypeId,
  Url
FROM (
  SELECT
    ContentNormalizedHash,
    PostId,
    PostTypeId,
    ParentId,
    CASE
      WHEN REGEXP_CONTAINS(Url, r'(https:\/\/stackoverflow\.com\/a\/[\d]+)')
	    THEN REGEXP_EXTRACT(Url, r'(https:\/\/stackoverflow\.com\/a\/[\d]+)')
      WHEN REGEXP_CONTAINS(Url, r'(https:\/\/stackoverflow\.com\/q\/[\d]+)')
	    THEN REGEXP_EXTRACT(Url, r'(https:\/\/stackoverflow\.com\/q\/[\d]+)')
      WHEN REGEXP_CONTAINS(Url, r'https:\/\/stackoverflow\.com\/questions\/[\d]+\/[^\s\/\#]+(?:\/|\#)([\d]+)')
	    THEN CONCAT("https://stackoverflow.com/a/", REGEXP_EXTRACT(Url, r'https:\/\/stackoverflow\.com\/questions\/[\d]+\/[^\s\/\#]+(?:\/|\#)([\d]+)'))
      WHEN REGEXP_CONTAINS(Url, r'(https:\/\/stackoverflow\.com\/questions\/[\d]+)')
	    THEN CONCAT("https://stackoverflow.com/q/", REGEXP_EXTRACT(Url, r'https:\/\/stackoverflow\.com\/questions\/([\d]+)'))
      ELSE Url
    END AS Url
  FROM (
    SELECT
      ContentNormalizedHash,
      PostId,
      PostTypeId,
      ParentId,
      REGEXP_REPLACE(LOWER(Url), r'^http:', 'https:') AS Url
    FROM (
	SELECT
	  ContentNormalizedHash,
	  clones.PostId,
	  PostTypeId,
	  ParentId,
	  RootDomain,
	  CompleteDomain,
	  Url
	FROM
	  `sotorrent-org.2018_09_23.PostVersionUrl` post_version_url
	JOIN
	  `sotorrent-extension.2018_09_23.CodeClonesSampleLarge` clones
	ON
	  post_version_url.PostId = clones.PostId
	WHERE
	  PostHistoryId = (
	  SELECT
		MAX(PostHistoryId)
	  FROM
		`sotorrent-org.2018_09_23.PostVersion` pv
	  WHERE
		pv.PostId = post_version_url.PostId
	  )
    ) WHERE
      RootDomain = "stackoverflow.com"
   )
);

=> sotorrent-extension.2018_09_23.CodeClonesSampleLargeLinksSO


# Export links to SO questions or answers
SELECT
  ContentNormalizedHash,
  PostId,
  PostTypeId,
  ParentId,
  LinkedPostId,
  LinkedPostTypeId
FROM
  `sotorrent-extension.2018_09_23.CodeClonesSampleLargeLinksSO`
WHERE
  LinkedPostId IS NOT NULL;

=> sotorrent-extension.2018_09_23.CodeClonesSampleLargeLinksSOExport


# Retrieve external links
SELECT
  ContentNormalizedHash,
  clones.PostId as PostId,
  PostTypeId,
  ParentId,
  RootDomain,
  CompleteDomain,
  Url
FROM
  `sotorrent-org.2018_09_23.PostVersionUrl` post_version_url
JOIN
  `sotorrent-extension.2018_09_23.CodeClonesSampleLarge` clones
ON
  post_version_url.PostId = clones.PostId
WHERE
  PostHistoryId = (
    SELECT
    MAX(PostHistoryId)
    FROM
    `sotorrent-org.2018_09_23.PostVersion` pv
    WHERE
    pv.PostId = post_version_url.PostId
  )
  AND RootDomain <> "stackoverflow.com";

=> sotorrent-extension.2018_09_23.CodeClonesSampleLargeLinksNonSO


# How many posts contain links to other SO posts?

SELECT COUNT(DISTINCT PostId) FROM `sotorrent-extension.2018_09_23.CodeClonesSampleLarge`; 
# 462,673

SELECT COUNT(DISTINCT PostId) FROM `sotorrent-extension.2018_09_23.CodeClonesSampleLargeLinksSO` WHERE LinkedPostId IS NOT NULL;
# 41,054 (8.9%)

SELECT COUNT(DISTINCT PostId) FROM `sotorrent-extension.2018_09_23.CodeClonesSampleLargeLinksNonSO`;
# 153,986 (33.3%)

# either SO or external
SELECT COUNT(DISTINCT PostId)
FROM (
  SELECT DISTINCT PostId FROM `sotorrent-extension.2018_09_23.CodeClonesSampleLargeLinksSO` WHERE LinkedPostId IS NOT NULL
  UNION DISTINCT
  SELECT DISTINCT PostId FROM `sotorrent-extension.2018_09_23.CodeClonesSampleLargeLinksNonSO`
);
# 180,175 (38.9%)

# both SO and external
SELECT COUNT(*) FROM
(SELECT DISTINCT PostId FROM `sotorrent-extension.2018_09_23.CodeClonesSampleLargeLinksSO` WHERE LinkedPostId IS NOT NULL) so
JOIN
(SELECT DISTINCT PostId FROM `sotorrent-extension.2018_09_23.CodeClonesSampleLargeLinksNonSO`) external
ON so.PostId = external.PostId;
# 14,865 (3.2%)
