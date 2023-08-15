#!/bin/bash

WORK_DIR=`dirname $0`
WORK_DIR=`cd ${WORK_DIR};pwd`
BASE_DIR=`cd ${WORK_DIR};cd ..;pwd`
CONF_DIR=`cd ${WORK_DIR};cd ../conf;pwd`
CONF_FILE=$CONF_DIR/setup.yaml
JUICEFS_VERSION=$(yq '.version' $CONF_FILE)

eval "cat <<EOF
$(<$BASE_DIR/blanner.txt)
EOF
" 2> /dev/null

# ---------------------------------------------------------------------------
# Configuration
# ---------------------------------------------------------------------------
deploy_user=$(yq '.deploy-user' $CONF_FILE)
ssh_port=$(yq '.ssh.port' $CONF_FILE)
juicefs_host_string=$(yq '.juicefs.servers.[].host' $CONF_FILE)
juicefs_host_and_port_string=$(yq '.juicefs.servers.[].host' $CONF_FILE | awk '{print $1":'$ssh_port'"}')
juicefs_package_dir=$(yq '.juicefs.package-dir' $CONF_FILE)

hdfs_integration_enable=$(yq '.hdfs.integration' $CONF_FILE)
hdfs_host_string=$(yq '.hdfs.servers.[].host' $CONF_FILE)
hdfs_host_and_port_string=$(yq '.hdfs.servers.[].host' $CONF_FILE | awk '{print $1":'$ssh_port'"}')
hdfs_package_dir=$(yq '.hdfs.package-dir' $CONF_FILE)
hdfs_plugin_dir=$(yq '.hdfs.plugin-dir' $CONF_FILE)

# ---------------------------------------------------------------------------
# step-1: refresh package to nodes
# ---------------------------------------------------------------------------
juicefs_package_path=$(dirname $juicefs_package_dir)
pssh -H "$juicefs_host_and_port_string" -l $deploy_user -i -P "if [ ! -d $juicefs_package_path ];then sudo mkdir -p $juicefs_package_path; sudo chown -R $deploy_user:$deploy_user $juicefs_package_path echo 'package dir has been created successfully!';else echo 'package dir has been already created!'; fi"
sudo chown $deploy_user:$deploy_user $juicefs_package_dir
pscp -H "$juicefs_host_and_port_string" -l $deploy_user -r $juicefs_package_dir $juicefs_package_path
echo -e "\033[34m <<step-1: Refresh package to nodes>> has been distributed successfully! \033[0m"

# ---------------------------------------------------------------------------
# step-2: refresh configuration to nodes
# ---------------------------------------------------------------------------
pssh -H "$juicefs_host_and_port_string" -l $deploy_user -i -P "if [ ! -d $BASE_DIR ];then sudo mkdir -p $BASE_DIR; sudo chown -R $deploy_user:$deploy_user $BASE_DIR echo 'base dir has been created successfully!';else echo 'base dir has been already created!'; fi"
pscp -H "$juicefs_host_and_port_string" -l $deploy_user -r $BASE_DIR/* $BASE_DIR
echo -e "\033[34m <<step-2: Refresh configuration to nodes>> has been distributed successfully! \033[0m"

# ---------------------------------------------------------------------------
# step-3: install package
# ---------------------------------------------------------------------------
pssh -H "$juicefs_host_and_port_string" -l $deploy_user -P -i "$BASE_DIR/sbin/deploy-juicefs.sh"
echo -e "\033[34m <<step-3: Install package]>> has been done successfully! \033[0m"

# ---------------------------------------------------------------------------
# Integration
# ---------------------------------------------------------------------------
# HDFS
if [ "$hdfs_integration_enable" = "true" ];then
  # ---------------------------------------------------------------------------
  # step-1: refresh package to nodes
  # ---------------------------------------------------------------------------
  hdfs_package_path=$(dirname $hdfs_package_dir)
  pssh -H "$hdfs_host_and_port_string" -l $deploy_user -i -P "if [ ! -d $hdfs_package_path ];then sudo mkdir -p $hdfs_package_path; sudo chown -R $deploy_user:$deploy_user $hdfs_package_path echo 'package dir has been created successfully!';else echo 'package dir has been already created!'; fi"
  sudo chown $deploy_user:$deploy_user $hdfs_package_dir
  pscp -H "$hdfs_host_and_port_string" -l $deploy_user -r $hdfs_package_dir $hdfs_package_path

  hdfs_plugin_path=$(dirname $hdfs_plugin_dir)
  pssh -H "$hdfs_host_and_port_string" -l $deploy_user -i -P "if [ ! -d $hdfs_plugin_path ];then sudo mkdir -p $hdfs_plugin_path; sudo chown -R $deploy_user:$deploy_user $hdfs_plugin_path echo 'package dir has been created successfully!';else echo 'package dir has been already created!'; fi"
  sudo chown $deploy_user:$deploy_user $hdfs_plugin_dir
  pscp -H "$hdfs_host_and_port_string" -l $deploy_user -r $hdfs_plugin_dir $hdfs_plugin_path
  
  echo -e "\033[34m <<[Integration HDFS] step-1: Refresh package to nodes>> has been distributed successfully! \033[0m"

  # ---------------------------------------------------------------------------
  # step-2: refresh configuration to nodes
  # ---------------------------------------------------------------------------
  pssh -H "$hdfs_host_and_port_string" -l $deploy_user -i -P "if [ ! -d $BASE_DIR ];then sudo mkdir -p $BASE_DIR; sudo chown -R $deploy_user:$deploy_user $BASE_DIR echo 'base dir has been created successfully!';else echo 'base dir has been already created!'; fi"
  pscp -H "$hdfs_host_and_port_string" -l $deploy_user -r $BASE_DIR/* $BASE_DIR
  echo -e "\033[34m <<[Integration HDFS] step-2: Refresh configuration to nodes>> has been distributed successfully! \033[0m"

  # ---------------------------------------------------------------------------
  # step-3: install package
  # ---------------------------------------------------------------------------
  pssh -H "$hdfs_host_and_port_string" -l $deploy_user -P -i "$BASE_DIR/sbin/deploy-juicefs-hadoop.sh"
  echo -e "\033[34m <<[Integration HDFS] step-3: Install package>> has been done successfully! \033[0m"
else
  echo -e "\033[31m <<[Integration HDFS]>> has been skipped! \033[0m"
fi
