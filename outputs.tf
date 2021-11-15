output "elasticsearch_https_endpoint" {
  value = ec_deployment.example_minimal.elasticsearch[0].https_endpoint
}

output "elasticsearch_username" {
  value = ec_deployment.example_minimal.elasticsearch_username
}

output "elasticsearch_password" {
  value = ec_deployment.example_minimal.elasticsearch_password
  sensitive = true
}

output "elasticsearch_cloud_id" {
  value = ec_deployment.example_minimal.elasticsearch[0].cloud_id
}

output "aws_account_id" {
  value = local.aws_account_id
}