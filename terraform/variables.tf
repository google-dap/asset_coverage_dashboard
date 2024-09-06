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

variable "project_id" {
  type = string
}

variable "google_ads_account_id" {
  type = string
  description = "Google Ads MCC ID"
}

variable "client_id" {
  type = string
  description = ""  
}

variable "client_secret" {
  type = string
  description = ""  
}

variable "refresh_token" {
  type = string
  description = ""  
}

variable "developer_token" {
  type = string
  description = ""  
}

variable "name" {
  type = string
  default = "agency_assets"
}

variable "location" {
  type = string
  default = "us"
}

variable "region" {
  type = string
  default = "us-central1"
}

variable "zone" {
  type = string
  default = "us-central1-c"
}

variable "user_project_override" {
  type = bool
  default = false
}

variable "billing_project" {
  type = string
  default = ""
}

variable "dashboard_template_id" {
  type = string
  default = "dc1266ef-d5b3-449c-9024-2ca6e4c5e98a"
}

variable "dashboard_report_name" {
  type = string
  default = "Google Ads Asset Coverage Dashboard"
}

variable "dataset_name" {
  type = string
  default = "agency_assets"
}

variable "application_title" {
  type = string
  default = "Asset Coverage Dashboard"
}
