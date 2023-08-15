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
host_string=$(yq '.minio.volumns.[].worker' $CONF_FILE)
host_and_port_string=$(yq '.minio.volumns.[].worker' $CONF_FILE | awk '{print $1":'$ssh_port'"}')
package_dir=$(yq '.minio.package-dir' $CONF_FILE)

# ---------------------------------------------------------------------------
# step-1: refresh package to nodes
# ---------------------------------------------------------------------------
package_path=$(dirname $package_dir)
pssh -H "$host_and_port_string" -l $deploy_user -i -P "if [ ! -d $package_path ];then sudo mkdir -p $package_path; sudo chown -R $deploy_user:$deploy_user $package_path echo 'package dir has been created successfully!';else echo 'package dir has been already created!'; fi"
sudo chown $deploy_user:$deploy_user $package_dir
pscp -H "$host_and_port_string" -l $deploy_user -r $package_dir $package_path
echo -e "\033[34m <<step-1: Refresh package to nodes>> has been distributed successfully! \033[0m"

# ---------------------------------------------------------------------------
# step-2: refresh configuration to nodes
# ---------------------------------------------------------------------------
pssh -H "$host_and_port_string" -l $deploy_user -i -P "if [ ! -d $BASE_DIR ];then sudo mkdir -p $BASE_DIR; sudo chown -R $deploy_user:$deploy_user $BASE_DIR echo 'base dir has been created successfully!';else echo 'base dir has been already created!'; fi"
pscp -H "$host_and_port_string" -l $deploy_user -r $BASE_DIR/* $BASE_DIR
echo -e "\033[34m <<step-2: Refresh configuration to nodes>> has been distributed successfully! \033[0m"

# ---------------------------------------------------------------------------
# step-3: install package
# ---------------------------------------------------------------------------
pssh -H "$host_and_port_string" -l $deploy_user -P -i "$BASE_DIR/sbin/node.sh"
echo -e "\033[34m <<step-3: Install package]>> has been done successfully! \033[0m"
