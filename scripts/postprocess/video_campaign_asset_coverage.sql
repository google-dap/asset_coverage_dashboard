-- Copyright 2024 Google LLC
--
-- Licensed under the Apache License, Version 2.0 (the "License");
-- you may not use this file except in compliance with the License.
-- You may obtain a copy of the License at
--
--     http://www.apache.org/licenses/LICENSE-2.0
--
-- Unless required by applicable law or agreed to in writing, software
-- distributed under the License is distributed on an "AS IS" BASIS,
-- WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
-- See the License for the specific language governing permissions and
-- limitations under the License.

-- Computes asset coverage for video campaigns.
--
-- Video campaigns are defined as both responsive ads with video as well as video ads, and
-- converage is determined by the presence of different video formats: landscape, square, and
-- portrait. While this script calculates this information, it does not make a determination on
-- whether the asset coverage is complete/valid or not.
--
-- @param ${dataset} BigQuery dataset to store calculated coverage data.
-- @param ${raw_dataset} BigQuery dataset where raw asset data is stored.

CREATE OR REPLACE TABLE `${dataset}.video_campaign_asset_coverage`
AS (
  WITH
    ResponsiveVideoAssets AS (
      SELECT DISTINCT
        VideoCampaigns.customer_id,
        VideoCampaigns.campaign_id,
        SUM(Aspects.landscape) AS landscape_video_count,
        SUM(Aspects.square) AS square_video_count,
        SUM(Aspects.vertical) AS vertical_video_count
      FROM `${raw_dataset}.video_campaigns` AS VideoCampaigns
      CROSS JOIN UNNEST(VideoCampaigns.ad_video_responsive_ad_videos) AS video_asset_id
      LEFT JOIN `${dataset}.video_assets` AS Aspects
        ON CAST(Aspects.asset_id AS STRING) = SPLIT(video_asset_id, "/")[SAFE_OFFSET(3)]
      GROUP BY campaign_id, customer_id
    ),
    VideoAdAssets AS (
      SELECT DISTINCT
        VideoCampaigns.customer_id,
        VideoCampaigns.campaign_id,
        SUM(Aspects.landscape) AS landscape_video_count,
        SUM(Aspects.square) AS square_video_count,
        SUM(Aspects.vertical) AS vertical_video_count
      FROM `${raw_dataset}.video_campaigns` AS VideoCampaigns
      LEFT JOIN `${dataset}.video_assets` AS Aspects
        ON
          CAST(Aspects.asset_id AS STRING)
          = SPLIT(VideoCampaigns.ad_video_ad_video_asset, "/")[SAFE_OFFSET(3)]
      GROUP BY campaign_id, customer_id
    )
  SELECT DISTINCT
    Customer.customer_name,
    LinkMapping.ocid,
    VideoCampaigns.customer_id,
    VideoCampaigns.campaign_id,
    VideoCampaigns.campaign_name,
    IFNULL(ResponsiveVideoAssets.landscape_video_count, 0)
      + IFNULL(VideoAdAssets.landscape_video_count, 0) AS landscape_video_count,
    IFNULL(ResponsiveVideoAssets.square_video_count, 0)
      + IFNULL(VideoAdAssets.square_video_count, 0) AS square_video_count,
    IFNULL(ResponsiveVideoAssets.vertical_video_count, 0)
      + IFNULL(VideoAdAssets.vertical_video_count, 0) AS vertical_video_count
  FROM `${raw_dataset}.video_campaigns` AS VideoCampaigns
  LEFT JOIN ResponsiveVideoAssets
    ON VideoCampaigns.campaign_id = ResponsiveVideoAssets.campaign_id
  LEFT JOIN VideoAdAssets
    ON ResponsiveVideoAssets.campaign_id = VideoAdAssets.campaign_id
  LEFT JOIN `${dataset}.account_list` AS Customer
    ON Customer.customer_id = VideoCampaigns.customer_id
  LEFT JOIN `${raw_dataset}.link_mapping` AS LinkMapping
    ON Customer.customer_id = LinkMapping.customer_id
)
