#!/bin/bash

install_elastic_agent() {
  echo "Downloading and installing Elastic Agent..."
  curl -L -O https://artifacts.elastic.co/downloads/beats/elastic-agent/elastic-agent-7.15.1-linux-x86_64.tar.gz
  tar xzvf elastic-agent-7.15.1-linux-x86_64.tar.gz
  sudo ./elastic-agent install
  echo "Elastic Agent has been installed."
}

_main() {
 install_elastic_agent
}

_main "$@"