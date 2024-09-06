# Copyright 2024 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

output "dashboard_template_url" {
  value = "https://lookerstudio.google.com/reporting/create?c.reportId=${urlencode(var.dashboard_template_id)}&c.mode=edit&r.reportName=${urlencode(var.dashboard_report_name)}&ds.accounts.connector=bigQuery&ds.accounts.projectId=${var.project_id}&ds.accounts.type=TABLE&ds.accounts.datasetId=${var.dataset_name}&ds.accounts.tableId=account_list&ds.video.connector=bigQuery&ds.video.projectId=${var.project_id}&ds.video.type=TABLE&ds.video.datasetId=${var.dataset_name}&ds.video.tableId=video_campaign_asset_coverage&ds.dg.connector=bigQuery&ds.dg.projectId=${var.project_id}&ds.dg.type=TABLE&ds.dg.datasetId=${var.dataset_name}&ds.dg.tableId=demand_gen_asset_coverage"
}
