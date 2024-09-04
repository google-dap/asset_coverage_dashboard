# Asset Coverage Dashboard

The Asset Coverage Dashboard is designed for agencies to get details about the image and videos assets associated with their clients' Demand Gen and Video campaigns.

## Overview

The solution contains two main portions and can be extended or modified however the end users see fit to fulfill their needs. The first portion is a GCP Cloud Workflow which leverages Google APIs and Services to retrieve, combine, and store the campaign asset information in BigQuery. The second is a Looker Dashboard which serves to display the information in a single pane of glass view and provide a shortcut for a user to investigate the campaign further.

## Getting Started

To deploy your own instance of this solution, there are a few pre-requisites you'll want to have setup/available prior in order to ensure success:

- Join the following Google Group to gain access to the dashboard template: [Agency Asset Dashboard Users
](https://groups.google.com/g/agency-asset-dashboard-users)
- [Google Cloud Project](https://developers.google.com/workspace/guides/create-project)
- [Google Ads Developer Token](https://developers.google.com/google-ads/api/docs/get-started/dev-token)
- [Oauth2 Configured for the Google Ads API](https://developers.google.com/google-ads/api/docs/oauth/overview) which will provide the following information:
  - A Client ID
  - A Client secret
  - A valid Refresh Token
- A Google Ads MCC Account ID

Once you have these accounted for you can clone this repository and navigate to the `/terraform/` directory. It is recommended to do this from your [Google Cloud Shell](https://cloud.google.com/shell/docs/launching-cloud-shell) to ensure you have the appropriate tooling, but if you have `gcloud` and `terraform` setup on your machine you should be able to complete the following steps.

Before provisioning the solution as a whole, you first must create a Cloud Storage bucket to store the Terraform state as well as authenticate to the GCP docker registry.

```bash
# create Cloud Storage bucket for state
gcloud storage buckets create gs://asset-dashboard-terraform-state --pap --uniform-bucket-level-access --project=$GOOGLE_CLOUD_PROJECT

# enable versioning on the bucket
gcloud storage buckets update gs://asset-dashboard-terraform-state --versioning  --project=$GOOGLE_CLOUD_PROJECT

# authenticate to docker registry
gcloud auth configure-docker us-central1-docker.pkg.dev

```

Once these have been completed, you're ready to deploy the solution.

>If you'd like, you can create a [tfvars](https://developer.hashicorp.com/terraform/language/values/variables#variable-definitions-tfvars-files) file to specify any values or value overrides for the solution. Any that are not specified you'll be prompted to enter each time you run a `terraform` command (e.g. `plan` or `apply`). For convenience, these definitions will create a `generated.auto.tfvars` file in the `terraform` directory containing the values for any variables that don't have a default associated, meaning unless you'd like to change them in the future, you'll only need to enter them once. These values will also be stored in a `backup.auto.tfvars` object in Cloud Storage should you need to retrieve them again at a later date.

From within the `terraform` directory, run the following commands:

```bash
# initialize terraform and required modules
terraform init

# enable APIs for programmatic usage and for provisioning resources via Terraform
terraform apply -target="null_resource.base_apis" -auto-approve
terraform apply -target="google_project_service.required_apis" -auto-approve

# deploy solution
terraform apply -auto-approve
```

The final command will output a URL which can be used to create a copy of the template dashboard, once the workflow has successfully run at least once.


## Architecture

The architecture of the Asset Coverage Dashboard is largely defined by a Cloud Workflow that is responsible for orchestrating a few different Cloud Run Jobs and services in order to download and format campaign asset information. This data is stored in BigQuery and can be viewed via a copy of the Template Looker Studio Dashboard. The following diagram illustrates this:

![architecture diagram](docs/overall_architecture.jpg)

### Architecture Notes

- **YouTube Data API** The solution uses the YouTube Data API in order to retrieve information about some of the video assets for campaigns. It only needs to do this once per video, however it does utilize your daily YouTube quota. In the event you have a large number of video assets (e.g. more than 10,000) or are already actively using your quota, it may take a few daily runs of the Workflow to populate BigQuery with all the requisite video information.


## Updating

In order to update the solution, clone the latest from the repo (or `git pull` any updates) and then run `terraform apply` again (and reply 'yes' to the prompt after reviewing the changes if needed) from within the `terraform` directory. This should use the existing state stored in GCS and only make changes to any resources that have changed.

**Note:** If you provide different values for certain variables (e.g. `client_id` or `refresh_token`), when running `terraform apply` it will update these values in the deployment. If you'd like to use your previously entered values but don't have them recorded (or you no longer have the `generated.auto.tfvars` file), you can download and use the `backup.auto.tfvars` file from the Cloud Storage bucket that was created (named "agency-assets") by placing it in the `terraform` directory.

## Deleting the Solution

If you no longer want the solution, you can run a `terraform destroy` from the `/terraform/` directory and that will delete and remove most of the solution, with the exception of disabling any Service APIs that were enabled as well as the Cloud Storage bucket that was manually created. **Please Note: _This will also delete the campaign and asset data in BigQuery as well as the BigQuery datasets themselves._**
