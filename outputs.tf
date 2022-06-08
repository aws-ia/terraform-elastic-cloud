output "elasticsearch_https_endpoint" {
  value       = ec_deployment.ec_minimal.elasticsearch[0].https_endpoint
  description = "The Elasticsearch resource HTTPs endpoint"
}

output "elasticsearch_cloud_id" {
  sensitive   = true
  value       = ec_deployment.ec_minimal.elasticsearch[0].cloud_id
  description = "The encoded Elasticsearch credentials to use in Beats or Logstash"
}

output "kibana_https_endpoint" {
  value       = ec_deployment.ec_minimal.kibana[0].https_endpoint
  description = "The Kibana resource HTTPs endpoint"
}

output "apm_https_endpoint" {
  value       = ec_deployment.ec_minimal.apm[0].https_endpoint
  description = "APM resource HTTPs endpoint"
}

output "deployment_id" {
  value       = ec_deployment.ec_minimal.id
  description = "The deployment identifier"
}