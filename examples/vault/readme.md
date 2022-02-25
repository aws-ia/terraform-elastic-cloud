## HashiCorp Vault deployment and migration steps

### Deployment steps
1.	Set the Vault environment variables. Be sure to replace the example values in brackets (<>) with your own values.

  1. Run the following export commands. 
  
  ```
  export VAULT_ADDR= "<your Vault URL>"
  export VAULT_TOKEN="<your Vault Token>"
  ```

  2. Run this command to add your Elasticsearch API key: 
  
  ```
  vault kv put secret/<your path> apikey="<your Elastic API key>"
  ```

  3. Run the following commands to add your AWS API key:
  
  ```
  vault kv put secret/<your path> s3_client_access_key="<your AWS access key>" s3_client_secret_key="<your AWS secret key>"
  ```

2.	Provide the key values to the variables in the <your file name>.tfvars file:
  
  **Note**: You can provide key values to the <your file name>.tfvars in other ways. For more information, refer to the [Assigning Values to Root Module Variables](https://www.terraform.io/language/values/variables) section in the Terraform documentation.
  
  ```
  name = "Elasticsearch Cluster"
  local_elasticsearch_url = ""
  vault_address = "your local Elastic cluster URL>"
  vault_ess_path = "secret/<your path>"
  vault_aws_path = "secret/<your path>"
  apikey = "hashicorp/vault"
  s3_client_access_key = "hashicorp/vault"
  s3_client_secret_key  = "hashicorp/vault"
  ```

### Migration steps
1. Add the URL to the same .tfvars file you created in the previous steps. 
  
  **Note**: You can provide key values to the <your file name>.tfvars in other ways. For more information, refer to the [Assigning Values to Root Module Variables](https://www.terraform.io/language/values/variables) section in the Terraform documentation.

```
name = "Elasticsearch Cluster"
local_elasticsearch_url = "your local Elasticsearch cluster URL>"
vault_address = "http://127.0.0.1:8200"
vault_ess_path = "secret/<your path>"
vault_aws_path = "secret/<your path>"
apikey = "hashicorp/vault"
s3_client_access_key = "hashicorp/vault"
s3_client_secret_key  = "hashicorp/vault"
```

