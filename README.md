<!-- BEGIN_TF_DOCS -->
## Elastic Cloud on AWS
This Terraform module automates your Elastic Cloud deployment and optional data migration to the AWS Cloud. The deployment provisions the following components:

* Your Elastic Cloud cluster.
* Amazon Elastic Compute Cloud (Amazon EC2), which is needed for [Elastic Agent](https://www.elastic.co/elastic-agent).
* An Amazon Simple Storage Service (Amazon S3) bucket needed for [Elasticsearch snapshots](https://www.elastic.co/guide/en/elasticsearch/reference/current/snapshot-restore.html).
* [Elastic Serverless Forwarder](https://www.elastic.co/blog/elastic-and-aws-serverless-application-repository-speed-time-to-actionable-insights-with-frictionless-log-ingestion-from-amazon-s3) for data ingestion.
* An AWS Identity and Access Management (IAM) instance role with fine-grained permissions to access AWS services.

Existing customers with Elasticsearch cluster data stored on premises in a self-managed Elasticsearch cluster can optionally choose to migrate that data into Elastic Cloud after deployment to AWS. Both the deployment and migration processes are covered in this document.

> **Note**: If using [HashiCorp Vault](https://www.vaultproject.io/), see the examples and accompanying readme in the [examples/vault](https://github.com/aws-ia/terraform-elastic-cloud/tree/develop/examples/vault) folder in this GitHub repository.

### Authors and Contributors

Battulga Purevragchaa (AWS), Uday Theepireddy (Elastic) and [other contributors](https://github.com/aws-ia/terraform-elastic-cloud/graphs/contributors).  

## Deployment (without data migration)

### Prerequisites
Check that you are running the most current version of Terraform software. For more, see [Install Terraform](https://learn.hashicorp.com/tutorials/terraform/install-cli).

### Deployment architecture
![](docs/images/elastic-architecture-diagram.png)

The deployment sets up the following components.
- A highly available architecture that spans multiple Availability Zones.
- A virtual private cloud (VPC) configured with public and private subnets according to AWS best practices, to provide you with your own virtual network on AWS.
- An AWS EC2 instance for the Elastic Agent.
- AWS Serverless Application Repository functions integration to create an Elastic forwarder and multiple sources to ingest into Elastic Cloud.
- Elastic Agent and Elastic serverless forwarder to receive logs from the S3 bucket.
- AWS Secrets Manager to store Elasticsearch credentials
- Amazon SQS to ingest logs contained in the S3 bucket through event notifications.
- AWS WAF to protect web applications from common web exploits.
- AWS CloudTrail to track user activity and API usage.
- Amazon VPC flow logs to capture information about IP traffic going to and from network interfaces.
- Amazon S3 buckets to host Elastic snapshots and capture logs from the various AWS services such as AWS WAF, Amazon VPC flow logs, AWS CloudTrail, and network firewall logs.
- An AWS IAM role with fine-grained permissions for access to AWS services required for deployment.

### Deployment steps
1.	Generate an Elasticsearch Service (ESS) API key:

	1.	Open your browser and navigate to https://cloud.elastic.co/login.
	2.	Log in with your email address and password.
	3.	Choose **Elasticsearch Service**.
	4.	Navigate to **Features > API Keys** and choose **Generate API Key**.
	5.	Choose a name for your API key.
	6.	Save your API key in a safe location.

2.	Clone the [Terraform Elastic Cloud Git repository](https://github.com/aws-ia/terraform-elastic-cloud) using the following commands:

```
git clone https://github.com/aws-ia/terraform-elastic-cloud  
cd terraform-elastic-cloud
```

3.	Create <your file name>.tfvars file in the same directory with the following variable definitions:
  ```
name = "Elasticsearch Cluster"
apikey = "<your Elastic API key>"
  ```
	
4.	Run the Terraform module <your file name>.tfvars file, as shown here:
 ```
terraform init
terraform apply -var-file="<your file name>.tfvars"
 ```
## Deployment with Elasticsearch data migration

When planning your Elasticsearch data migration to Elastic Cloud, you have a few options. In some cases, you may not need to migrate the data in existing clusters. This is common when you are planning to migrate the data source itself and can just re-ingest the data into Elastic Cloud after migration. Another reason for not migrating your data is when the existing indices are time-sensitive and no longer needed. In these cases, you can just deploy Elastic Cloud without migrating any data from existing clusters.

For cases where the data must be migrated to Elastic Cloud, options depend on the use case, data volume, current Elasticsearch version, and uptime requirements on the current Elasticsearch application. Options include:
- **Snapshot and restore** – In this option, you create an S3 bucket, add a snapshot of the current deployment into the bucket, add the same repository from Elastic Cloud, and finally restore indexes from the snapshot into Elastic Cloud. This option is covered in the steps that follow.
- **Re-index from a remote cluster** – In this option, you use the re-index API from the new cluster to retrieve data from the indices in the existing Elasticsearch cluster and then re-index them in the new Elastic Cloud deployment. This option is not covered in this document.

> **Note**: To learn more, visit [AWS Prescriptive Guidance: Migrate an ELK Stack to Elastic Cloud on AWS](https://docs.aws.amazon.com/prescriptive-guidance/latest/patterns/migrate-an-elk-stack-to-elastic-cloud-on-aws.html).
	
### Prerequisites

- Verify that the target Elastic Cloud is running a version that is the same or higher than the current Elasticsearch cluster. For more information about version compatibility, refer to the [Elastic Cloud documentation](https://www.elastic.co/guide/en/elasticsearch/reference/8.0/snapshot-restore.html#snapshot-restore-version-compatibility).
- Check for limitations and version-specific breaking changes to confirm that no constraints exist that might affect migration to Elastic Cloud. For more information, refer to the [Snapshot and restore](https://www.elastic.co/guide/en/elasticsearch/reference/current/snapshot-restore.html) and [Upgrade Elasticsearch](https://www.elastic.co/guide/en/elasticsearch/reference/current/setup-upgrade.html) topics in the Elasticsearch Guide.
- If you don’t already have AWS Command Line Interface (AWS CLI) and the Amazon S3 plug-in on your existing Elasticsearch cluster, install it from the Elasticsearch home directory with the following command:
	
 ```
sudo bin/elasticsearch-plugin install repository-s3
 ```
- Add the Amazon S3 access keys to the Elasticsearch keystore by running the following commands from the root directory of the existing Elasticsearch cluster. When prompted, enter the appropriate keys to access and store a snapshot in an S3 bucket from your self-managed Elasticsearch.
	
 ```
bin/elasticsearch-keystore add s3.client.default.access_key
bin/elasticsearch-keystore add s3.client.default.secret_key
 ```
### Migration architecture
![](docs/images/elastic-migration-diagram.png)
	
The migration takes the following high-level steps:
1.	Creates and registers an Elastic Cloud snapshot repository using Amazon S3.
2.	Creates and configures a local snapshot repository and points to the S3 bucket.
3.	Creates a new snapshot from the local cluster and stores it in the S3 bucket.
4.	Closes all indices in Elasticsearch Cloud.
5.	Restores the local cluster data from the snapshot in Elasticsearch Cloud.
6.	Opens all indices in Elasticsearch Cloud.

### Deployment steps with data migration
	
Existing customers who are already running Elasticsearch cluster on premises can use a built-in feature of Elastic Cloud to migrate to the AWS Cloud. Be sure to replace the example values in brackets (<>) with your own values.

To perform the deployment with migration:
1.	Generate an Elasticsearch Service (ESS) API key:

	1.	Open your browser and navigate to https://cloud.elastic.co/login.
	2.	Log in with your email address and password.
	3.	Choose Elasticsearch Service.
	4.	Navigate to **Features > API Keys** and choose **Generate API Key**.
	5.	Choose a name for your API Key.
	6.	Save your API key in a safe location.

2.	Clone the [Terraform Elastic Cloud Git repository](https://github.com/aws-ia/terraform-elastic-cloud) using the following commands:

```
git clone https://github.com/aws-ia/terraform-elastic-cloud  
cd terraform-elastic-cloud
```

3.	Create <your file name>.tfvars file in the same directory with the following variable definitions:
	
```
name = "Elasticsearch Cluster"
apikey = "Your Elastic API Key"
s3_client_access_key = "your AWS access key"
s3_client_secret_key  = "your AWS secret key"
local_elasticsearch_url = "your local Elastic cluster URL"
```

> Note: Assign the URL of your self-managed Elasticsearch to `local_elasticsearch_url` (for example, http://127.0.0.1:9200).

4.	Run the Terraform module to deploy the Elastic Cloud cluster on AWS and migrate the self-managed Elasticsearch data.

```
terraform init
terraform apply -var-file="<your file name>.tfvars"
```
## Clean up the infrastructure
If you no longer need the infrastructure that’s provisioned by the Terraform module, run the following command to remove the deployment infrastructure and terminate all resources.
	
```
terraform destroy -var-file="<your file name>.tfvars"
```

## Elastic Cloud automation structure
The following Terraform modules are used for Elastic Cloud deployment.

| Name | Description |
|------|------|
| [examples/vault](https://github.com/aws-ia/terraform-elastic-cloud/tree/main/examples/vault) | Example modules if you are using [HashiCorp Vault](https://www.vaultproject.io/) |
| [ec\_aws\_resource.tf](https://github.com/aws-ia/terraform-elastic-cloud/blob/main/ec_aws_resources.tf) | Creates all the AWS resources needed for the deployment |
| [ec\_migrate.tf](https://github.com/aws-ia/terraform-elastic-cloud/blob/main/ec_migrate.tf) | Migrates self-managed Elasticsearch data to Elastic Cloud |  
| [ec\_secrets.tf](https://github.com/aws-ia/terraform-elastic-cloud/blob/main/ec_secrets.tf) | Contains code to retrieve the secrets keys |
| [main.tf](https://github.com/aws-ia/terraform-elastic-cloud/blob/main/main.tf) | Contains the primary entry point for Elastic Cloud deployment | <your file name>.tfvars | Provides required input values. |
| [outputs.tf](https://github.com/aws-ia/terraform-elastic-cloud/blob/main/outputs.tf) | Used for the declarations of [output values](https://www.terraform.io/language/values/outputs) | <your file name>.tfvars | Provides required input values. |
| [providers.tf](https://github.com/aws-ia/terraform-elastic-cloud/blob/main/providers.tf) | Specifies [providers](https://www.terraform.io/language/providers) | <your file name>.tfvars | Provides required input values. |
| [variables.tf](https://github.com/aws-ia/terraform-elastic-cloud/blob/main/variables.tf) | Contains the declaration of [input variables](https://www.terraform.io/language/values/variables) | <your file name>.tfvars | Provides required input values. |
| \<your file name>.tfvars | Provides required input values |

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 0.13 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 4.12.1 |
| <a name="requirement_ec"></a> [ec](#requirement\_ec) | >= 0.4.0 |
| <a name="requirement_elasticsearch"></a> [elasticsearch](#requirement\_elasticsearch) | 2.0.1 |
| <a name="requirement_random"></a> [random](#requirement\_random) | >= 3.1.3 |
| <a name="requirement_vault"></a> [vault](#requirement\_vault) | 3.5.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 4.12.1 |
| <a name="provider_ec"></a> [ec](#provider\_ec) | >= 0.4.0 |
| <a name="provider_elasticsearch"></a> [elasticsearch](#provider\_elasticsearch) | 2.0.1 |
| <a name="provider_null"></a> [null](#provider\_null) | n/a |
| <a name="provider_random"></a> [random](#provider\_random) | >= 3.1.3 |
| <a name="provider_template"></a> [template](#provider\_template) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_iam_role.es_role](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role) | resource |
| [aws_iam_role_policy_attachment.es_deploy](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/iam_role_policy_attachment) | resource |
| [aws_instance.ec2_instance](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/instance) | resource |
| [aws_kms_alias.aka](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_alias) | resource |
| [aws_kms_key.akk](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/kms_key) | resource |
| [aws_s3_bucket.es_s3_agent](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket.es_s3_logging](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket.es_s3_repo](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket_acl.es_s3_logging_acl](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_acl) | resource |
| [aws_s3_bucket_logging.es_s3_agent_logging](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_logging) | resource |
| [aws_s3_bucket_logging.es_s3_repo_logging](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_logging) | resource |
| [aws_s3_bucket_policy.es_s3_agent](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_policy) | resource |
| [aws_s3_bucket_policy.es_s3_repo](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_policy) | resource |
| [aws_s3_bucket_public_access_block.es_s3_agent](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_public_access_block) | resource |
| [aws_s3_bucket_public_access_block.es_s3_logging](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_public_access_block) | resource |
| [aws_s3_bucket_public_access_block.es_s3_repo](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_public_access_block) | resource |
| [aws_s3_bucket_server_side_encryption_configuration.es_s3_agent_encryption](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_server_side_encryption_configuration) | resource |
| [aws_s3_bucket_server_side_encryption_configuration.es_s3_logging_encryption](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_server_side_encryption_configuration) | resource |
| [aws_s3_bucket_server_side_encryption_configuration.es_s3_repo_encryption](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_server_side_encryption_configuration) | resource |
| [aws_s3_bucket_versioning.es_s3_agent_versioning](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_versioning) | resource |
| [aws_s3_bucket_versioning.es_s3_logging_versioning](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_versioning) | resource |
| [aws_s3_bucket_versioning.es_s3_repo_versioning](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_versioning) | resource |
| [aws_s3_object.esf_sar_config](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_object) | resource |
| [aws_secretsmanager_secret.es_secrets](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret) | resource |
| [aws_secretsmanager_secret_version.es_credentials](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/secretsmanager_secret_version) | resource |
| [aws_serverlessapplicationrepository_cloudformation_stack.esf_cfn_stack](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/serverlessapplicationrepository_cloudformation_stack) | resource |
| [aws_sqs_queue.es_queue](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sqs_queue) | resource |
| [aws_sqs_queue.es_queue_deadletter](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/sqs_queue) | resource |
| [ec_deployment.ec_minimal](https://registry.terraform.io/providers/elastic/ec/latest/docs/resources/deployment) | resource |
| [ec_deployment_elasticsearch_keystore.access_key](https://registry.terraform.io/providers/elastic/ec/latest/docs/resources/deployment_elasticsearch_keystore) | resource |
| [ec_deployment_elasticsearch_keystore.secret_key](https://registry.terraform.io/providers/elastic/ec/latest/docs/resources/deployment_elasticsearch_keystore) | resource |
| [ec_deployment_traffic_filter.allow_all](https://registry.terraform.io/providers/elastic/ec/latest/docs/resources/deployment_traffic_filter) | resource |
| [elasticsearch_snapshot_repository.create_local_repo](https://registry.terraform.io/providers/phillbaker/elasticsearch/2.0.1/docs/resources/snapshot_repository) | resource |
| [null_resource.create_cloud_repo](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [null_resource.create_snapshot](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [null_resource.restore_snapshot](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [random_id.id](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/id) | resource |
| [aws_ami.ubuntu](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/ami) | data source |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_serverlessapplicationrepository_application.esf_app](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/serverlessapplicationrepository_application) | data source |
| [ec_stack.latest](https://registry.terraform.io/providers/elastic/ec/latest/docs/data-sources/stack) | data source |
| [template_file.init_sar_config](https://registry.terraform.io/providers/hashicorp/template/latest/docs/data-sources/file) | data source |
| [template_file.install_elastic_agent](https://registry.terraform.io/providers/hashicorp/template/latest/docs/data-sources/file) | data source |
| [template_file.run_rest_api](https://registry.terraform.io/providers/hashicorp/template/latest/docs/data-sources/file) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_apikey"></a> [apikey](#input\_apikey) | Elasticsearch Service API Key | `string` | n/a | yes |
| <a name="input_name"></a> [name](#input\_name) | Deployment Name | `string` | n/a | yes |
| <a name="input_agent_s3_bucket_prefix"></a> [agent\_s3\_bucket\_prefix](#input\_agent\_s3\_bucket\_prefix) | Creates a unique bucket name beginning with the specified prefix | `string` | `"es-s3-agent"` | no |
| <a name="input_ami"></a> [ami](#input\_ami) | AMI ID for the instance | `string` | `null` | no |
| <a name="input_associate_public_ip_address"></a> [associate\_public\_ip\_address](#input\_associate\_public\_ip\_address) | Whether to associate a public IP address with an instance in a VPC | `bool` | `null` | no |
| <a name="input_autoscale"></a> [autoscale](#input\_autoscale) | Enable or disable autoscaling | `string` | `"false"` | no |
| <a name="input_availability_zone"></a> [availability\_zone](#input\_availability\_zone) | Availability Zone into which the instance is deployed | `string` | `null` | no |
| <a name="input_deployment_template_id"></a> [deployment\_template\_id](#input\_deployment\_template\_id) | Deployment template identifier | `string` | `"aws-io-optimized-v2"` | no |
| <a name="input_ec2_name"></a> [ec2\_name](#input\_ec2\_name) | EC2 Name | `string` | `"single-instance"` | no |
| <a name="input_existing_s3_repo_bucket_name"></a> [existing\_s3\_repo\_bucket\_name](#input\_existing\_s3\_repo\_bucket\_name) | Existing S3 bucket name for repository | `string` | `""` | no |
| <a name="input_instance_type"></a> [instance\_type](#input\_instance\_type) | The type of instance to start | `string` | `"t3.micro"` | no |
| <a name="input_key_name"></a> [key\_name](#input\_key\_name) | Key name of the EC2 Key Pair to use for the instance. | `string` | `null` | no |
| <a name="input_kms_key_id"></a> [kms\_key\_id](#input\_kms\_key\_id) | KMS Key ID | `string` | `null` | no |
| <a name="input_local_elasticsearch_repo_name"></a> [local\_elasticsearch\_repo\_name](#input\_local\_elasticsearch\_repo\_name) | Creates an S3 repository with the specified name for the local cluster | `string` | `"es-index-backups"` | no |
| <a name="input_local_elasticsearch_url"></a> [local\_elasticsearch\_url](#input\_local\_elasticsearch\_url) | Migrates self-hosted Elasticsearch data if its URL is provided – e.g., http://127.0.0.1:9200 | `string` | `""` | no |
| <a name="input_log_s3_bucket_prefix"></a> [log\_s3\_bucket\_prefix](#input\_log\_s3\_bucket\_prefix) | Creates a unique bucket name beginning with the specified prefix | `string` | `"es-s3-logging"` | no |
| <a name="input_region"></a> [region](#input\_region) | AWS Region | `string` | `"us-west-2"` | no |
| <a name="input_repo_s3_bucket_prefix"></a> [repo\_s3\_bucket\_prefix](#input\_repo\_s3\_bucket\_prefix) | Creates a unique bucket name beginning with the specified prefix | `string` | `"es-s3-repo"` | no |
| <a name="input_root_block_device"></a> [root\_block\_device](#input\_root\_block\_device) | Details about the root block device of the instance. | `list(any)` | `[]` | no |
| <a name="input_s3_client_access_key"></a> [s3\_client\_access\_key](#input\_s3\_client\_access\_key) | Access Key ID for the S3 repository | `string` | `null` | no |
| <a name="input_s3_client_secret_key"></a> [s3\_client\_secret\_key](#input\_s3\_client\_secret\_key) | Secret Access Key for the S3 repository | `string` | `null` | no |
| <a name="input_sourceip"></a> [sourceip](#input\_sourceip) | traffic filter source | `string` | `"0.0.0.0/0"` | no |
| <a name="input_subnet_id"></a> [subnet\_id](#input\_subnet\_id) | Subnet ID | `string` | `null` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | tags, which could be used for additional tags | `map(string)` | `{}` | no |
| <a name="input_user_data"></a> [user\_data](#input\_user\_data) | The user data to provide when launching the instance. | `string` | `null` | no |
| <a name="input_vpc_security_group_ids"></a> [vpc\_security\_group\_ids](#input\_vpc\_security\_group\_ids) | A list of security group IDs with which to associate the instance | `list(string)` | `null` | no |
| <a name="input_zone_count"></a> [zone\_count](#input\_zone\_count) | Number of zones the instance type of the Elasticsearch cluster will span | `number` | `1` | no |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_apm_https_endpoint"></a> [apm\_https\_endpoint](#output\_apm\_https\_endpoint) | APM resource HTTPs endpoint |
| <a name="output_deployment_id"></a> [deployment\_id](#output\_deployment\_id) | The deployment identifier |
| <a name="output_elasticsearch_cloud_id"></a> [elasticsearch\_cloud\_id](#output\_elasticsearch\_cloud\_id) | The encoded Elasticsearch credentials to use in Beats or Logstash |
| <a name="output_elasticsearch_https_endpoint"></a> [elasticsearch\_https\_endpoint](#output\_elasticsearch\_https\_endpoint) | The Elasticsearch resource HTTPs endpoint |
| <a name="output_kibana_https_endpoint"></a> [kibana\_https\_endpoint](#output\_kibana\_https\_endpoint) | The Kibana resource HTTPs endpoint |
<!-- END_TF_DOCS -->