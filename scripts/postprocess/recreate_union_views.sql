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

-- Recreates BigQuery union views for a list of accounts.
--
-- In the case where suffixed tables are stored at different times, the default created union view
-- will only reference the first (or first set) of tables. This is designed to be run after all the
-- tables have been created and will recreate the view using the entire list of accounts to ensure
-- the view accounts for all the tables.
--
-- @param ${accounts} The comma-separated list of accounts in STRING format.
-- @param ${dataset} The BigQuery dataset where the tables are stored.
-- @param ${table} The base table name used for the union view.

CREATE OR REPLACE VIEW `${dataset}.${table}`
AS (
  SELECT * FROM `${dataset}.${table}_*` WHERE _TABLE_SUFFIX IN (${accounts})
);
