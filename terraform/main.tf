locals {
  required_apis = [
    "apikeys.googleapis.com",
    "artifactregistry.googleapis.com",
    "bigquery.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "cloudscheduler.googleapis.com",
    "compute.googleapis.com",
    "iam.googleapis.com",
    "iap.googleapis.com",
    "run.googleapis.com",
    "serviceusage.googleapis.com",
    "storage.googleapis.com",
    "workflows.googleapis.com",
    "youtube.googleapis.com"
  ]
  sanitized_project_id = replace(var.project_id, ":", "/")
  workflow_contents = file("../files/workflow.yaml")
  script_files = fileset("../scripts", "**")
}

resource "null_resource" "base_apis" {
  for_each = toset(["serviceusage.googleapis.com", "cloudresourcemanager.googleapis.com"])
  provisioner "local-exec" {
    command = "gcloud services enable $SERVICE --project $PROJECT"

    environment = {
      SERVICE = each.key
      PROJECT = var.project_id
    }
  }

  depends_on = [ local_file.generated_tfvars ]
}

resource "null_resource" "delay_for_api_service" {
  provisioner "local-exec" {
    command = "sleep 60"
  }
  triggers = {
    "resource" = null_resource.base_apis["cloudresourcemanager.googleapis.com"].id
  }
  depends_on = [ 
    null_resource.base_apis["serviceusage.googleapis.com"],
    null_resource.base_apis["cloudresourcemanager.googleapis.com"]
  ]
}

resource "google_project_service" "required_apis" {
  for_each = toset(local.required_apis)
  service = each.key

  disable_on_destroy = false
  disable_dependent_services = false
  depends_on = [ null_resource.delay_for_api_service ]
}

resource "google_artifact_registry_repository" "image_repository" {
  location      = var.region
  repository_id = "agency-dash-image-repo"
  description   = "Image Repository for Agency Dash images"
  format        = "DOCKER"
}

resource "google_storage_bucket" "agency_assets" {
  name          = "agency-assets"
  location      = upper(var.location)
  force_destroy = true

  # TODO
  uniform_bucket_level_access = "true"
  public_access_prevention = "enforced"
}

resource "google_bigquery_dataset" "raw_dataset" {
  dataset_id                  = "agency_assets_raw"
  friendly_name               = "agency_assets_raw"
  description                 = "Asset Coverage Dataset for raw API output"
  location                    = upper(var.location)
  default_table_expiration_ms = 2592000000
  delete_contents_on_destroy = true

  labels = {
    env = "agency_assets"
  }
}

resource "google_bigquery_dataset" "formatted_dataset" {
  dataset_id                  = "agency_assets"
  friendly_name               = "agency_assets"
  description                 = "Asset Coverage Dataset for formatted data"
  location                    = upper(var.location)
  default_table_expiration_ms = 2592000000
  delete_contents_on_destroy = true

  labels = {
    env = "agency_assets"
  }
}

resource "google_storage_bucket_object" "scripts" {
  for_each = toset(local.script_files)
  name   = "scripts/${each.key}"
  source = "../scripts/${each.key}"
  bucket = google_storage_bucket.agency_assets.name
}

resource "google_storage_bucket_object" "google_ads_yaml" {
  name   = "google-ads.yaml"
  content_type = "application/yaml"
  content = yamlencode({
    developer_token: var.developer_token,
    use_proto_plus: false,
    client_id: var.client_id,
    client_secret: var.client_secret,
    refresh_token: var.refresh_token,
    login_customer_id: var.google_ads_account_id
  })
  bucket = google_storage_bucket.agency_assets.name
}

resource "google_storage_bucket_object" "custom_var_backup" {
  name = "backup.auto.tfvars"
  content = <<EOF
google_ads_account_id = "${var.google_ads_account_id}"
client_id = "${var.client_id}"
client_secret = "${var.client_secret}"
refresh_token = "${var.refresh_token}"
developer_token = "${var.developer_token}"
EOF
  bucket = google_storage_bucket.agency_assets.name
}


resource "local_file" "generated_tfvars" {
  filename = "${path.module}/generated.auto.tfvars"
  content = <<EOF
google_ads_account_id = "${var.google_ads_account_id}"
client_id = "${var.client_id}"
client_secret = "${var.client_secret}"
refresh_token = "${var.refresh_token}"
developer_token = "${var.developer_token}"
EOF
}

resource "docker_registry_image" "gcp_artifactory_gaarf" {
  name          = docker_image.gaarf_image.name
  keep_remotely = true
}

resource "docker_image" "gaarf_image" {
  name = "${google_artifact_registry_repository.image_repository.location}-docker.pkg.dev/${local.sanitized_project_id}/${google_artifact_registry_repository.image_repository.repository_id}/gaarf:latest"
  build {
    context = "../src"
    dockerfile = "Dockerfile.gaarf"
  }
}

resource "docker_registry_image" "gcp_artifactory_gaarf_bq" {
  name          = docker_image.gaarf_bq_image.name
}

resource "docker_image" "gaarf_bq_image" {
  name = "${google_artifact_registry_repository.image_repository.location}-docker.pkg.dev/${local.sanitized_project_id}/${google_artifact_registry_repository.image_repository.repository_id}/gaarf-bq:latest"
  build {
    context = "../src"
    dockerfile = "Dockerfile.gaarf-bq"
  }
}

resource "null_resource" "wait_for_gaarf_image" {
  provisioner "local-exec" {
    command = "sleep 60"
  }
  triggers = {
    "resource" = docker_registry_image.gcp_artifactory_gaarf.name
  }
  depends_on = [ docker_registry_image.gcp_artifactory_gaarf ]
}

resource "google_cloud_run_v2_job" "gaarf" {
  name     = "gaarf"
  location = var.region

  template {
    task_count = 1
    template {
      containers {
        image = docker_image.gaarf_image.name
      }
    }
  }
  depends_on = [ null_resource.wait_for_gaarf_image ]
}

resource "null_resource" "wait_for_gaarf_bq_image" {
  provisioner "local-exec" {
    command = "sleep 60"
  }
  triggers = {
    "resource" = docker_registry_image.gcp_artifactory_gaarf_bq.name
  }
  depends_on = [ docker_registry_image.gcp_artifactory_gaarf_bq ]
}

resource "google_cloud_run_v2_job" "gaarf_bq" {
  name     = "gaarf-bq"
  location = var.region

  template {
    task_count = 1
    template {
      containers {
        image = docker_image.gaarf_bq_image.name
      }
    }
  }
  depends_on = [ null_resource.wait_for_gaarf_bq_image ]
}

resource "random_string" "api_key_suffix" {
  length = 8
  special = false
  upper = false
  numeric = false
}

resource "google_apikeys_key" "youtube_key" {
  name         = "youtube-key-${random_string.api_key_suffix.result}"
  display_name = "Youtube Key for asset coverage"

  restrictions {
    api_targets {
      service = "youtube.googleapis.com"
      methods = ["*"]
    }
  }
}

resource "google_workflows_workflow" "agency_assets_wf" {
  name          = "agency-assets"
  region        = var.region
  description   = "Agency Assets Workflow"
  call_log_level = "LOG_ERRORS_ONLY"
  labels = {
    env = "agency_assets"
  }
  user_env_vars = {
    AGENCY_ASSETS_CID = replace(var.google_ads_account_id, "-", "")
    AGENCY_ASSETS_DATASET_LOCATION = var.location
    AGENCY_ASSETS_REGION = var.region
    AGENCY_ASSETS_YOUTUBE_KEY = google_apikeys_key.youtube_key.key_string
  }

  source_contents = local.workflow_contents

  depends_on = [ google_cloud_run_v2_job.gaarf, google_cloud_run_v2_job.gaarf_bq ]
}

data "google_compute_default_service_account" "default" {
}

resource "google_cloud_scheduler_job" "job" {
  name             = "agency-asset-scheduler"
  description      = "Scheduler Job for Agency Asset Dashboard data"
  schedule         = "8 2 * * *"
  time_zone        = "America/New_York"
  attempt_deadline = "320s"

  retry_config {
    retry_count = 1
  }

  http_target {
    http_method = "POST"
    uri         = "https://workflowexecutions.googleapis.com/v1/projects/${var.project_id}/locations/${var.region}/workflows/agency-assets/executions"
    # body        = base64encode("{\"argument\":{}}")
    headers = {
      "Content-Type" = "application/json"
    }
    oauth_token {
      service_account_email = data.google_compute_default_service_account.default.email
    }
  }

  depends_on = [ google_workflows_workflow.agency_assets_wf ]
}
