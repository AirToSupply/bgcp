#!/bin/bash

WORK_DIR=`dirname $0`
WORK_DIR=`cd ${WORK_DIR};pwd`

CONF_DIR=`cd ${WORK_DIR};cd ../conf;pwd`
CONF_FILE=$CONF_DIR/setup.yaml

# ----------------------------------------------------------
# Configuration
# ----------------------------------------------------------
deploy_user=$(yq '.deploy-user' $CONF_FILE)

package_dir=$(yq '.minio.package-dir' $CONF_FILE)
deploy_dir=$(yq '.minio.deploy-dir' $CONF_FILE)
home_dir=$(yq '.minio.home-dir' $CONF_FILE)
log_dir=$(yq '.minio.log-dir' $CONF_FILE)
server_port=$(yq '.minio.server-port' $CONF_FILE)
web_console_port=$(yq '.minio.web-console-port' $CONF_FILE)

host_name=`hostname`

# ----------------------------------------------------------
# step-0: mkdir minio drive
# ----------------------------------------------------------
worker_size=$(yq '.minio.volumns | length' $CONF_FILE)
echo -e "\033[34m [step-0: mkdir minio drive] Find $worker_size MinIO Server Nodes! \033[0m"

worker_last_index=$(expr $worker_size - 1)
for idx in $(seq 0 $worker_last_index)
do
  worker=`i=$idx yq '.minio.volumns.[env(i)]' $CONF_FILE | yq '.worker'`
  if [ "$worker" = "$host_name" ];then
    drive_size=$(x=$idx yq '.minio.volumns.[env(x)].drive | length' $CONF_FILE)
    echo -e "\033[34m [step-0: mkdir minio drive] Find $drive_size Drives from MinIO Server Node[$worker]! \033[0m"
    drive_last_index=$(expr $drive_size - 1)
    for didx in $(seq 0 $drive_last_index)
    do
      drive=$(x=$idx y=$didx yq '.minio.volumns.[env(x)].drive.[env(y)]' $CONF_FILE)
      echo -e "\033[34m [step-0: mkdir minio drive] There is Drive[$drive] in MinIO Server Node[$worker]! \033[0m"
      # |>O - O<|
      if [ ! -d $drive ];then
        sudo mkdir -p $drive
        sudo chown -R $deploy_user:$deploy_user $drive
        echo -e "\033[34m [step-0: mkdir minio drive] MinIO Server Node[$worker] and Drive[$drive] has been created successfully! \033[0m"
      else
        echo -e "\033[31m [step-0: mkdir minio drive] MinIO Server Node[$worker] and Drive[$drive] has been already created! \033[0m"
      fi
      # |>O - O<|
    done
  fi
done

# ----------------------------------------------------------
# step-1: decompress
# ----------------------------------------------------------
if [ ! -d $home_dir ];then 
  sudo tar -zxvf $package_dir -C $deploy_dir
  sudo chown -R $deploy_user:$deploy_user $home_dir
  chmod u+x $home_dir/bin/*
  chmod u+x $home_dir/sbin/*
  echo -e "\033[34m [step-1: decompress] MinIO Package has been decompressed successfully! \033[0m"
else
  echo -e "\033[31m [step-1: decompress] MinIO Package has been already decompressed! \033[0m"
fi

# ----------------------------------------------------------
# step-2: Environment Variables Injection
# ----------------------------------------------------------
source ~/.bashrc
minio_home_value=$(cat ~/.bashrc | grep '^export MINIO_HOME=')
if [ -z "$minio_home_value" ];then
  echo -e "\n# MINIO\nexport MINIO_HOME=$home_dir\nexport PATH=\$PATH:\$MINIO_HOME/bin:\$MINIO_HOME/sbin" >> ~/.bashrc
  sleep 1s
  source ~/.bashrc
  mc --version
  echo -e "\033[34m [step-2: Environment Variables Injection] has injected \$MINIO_HOME successfully! \033[0m"
else
  echo -e "\033[31m [step-2: Environment Variables Injection] \$MINIO_HOME has been already existed! \033[0m"
fi
source ~/.bashrc

# ----------------------------------------------------------
# step-3: MinIO Server Environment Variables Setting
# ----------------------------------------------------------
sed -i '/^[^#]/,$d' $MINIO_HOME/conf/minio-env.conf
yq '.minio.env' $CONF_FILE | grep -v "^#" | awk -F ': ' '{print $1 "=" $2}' >> $MINIO_HOME/conf/minio-env.conf
echo -e "\033[34m [step-3: MinIO Server Environment Variables Setting] has been configured successfully! \033[0m"

# ----------------------------------------------------------
# step-4: MinIO Drives Setting
# ----------------------------------------------------------
sed -i '/^[^#]/,$d' $MINIO_HOME/conf/minio-volumns.conf
worker_size=$(yq '.minio.volumns | length' $CONF_FILE)
worker_last_index=$(expr $worker_size - 1)
for idx in $(seq 0 $worker_last_index)
do
  worker=`i=$idx yq '.minio.volumns.[env(i)]' $CONF_FILE | yq '.worker'`
  drive_size=$(x=$idx yq '.minio.volumns.[env(x)].drive | length' $CONF_FILE)
  drive_last_index=$(expr $drive_size - 1)
  for didx in $(seq 0 $drive_last_index)
  do
    drive=$(x=$idx y=$didx yq '.minio.volumns.[env(x)].drive.[env(y)]' $CONF_FILE)
    echo "$worker $drive" >> $MINIO_HOME/conf/minio-volumns.conf
  done
done
echo -e "\033[34m [step-4: MinIO Drives Setting] has been configured successfully! \033[0m"

# ----------------------------------------------------------
# step-5: MinIO Nodes Setting
# ----------------------------------------------------------
yq '.minio.volumns.[].worker' $CONF_FILE > $MINIO_HOME/conf/workers
echo -e "\033[34m [step-5: MinIO Nodes Setting] has been configured successfully! \033[0m"

# ----------------------------------------------------------
# step-6: MinIO Server Runtime Setting
# ----------------------------------------------------------
if [ ! -d $log_dir ];then
  sudo mkdir -p $log_dir
  sudo chown -R $deploy_user:$deploy_user $log_dir
fi
sed -i "s#^MINIO_SERVER_LOG_DIR=.*#MINIO_SERVER_LOG_DIR=$log_dir#g" $MINIO_HOME/sbin/minio-start.sh
sed -i "s#^MINIO_SERVER_PORT=.*#MINIO_SERVER_PORT=$server_port#g" $MINIO_HOME/sbin/minio-start.sh
sed -i "s#^MINIO_CONSOLE_ADDRESS_PORT=.*#MINIO_CONSOLE_ADDRESS_PORT=$web_console_port#g" $MINIO_HOME/sbin/minio-start.sh
echo -e "\033[34m [step-6: MinIO Server Runtime Setting] has been configured successfully! \033[0m"
