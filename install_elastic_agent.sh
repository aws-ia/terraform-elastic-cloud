#!/bin/bash -ex
install_elastic_agent() {
  # "jq" needs to be installed on the host
  apt update
  apt install -y jq  #debian default
  count=0
  MAX_ATTEMPTS=6
  echo "creating API Key"
  while [[ "$count" -lt "$MAX_ATTEMPTS" ]]; do
    count=$((count+1))
    sleep 10
    echo `date`
    estable=$(curl -XPOST -H "kbn-xsrf: true" -u ${ELASTICSEARCH_USERNAME}:${ELASTICSEARCH_PASSWORD} -w "%%{http_code}" -s "${KIBANA_URL}/api/fleet/agent_policies?sys_monitoring=true" -H 'Content-Type: application/json' --data-raw '{"name":"${DeploymentID}", "description":"Dedicated agent policy for AWS Marketplace QuickStarts ","namespace":"default","monitoring_enabled":["logs","metrics"]}')
    http_code=$(echo $estable | jq | tail -1)
    echo $http_code
    if [[ "$http_code" -eq 200  ]] ; then
      policy_id=$(echo $estable | rev | cut -c 4- | rev | jq -r '.[] | .id')
      echo $policy_id
      response=$(curl -XGET -H "kbn-xsrf: true" -u ${ELASTICSEARCH_USERNAME}:${ELASTICSEARCH_PASSWORD} -s "${KIBANA_URL}/api/fleet/enrollment-api-keys" -H 'Content-Type: application/json')
      echo $response | jq
      api_key=$(echo $response | jq -r --arg policy_id "$policy_id" '.list[] | select(.policy_id == $policy_id) | .api_key')
      echo $api_key
      aws_version=$(curl -s -u ${ELASTICSEARCH_USERNAME}:${ELASTICSEARCH_PASSWORD} -H 'Content-Type: application/json' -H 'kbn-xsrf: true' -XGET "${KIBANA_URL}/api/fleet/epm/packages/aws" | jq '.response[]' | tail -4 | head -1 | tr -d \")
      echo $aws_version
      fleet_server_host=$(curl -s -XGET ${KIBANA_URL}/api/fleet/settings -H 'Content-Type: application/json' -H 'kbn-xsrf: true' -u ${ELASTICSEARCH_USERNAME}:${ELASTICSEARCH_PASSWORD} | jq -r '.item.fleet_server_hosts[0]')
      echo $fleet_server_host
      echo "http code is 200, API Key fetched successfully"
      echo "---------------------------------------------"
      echo "Downloading Elastic Agent..."
      curl -L -O https://artifacts.elastic.co/downloads/beats/elastic-agent/elastic-agent-${DeploymentVersion}-linux-x86_64.tar.gz
      tar xzvf elastic-agent-${DeploymentVersion}-linux-x86_64.tar.gz
      cd elastic-agent-${DeploymentVersion}-linux-x86_64
      sudo ./elastic-agent install -f --url=$fleet_server_host --enrollment-token=$api_key
      echo "Elastic Agent has been downloaded."
      break
    fi
  done
}

_main() {
  install_elastic_agent
}

_main "$@"