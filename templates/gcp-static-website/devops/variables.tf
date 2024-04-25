variable "project" {
  description = "The GCP project to deploy the resources"
  type        = string
  default     = "able-study-419810"
}

variable "bucket_name" {
  description = "The name of the GCS bucket"
  type        = string
  default     = "${{ values.name }}"
}

variable "github_owner" {
  description = "The owner of the GitHub repository"
  type        = string
  default     = "victoronl"
}

variable "github_token_secret" {
  description = "The name of the secret that contains the GitHub token"
  type        = string
  default = "github-token"
}
