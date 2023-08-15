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

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------
deploy_user=$(yq '.deploy-user' $CONF_FILE)
ssh_port=$(yq '.ssh.port' $CONF_FILE)
host_set=$(yq '.minio.volumns.[].worker' $CONF_FILE)
home_dir=$(yq '.minio.home-dir' $CONF_FILE)

for n in $host_set
do
  echo "# -->[" $n "]<--------------------------------------------------------------"
  ssh $n -l $deploy_user -p $ssh_port "$home_dir/sbin/minio-deamon.sh $1"
  echo "# -->[" $n "]<--------------------------------------------------------------"
done
