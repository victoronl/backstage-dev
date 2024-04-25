variable "region" {
  description = "The AWS region to deploy the resources"
  type        = string
  default     = "us-east-1"
}

variable "bucket_name" {
  description = "The name of the S3 bucket"
  type        = string
  default     = "${{ values.name }}"
}

variable "github_username" {
  description = "The GitHub username to authenticate with the repository"
  type        = string
  default =   "victoronl"
}

variable "github_repo" {
  description = "The name of the GitHub repository"
  type        = string
  default     = "${{ values.name }}"
}
