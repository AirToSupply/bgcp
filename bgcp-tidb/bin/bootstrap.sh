#!/bin/bash

WORK_DIR=`dirname $0`
WORK_DIR=`cd ${WORK_DIR};pwd`
BASE_DIR=`cd ${WORK_DIR};cd ..;pwd`
CONF_DIR=`cd ${WORK_DIR};cd ../conf;pwd`
CONF_FILE=$CONF_DIR/setup.yaml
TOPO_CONF_FILE=$CONF_DIR/topology.yaml
TIDB_VERSION=$(yq '.version' $CONF_FILE)

eval "cat <<EOF
$(<$BASE_DIR/blanner.txt)
EOF
" 2> /dev/null

# ----------------------------------------------------------
# Configuration
# ----------------------------------------------------------
cluser_name=$(yq '.tidb.cluster' $CONF_FILE)
deploy_user=$(yq '.global.user' $TOPO_CONF_FILE)
server_package_dir=$(yq '.server-package-dir' $CONF_FILE)
toolkit_package_dir=$(yq '.toolkit-package-dir' $CONF_FILE)
deploy_dir=$(yq '.tiup-deploy-dir' $CONF_FILE)
who=`whoami`

tiup --version
if [ $? -eq 0 ];then
  echo -e "\033[31m tiup has been already installed! \033[0m"
  exit
fi

if [ "$who" != "$deploy_user" ];then 
  echo -e "\033[31m current user[$who] is not deploy user[$deploy_user]! \033[0m"
  exit
fi

# ----------------------------------------------------------
# step-1: Environment Variables Injection
# ----------------------------------------------------------
source ~/.bashrc
tidb_home_value=$(cat ~/.bashrc | grep '^export TIDB_HOME=')
if [ -z "$tidb_home_value" ];then
  echo -e "\n# TiDB\nexport TIDB_HOME=$deploy_dir\nexport TIDB_CLUSTER_NAME=$cluser_name" >> ~/.bashrc
  sleep 1s
  source ~/.bashrc
  echo -e "\033[34m [step-1: Environment Variables Injection] has injected \$TIDB_HOME successfully! \033[0m"
else
  echo -e "\033[31m [step-1: Environment Variables Injection] \$TIDB_HOME has been already existed! \033[0m"
fi
source ~/.bashrc

# ----------------------------------------------------------
# step-2: Install thrid-party packages
# ----------------------------------------------------------
sudo yum -y install numactl.x86_64
sudo yum -y install mysql-server mysql mysql-devel
echo -e "\033[34m [step-2: Install thrid-party packages] has been installed! \033[0m"

# ----------------------------------------------------------
# step-3: Install tiup
# ----------------------------------------------------------
if [ ! -d $deploy_dir ];then
  sudo mkdir -p $deploy_dir
  sudo chown -R $deploy_user:$deploy_user $deploy_dir
  echo -e "\033[34m [step-3: Install tiup] tiup deploy path[$deploy_dir] has been created successfully! \033[0m"
else
  echo -e "\033[31m [step-3: Install tiup] tiup deploy path[$deploy_dir] has been already created! \033[0m"
fi

tiup --version
if [ $? -eq 0 ];then
  echo -e "\033[34m [step-3: Install tiup] tiup has been already deployed! \033[0m"
  exit
fi

server_package_filename=$(basename $server_package_dir)
server_package_subdir=${server_package_filename%.tar.gz}
toolkit_package_filename=$(basename $toolkit_package_dir)
toolkit_package_subdir=${toolkit_package_filename%.tar.gz}

sudo tar -xzvf $server_package_dir -C $deploy_dir
sudo chown -R $deploy_user:$deploy_user $deploy_dir
sh $deploy_dir/$server_package_subdir/local_install.sh
source ~/.bash_profile

sudo tar xf $toolkit_package_dir -C $deploy_dir
sudo chown -R $deploy_user:$deploy_user $deploy_dir
ls -ld $deploy_dir/$server_package_subdir $deploy_dir/$toolkit_package_subdir
cd $deploy_dir/$server_package_subdir
cp -rp keys ~/.tiup/
tiup mirror merge ../$toolkit_package_subdir
echo -e "\033[34m [step-3: Install tiup] tiup has been deployed successfully! \033[0m"
