#!/bin/bash

check_repo_ec() {
  repeat=120
  exit=1
  file="./ec_repo.status"
  string="nodes"

  touch ec_repo.status
  while [ $repeat -gt 0 ] && [ $exit -ne 0 ]; do
    curl -v --user ${ec-user}:${ec-pwd} -XPOST ${ec-url}/_snapshot/${ec-repo}/_verify -H 'Content-Type: application/json' > ec_repo.status
    if [ ! -z $(grep "$string" "$file") ]; then exit=0; else repeat=$(($repeat-1)); sleep 5; fi
  done
}

close_indexes_ec() {
  curl -v --user ${ec-user}:${ec-pwd} -XPOST ${ec-url}/*/_close?expand_wildcards=all
  sleep 1m
}

restore_snapshot_ec() {
  curl -v --user ${ec-user}:${ec-pwd} -XPOST ${ec-url}/_snapshot/${ec-repo}/${ec-snapshot}/_restore?wait_for_completion=true -H 'Content-Type: application/json' -d '
  {
    "indices": "*",
    "ignore_unavailable": true,
    "include_global_state": false,
    "rename_pattern": ".geoip_databases",
    "rename_replacement": ".geoip_databases_.geoip_databases"
  }'
}

rename_geoip_index_ec() {
  curl -v --user ${ec-user}:${ec-pwd} -XPOST ${ec-url}/_reindex?wait_for_completion=true -H 'Content-Type: application/json' -d '
  {
    "source": {
      "index": ".geoip_databases_.geoip_databases"
    },
    "dest": {
      "index": ".geoip_databases"
    }
  }'
}

open_indexes_ec() {
  curl -v --user ${ec-user}:${ec-pwd} -XPOST ${ec-url}/*/_open?expand_wildcards=all
}

_main() {
 check_repo_ec
 close_indexes_ec
 restore_snapshot_ec
 rename_geoip_index_ec
 open_indexes_ec
}

_main "$@"