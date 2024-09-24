#!/usr/bin/env bash

# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenCRVS is also distributed under the terms of the Civil Registration
# & Healthcare Disclaimer located at http://opencrvs.org/license.
#
# Copyright (C) The OpenCRVS Authors located at https://github.com/opencrvs/opencrvs-core/blob/master/AUTHORS.

# Upgrading from 7 to 8 requires deleting elastalert indices. https://elastalert2.readthedocs.io/en/latest/recipes/faq.html#does-elastalert-2-support-elasticsearch-8

set -e

docker_command="docker run --rm --network=dependencies_elasticsearch_net curlimages/curl"

echo 'Waiting for availability of Elasticsearch'
ping_status_code=$($docker_command --connect-timeout 60 -u elastic:$ELASTICSEARCH_SUPERUSER_PASSWORD -o /dev/null -w '%{http_code}' "http://elasticsearch:9200")

if [ "$ping_status_code" -ne 200 ]; then
  echo "Elasticsearch is not ready. API returned status code: $ping_status_code"
  exit 1
fi

