output "clone_url_http" {
  value = aws_codecommit_repository.static_website_codecommit_repository.clone_url_http
}

output "clone_url_ssh" {
  value = aws_codecommit_repository.static_website_codecommit_repository.clone_url_ssh
}

output "website_endpoint" {
  value = "${aws_s3_bucket_website_configuration.static_website_configuration.website_endpoint}/index.html"
}
