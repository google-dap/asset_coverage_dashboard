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

-- Computes asset coverage for Demand Gen campaigns.
--
-- Asset coverage for Demand Gen campaigns takes into consideration images and videos. For formats
-- landscape, square, and portrait is considered. For images, they can be directly associtated
-- assets, a carousel, or a connected Merchant Center feed. While this script calculates this
-- information, it does not make a determination on whether the asset coverage is complete/valid or
-- not.
--
-- @param ${dataset} BigQuery dataset to store calculated coverage data.
-- @param ${raw_dataset} BigQuery dataset where raw asset data is stored.

CREATE OR REPLACE TABLE `${dataset}.demand_gen_asset_coverage`
AS (
  WITH
    VideoAssets AS (
      SELECT DISTINCT
        DemandGen.customer_id,
        DemandGen.campaign_id,
        SUM(Aspects.landscape) AS landscape_video_count,
        SUM(Aspects.square) AS square_video_count,
        SUM(Aspects.vertical) AS vertical_video_count
      FROM `${raw_dataset}.demand_gen_campaign_assets` AS DemandGen
      CROSS JOIN UNNEST(DemandGen.ad_demand_gen_video_responsive_ad_videos) AS video_asset_id
      LEFT JOIN `${dataset}.video_assets` AS Aspects
        ON CAST(Aspects.asset_id AS STRING) = SPLIT(video_asset_id, "/")[SAFE_OFFSET(3)]
      GROUP BY campaign_id, customer_id
    ),
    CarouselAssets AS (
      SELECT DISTINCT
        DemandGen.customer_id,
        DemandGen.campaign_id,
        COUNTIF(Carousel.carousel_landscape_asset != "") AS carousel_landscape_image_count,
        COUNTIF(Carousel.carousel_square_asset != "") AS carousel_square_image_count,
        COUNTIF(Carousel.carousel_portrait_asset != "") AS carousel_portrait_image_count
      FROM `${raw_dataset}.demand_gen_campaign_assets` AS DemandGen
      CROSS JOIN UNNEST(DemandGen.ad_demand_gen_carousel_ad_carousel_cards) AS carousel_card_id
      LEFT JOIN `${raw_dataset}.carousel_image_assets` AS Carousel
        ON Carousel.asset_resource_name = carousel_card_id
      GROUP BY campaign_id, customer_id
    ),
    ImageAssets AS (
      SELECT
        DemandGen.customer_id,
        DemandGen.campaign_id,
        DemandGen.campaign_name,
        DemandGen.campaign_shopping_setting_merchant_id,
        SUM(ARRAY_LENGTH(DemandGen.ad_demand_gen_multi_asset_ad_marketing_images))
          AS ad_demand_gen_multi_asset_ad_marketing_images_count,
        SUM(ARRAY_LENGTH(DemandGen.ad_demand_gen_multi_asset_ad_square_marketing_images))
          AS ad_demand_gen_multi_asset_ad_square_marketing_images_count,
        SUM(ARRAY_LENGTH(DemandGen.ad_demand_gen_multi_asset_ad_portrait_marketing_images))
          AS ad_demand_gen_multi_asset_ad_portrait_marketing_images_count,
        SUM(ARRAY_LENGTH(DemandGen.ad_demand_gen_multi_asset_ad_logo_images))
          AS ad_demand_gen_multi_asset_ad_logo_images_count,
        SUM(ARRAY_LENGTH(DemandGen.ad_demand_gen_video_responsive_ad_logo_images))
          AS ad_demand_gen_video_responsive_ad_logo_images_count,
      FROM `${raw_dataset}.demand_gen_campaign_assets` AS DemandGen
      GROUP BY campaign_id, customer_id, campaign_name, campaign_shopping_setting_merchant_id
    )
  SELECT
    Customer.customer_name,
    LinkMapping.ocid,
    ImageAssets.customer_id,
    ImageAssets.campaign_id,
    ImageAssets.campaign_name,
    IF(ImageAssets.campaign_shopping_setting_merchant_id IS NULL, FALSE, TRUE) AS connected_gmc,
    ImageAssets.ad_demand_gen_multi_asset_ad_marketing_images_count
      + IFNULL(CarouselAssets.carousel_landscape_image_count, 0) AS landscape_image_count,
    ImageAssets.ad_demand_gen_multi_asset_ad_square_marketing_images_count
      + ImageAssets.ad_demand_gen_multi_asset_ad_logo_images_count
      + ImageAssets.ad_demand_gen_video_responsive_ad_logo_images_count
      + IFNULL(CarouselAssets.carousel_square_image_count, 0) AS square_image_count,
    ImageAssets.ad_demand_gen_multi_asset_ad_portrait_marketing_images_count
      + IFNULL(CarouselAssets.carousel_portrait_image_count, 0) AS portrait_image_count,
    IFNULL(VideoAssets.landscape_video_count, 0) AS landscape_video_count,
    IFNULL(VideoAssets.square_video_count, 0) AS square_video_count,
    IFNULL(VideoAssets.vertical_video_count, 0) AS vertical_video_count
  FROM ImageAssets
  LEFT JOIN VideoAssets
    ON ImageAssets.campaign_id = VideoAssets.campaign_id
  LEFT JOIN CarouselAssets
    ON ImageAssets.campaign_id = CarouselAssets.campaign_id
  LEFT JOIN `${dataset}.account_list` AS Customer
    ON Customer.customer_id = ImageAssets.customer_id
  LEFT JOIN `${raw_dataset}.link_mapping` AS LinkMapping
    ON Customer.customer_id = LinkMapping.customer_id
)
