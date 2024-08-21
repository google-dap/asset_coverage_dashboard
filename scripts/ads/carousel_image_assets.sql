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

-- Retrieves Carousel Asset information for Demand Gen campaigns.

SELECT
  customer.id AS account_id,
  asset.id AS asset_id,
  asset.resource_name AS asset_resource_name,
  asset.discovery_carousel_card_asset.marketing_image_asset AS carousel_landscape_asset,
  asset.discovery_carousel_card_asset.square_marketing_image_asset AS carousel_square_asset,
  asset.discovery_carousel_card_asset.portrait_marketing_image_asset AS carousel_portrait_asset
FROM
  asset
WHERE
  asset.type = 'DISCOVERY_CAROUSEL_CARD'
