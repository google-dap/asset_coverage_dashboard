terraform {
  required_providers {
    docker = {
      source = "kreuzwerker/docker"
      version = "3.0.2"
    }
  }
}

provider "google" {
  project     = var.project_id
  region      = var.region
  zone        = var.zone
  user_project_override = var.user_project_override
  billing_project = var.billing_project
}

provider "docker" {
  registry_auth {
    address  = "${google_artifact_registry_repository.image_repository.location}-docker.pkg.dev"
  }
}
