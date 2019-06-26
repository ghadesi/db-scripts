#!/bin/bash

project="sotorrent-org"
dataset="2019_06_21"
bucket="sotorrent"
logfile="bigquery.log"

# TODO: copy or create type tables

# import CSV files without header row
bq load --source_format=CSV "$project:$dataset.Badges" "gs://$bucket/Badges.csv" ./bigquery-schema/Badges.json &>> "$logfile"
bq load --source_format=CSV "$project:$dataset.Comments" "gs://$bucket/Comments.csv" ./bigquery-schema/Comments.json &>> "$logfile"
bq load --source_format=CSV "$project:$dataset.CommentUrl" "gs://$bucket/CommentUrl.csv" ./bigquery-schema/CommentUrl.json &>> "$logfile"
bq load --source_format=CSV "$project:$dataset.PostBlockDiff" "gs://$bucket/PostBlockDiff.csv" ./bigquery-schema/PostBlockDiff.json &>> "$logfile"
bq load --source_format=CSV "$project:$dataset.PostBlockType" "gs://$bucket/PostBlockType.csv" ./bigquery-schema/PostBlockType.json &>> "$logfile"
bq load --source_format=CSV "$project:$dataset.PostBlockVersion" "gs://$bucket/PostBlockVersion.csv" ./bigquery-schema/PostBlockVersion.json &>> "$logfile"
bq load --source_format=CSV "$project:$dataset.PostHistory" "gs://$bucket/PostHistory.csv" ./bigquery-schema/PostHistory.json &>> "$logfile"
bq load --source_format=CSV "$project:$dataset.PostLinks" "gs://$bucket/PostLinks.csv" ./bigquery-schema/PostLinks.json &>> "$logfile"
bq load --source_format=CSV "$project:$dataset.Posts" "gs://$bucket/Posts.csv" ./bigquery-schema/Posts.json &>> "$logfile"
bq load --source_format=CSV "$project:$dataset.PostVersion" "gs://$bucket/PostVersion.csv" ./bigquery-schema/PostVersion.json &>> "$logfile"
bq load --source_format=CSV "$project:$dataset.PostVersionUrl" "gs://$bucket/PostVersionUrl.csv" ./bigquery-schema/PostVersionUrl.json &>> "$logfile"
bq load --source_format=CSV "$project:$dataset.Tags" "gs://$bucket/Tags.csv" ./bigquery-schema/Tags.json &>> "$logfile"
bq load --source_format=CSV "$project:$dataset.TitleVersion" "gs://$bucket/TitleVersion.csv" ./bigquery-schema/TitleVersion.json &>> "$logfile"
bq load --source_format=CSV "$project:$dataset.Users" "gs://$bucket/Users.csv" ./bigquery-schema/Users.json &>> "$logfile"
bq load --source_format=CSV "$project:$dataset.Votes" "gs://$bucket/Votes.csv" ./bigquery-schema/Votes.json &>> "$logfile"

# import CSV files with header row
bq load --source_format=CSV --skip_leading_rows=1 "$project:$dataset.GHMatches" "gs://$bucket/GHMatches.csv" ./bigquery-schema/GHMatches.json &>> "$logfile"
bq load --source_format=CSV --skip_leading_rows=1 "$project:$dataset.PostReferenceGH" "gs://$bucket/PostReferenceGH.csv" ./bigquery-schema/PostReferenceGH.json &>> "$logfile"

# remove CSV files in the cloud
gsutil rm "gs://$bucket/*.csv.gz"
