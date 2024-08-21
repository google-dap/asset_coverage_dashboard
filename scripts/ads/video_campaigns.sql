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

-- Retrieves Campaign and Asset information for active Video campaigns.

SELECT
  customer.id,
  campaign.id,
  campaign.name,
  campaign.advertising_channel_type,
  campaign.bidding_strategy_type,
  ad_group.name,
  ad_group.id,
  ad_group_ad.status AS ad_group_ad_status,
  ad_group_ad.ad.id AS ad_group_ad_ad_id,
  ad_group_ad.ad.type AS ad_group_ad_ad_type,
  ad_group_ad.ad.video_ad.video.asset,
  ad_group_ad.ad.video_responsive_ad.videos:asset
FROM
  ad_group_ad
WHERE
  campaign.advertising_channel_type = 'VIDEO'
  AND campaign.status = 'ENABLED'
  AND ad_group_ad.status = 'ENABLED'
