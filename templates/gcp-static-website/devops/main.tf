terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "5.24.0"
    }
  }
}

provider "google" {
  project = var.project
}

resource "google_storage_bucket" "static_website" {
  name          = var.bucket_name
  location      = "us-central1"
  storage_class = "STANDARD"
  force_destroy = true

  website {
    main_page_suffix = "index.html"
    not_found_page   = "404.html"
  }
}

resource "google_storage_bucket_object" "static_website_index_page" {
  name         = "index.html"
  content      = "<html><body>Hello World!</body></html>"
  content_type = "text/html"
  bucket       = google_storage_bucket.static_website.id
}

resource "google_storage_bucket_object" "static_website_error_page" {
  name         = "404.html"
  content      = "<html><body>404!</body></html>"
  content_type = "text/html"
  bucket       = google_storage_bucket.static_website.id
}

resource "google_storage_bucket_access_control" "static_website_access_control" {
  bucket = google_storage_bucket.static_website.id
  role   = "READER"
  entity = "allUsers"
}

resource "google_storage_bucket_iam_binding" "static_website_iam_binding" {
  bucket = google_storage_bucket.static_website.id
  role   = "roles/storage.objectViewer"
  members = [
    "allUsers",
  ]
}

// Create a secret containing the personal access token and grant permissions to the Service Agent
resource "google_secret_manager_secret" "github_token_secret" {
  project   = var.project
  secret_id = "GitHubVictoronl-github-secret"

  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_version" "github_token_secret_version" {
  secret      = google_secret_manager_secret.github_token_secret.id
  secret_data = var.github_token_secret

  depends_on = [google_secret_manager_secret.github_token_secret]
}

data "google_iam_policy" "serviceagent_secretAccessor" {
  binding {
    role = "roles/secretmanager.secretAccessor"
    members = [
      "serviceAccount:service-926912221151@gcp-sa-cloudbuild.iam.gserviceaccount.com"
    ]
  }
}

resource "google_secret_manager_secret_iam_policy" "policy" {
  project     = google_secret_manager_secret.github_token_secret.project
  secret_id   = google_secret_manager_secret.github_token_secret.secret_id
  policy_data = data.google_iam_policy.serviceagent_secretAccessor.policy_data

  depends_on = [google_secret_manager_secret.github_token_secret, google_secret_manager_secret_version.github_token_secret_version]
}

// Create the GitHub connection
resource "google_cloudbuildv2_connection" "my_connection" {
  project  = var.project
  location = "us-central1"
  name     = "GitHubVictoronl"

  github_config {
    app_installation_id = 49480549
    authorizer_credential {
      oauth_token_secret_version = google_secret_manager_secret_version.github_token_secret_version.id
    }
  }
  depends_on = [google_secret_manager_secret_iam_policy.policy]
}

# https://cloud.google.com/build/docs/automating-builds/github/connect-repo-github?generation=2nd-gen&hl=pt-br#connecting_a_github_host_programmatically

resource "google_cloudbuildv2_repository" "my_repository" {
  project           = var.project
  location          = "us-central1"
  name              = var.bucket_name
  parent_connection = google_cloudbuildv2_connection.my_connection.name
  remote_uri        = "https://github.com/${var.github_owner}/${var.bucket_name}"
}

resource "google_cloudbuild_trigger" "static_website_trigger" {
  name     = "${google_storage_bucket.static_website.name}-trigger"
  location = "us-central1"
  project  = var.project

  repository_event_config {
    repository = google_cloudbuildv2_repository.my_repository.id
    push {
      branch = "^main$"
    }
  }

  github {
    owner = var.github_owner
    name  = var.bucket_name
    push {
      branch = "^main$"
    }
  }

  build {
    timeout = "120s"
    substitutions = {
      _BUCKET_NAME = var.bucket_name
    }
    step {
      name       = "gcr.io/cloud-builders/gsutil"
      entrypoint = "bash"
      args       = ["-c", "gsutil -m rsync -r -d -x '.git/' . gs://$_BUCKET_NAME"]
    }
  }
}
