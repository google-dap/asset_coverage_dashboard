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

-- Calculates video formats based on their embedding dimensions.
--
-- For a given triple of account, asset, and video, and given formats of landscape, square, and
-- vertical, a 1 will be assigned to the format that matches its dimensions, and a 0 will be
-- assigned to the other formats.
--
-- @param ${aspect_table} Table containing the aspect ratios for videos.
-- @param ${asset_table} Table containing asset details.
-- @param ${destination_dataset} BigQuery dataset where calculated data will be stored.
-- @param ${source_dataset} BiqQuery dataset where raw data will be sourced from.

CREATE OR REPLACE TABLE `${destination_dataset}.video_assets`
AS (
  SELECT
    VideoAssets.account_id,
    VideoAssets.asset_id,
    VideoAssets.video_id,
    AspectRatios.embedWidth AS embed_width,
    AspectRatios.embedHeight AS embed_height,
    IF(AspectRatios.embedWidth / AspectRatios.embedHeight > 1, 1, 0) AS landscape,
    IF(AspectRatios.embedWidth / AspectRatios.embedHeight = 1, 1, 0) AS square,
    IF(AspectRatios.embedWidth / AspectRatios.embedHeight < 1, 1, 0) AS vertical
  FROM `${source_dataset}.${asset_table}` AS VideoAssets
  INNER JOIN `${source_dataset}.${aspect_table}` AS AspectRatios
    ON VideoAssets.video_id = AspectRatios.video_id
)
