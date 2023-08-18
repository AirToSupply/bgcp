#!/bin/bash

WORK_DIR=`dirname $0`
WORK_DIR=`cd ${WORK_DIR};pwd`
BASE_DIR=`cd ${WORK_DIR};cd ..;pwd`
CONF_DIR=`cd ${WORK_DIR};cd ../conf;pwd`
CONF_FILE=$CONF_DIR/setup.yaml
MINIO_VERSION=$(yq '.version' $CONF_FILE)

eval "cat <<EOF
$(<$BASE_DIR/blanner.txt)
EOF
" 2> /dev/null

$BASE_DIR/sbin/deploy-docker.sh
