output "github_repo" {
  value = "https://github.com/${var.github_owner}/${google_storage_bucket.static_website.name}"
}

output "website_url" {
  value = "https://${google_storage_bucket.static_website.name}.storage.googleapis.com/index.html"
}
