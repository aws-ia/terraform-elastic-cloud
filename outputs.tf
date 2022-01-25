output "elasticsearch_https_endpoint" {
  value = ec_deployment.ec_minimal.elasticsearch[0].https_endpoint
}

output "elasticsearch_cloud_id" {
  value = ec_deployment.ec_minimal.elasticsearch[0].cloud_id
  sensitive = true
}

output kibana_https_endpoint {
  value = ec_deployment.ec_minimal.kibana[0].https_endpoint
}

output apm_https_endpoint {
  value = ec_deployment.ec_minimal.apm[0].https_endpoint
}

output "deployment_id" {
  value = ec_deployment.ec_minimal.id
}