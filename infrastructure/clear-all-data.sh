
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.
#
# OpenCRVS is also distributed under the terms of the Civil Registration
# & Healthcare Disclaimer located at http://opencrvs.org/license.
#
# Copyright (C) The OpenCRVS Authors located at https://github.com/opencrvs/opencrvs-core/blob/master/AUTHORS.

set -e

print_usage_and_exit () {
    echo 'Usage: ./clear-all-data.sh REPLICAS STACK'
    echo ""
    echo "If your MongoDB is password protected, an admin user's credentials can be given as environment variables:"
    echo "MONGODB_ADMIN_USER=your_user MONGODB_ADMIN_PASSWORD=your_pass"
    echo ""
    echo "If your Elasticsearch is password protected, an admin user's credentials can be given as environment variables:"
    echo "ELASTICSEARCH_ADMIN_USER=your_user ELASTICSEARCH_ADMIN_PASSWORD=your_pass"
    exit 1
}

if [ -z "$1" ] ; then
    echo 'Error: Argument REPLICAS is required in position 1.'
    print_usage_and_exit
fi

if [ -z "$2" ] ; then
    echo 'Error: Argument STACK is required in position 2.'
    print_usage_and_exit
fi

REPLICAS=$1
STACK=$2

if ! [[ "$REPLICAS" =~ ^[0-9]+$ ]]; then
  echo "Script must be passed a positive integer number of replicas. Got '$REPLICAS'"
  print_usage_and_exit
fi

if [ "$REPLICAS" = "0" ]; then
  HOST=mongo1
  NETWORK=opencrvs_default
  echo "Working with no replicas"
else
  NETWORK=dependencies_mongo_net_1
  # Construct the HOST string rs0/mongo1,mongo2... based on the number of replicas
  HOST="rs0/"
  for (( i=1; i<=REPLICAS; i++ )); do
    if [ $i -gt 1 ]; then
      HOST="${HOST},"
    fi
    HOST="${HOST}mongo${i}"
  done
fi

mongo_credentials() {
  if [ ! -z ${MONGODB_ADMIN_USER+x} ] || [ ! -z ${MONGODB_ADMIN_PASSWORD+x} ]; then
    echo "--username $MONGODB_ADMIN_USER --password $MONGODB_ADMIN_PASSWORD --authenticationDatabase admin";
  else
    echo "";
  fi
}

elasticsearch_host() {
  if [ ! -z ${ELASTICSEARCH_ADMIN_USER+x} ] || [ ! -z ${ELASTICSEARCH_ADMIN_PASSWORD+x} ]; then
    echo "$ELASTICSEARCH_ADMIN_USER:$ELASTICSEARCH_ADMIN_PASSWORD@elasticsearch:9200";
  else
    echo "elasticsearch:9200";
  fi
}

drop_database () {
  local database="${STACK}__${1}"
  docker run --rm --network=$NETWORK mongo:4.4 mongo $database $(mongo_credentials) --host $HOST --eval "db.dropDatabase()"
}

# Delete all data from mongo
#---------------------------
drop_database hearth-dev;

drop_database openhim-dev;

drop_database user-mgnt;

drop_database application-config;

drop_database metrics;

drop_database performance;

# Delete all data from elasticsearch
#-----------------------------------
docker run --rm --network=dependencies_elasticsearch_net appropriate/curl curl -XDELETE "http://$(elasticsearch_host)/${STACK}__ocrvs" -v

# Delete all data from metrics
#-----------------------------
docker run --rm --network=dependencies_influx_net appropriate/curl curl -X POST "http://influxdb:8086/query?db=${STACK}__ocrvs" --data-urlencode "q=DROP SERIES FROM /.*/" -v

# Delete all data from minio
#-----------------------------
docker run --rm --network=dependencies_minio_net --entrypoint=/bin/sh minio/mc -c "\
  mc alias set myminio http://minio:9000 $MINIO_ROOT_USER $MINIO_ROOT_PASSWORD && \
  mc rm --recursive --force myminio/${STACK}--ocrvs && \
  mc rb myminio/${STACK}--ocrvs && \
  mc mb myminio/${STACK}--ocrvs"

# Delete all data from redis
#-----------------------------
REDIS_CONTAINER_ID=$(docker ps --filter "name=^${STACK}_redis" --format '{{.ID}}' --latest)
echo "REDIS_CONTAINER_ID: $REDIS_CONTAINER_ID"
docker exec -i $REDIS_CONTAINER_ID redis-cli FLUSHDB