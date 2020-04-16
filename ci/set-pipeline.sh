#!/bin/bash

set -ex

lpass ls > /dev/null # check that we're logged in

fly -t denver set-pipeline \
    -p bosh-system-metrics \
    -c bosh-system-metrics.yml \
    -l <(lpass show --notes "Shared-Loggregator (Pivotal Only)/bosh-system-metrics-creds.yml") \
    -v gcp_credentials_json="$(lpass show --notes "Shared-Loggregator (Pivotal Only)/GCP Service Account Key")" \
    -l scripts.yml
