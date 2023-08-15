#!/bin/bash

WORK_DIR=`dirname $0`
WORK_DIR=`cd ${WORK_DIR};pwd`

CONF_DIR=`cd ${WORK_DIR};cd ../conf;pwd`
CONF_FILE=$CONF_DIR/setup.yaml

# ----------------------------------------------------------
# Configuration
# ----------------------------------------------------------
deploy_user=$(yq '.deploy-user' $CONF_FILE)

package_dir=$(yq '.juicefs.package-dir' $CONF_FILE)
deploy_dir=$(yq '.juicefs.deploy-dir' $CONF_FILE)
data_dir=$(yq '.juicefs.data-dir' $CONF_FILE)
log_dir=$(yq '.juicefs.log-dir' $CONF_FILE)
cache_dir=$(yq '.juicefs.cache-dir' $CONF_FILE)

filesystem_name=$(yq '.juicefs.fs-name' $CONF_FILE)

metadata_type=$(yq '.juicefs.metadata.type' $CONF_FILE)
storage_type=$(yq '.juicefs.storage.type' $CONF_FILE)

# ----------------------------------------------------------
# JuiceFS metadata url
# ----------------------------------------------------------
meta_url=
case $metadata_type in
mysql)
  ip=$(yq '.juicefs.metadata.config.ip' $CONF_FILE)
  port=$(yq '.juicefs.metadata.config.port' $CONF_FILE)
  user=$(yq '.juicefs.metadata.config.user' $CONF_FILE)
  password=$(yq '.juicefs.metadata.config.password' $CONF_FILE)
  database=$(yq '.juicefs.metadata.config.database' $CONF_FILE)
  addons=$(yq '.juicefs.metadata.config.addons' $CONF_FILE)
  meta_url="mysql://$user:$password@($ip:$port)/$database"
  if [[ -n "$addons" ]]; then
    meta_url="\"$meta_url?$addons\""
  fi
  ;;
postgresql)
  ip=$(yq '.juicefs.metadata.config.ip' $CONF_FILE)
  port=$(yq '.juicefs.metadata.config.port' $CONF_FILE)
  user=$(yq '.juicefs.metadata.config.user' $CONF_FILE)
  password=$(yq '.juicefs.metadata.config.password' $CONF_FILE)
  database=$(yq '.juicefs.metadata.config.database' $CONF_FILE)
  addons=$(yq '.juicefs.metadata.config.addons' $CONF_FILE)
  meta_url="postgres://$user:$password@$ip:$port/$database"
  if [[ -n "$addons" ]]; then
    meta_url="\"$meta_url?$addons\""
  fi
  ;;
*)
  echo -e "\033[31m [ERROR] metadata type [$metadata_type] is not support! \033[0m"
  exit 1
  ;;
esac

echo -e "\033[34m [juicefs meta url] => $meta_url \033[0m"

# ----------------------------------------------------------
# step-0: Mkdir juicefs related path
# ----------------------------------------------------------
if [ ! -d $data_dir ];then
  sudo mkdir -p $data_dir
  sudo chown -R $deploy_user:$deploy_user $data_dir 
fi
if [ ! -d $log_dir ];then
  sudo mkdir -p $log_dir
  sudo chown -R $deploy_user:$deploy_user $log_dir
fi
if [ ! -d $cache_dir ];then
  sudo mkdir -p $cache_dir
  sudo chown -R $deploy_user:$deploy_user $cache_dir
fi
echo -e "\033[34m [step-0:  Mkdir juicefs related path] has been created successfully! \033[0m"

# ----------------------------------------------------------
# step-1: Deploy juicefs
# ----------------------------------------------------------
juicefs version
if [ $? -ne '0' ];then
  # || >< ||
  tmp_dir=$(mktemp -d /tmp/juicefs-install.XXXX)
  tar -zxf $package_dir -C $tmp_dir
  if [ -O $deploy_dir ]; then
    mv -f $tmp_dir/juicefs $deploy_dir/juicefs
  else
    echo "Install juicefs to $deploy_dir requires root permission"
    sudo mv -f $tmp_dir/juicefs $deploy_dir/juicefs
  fi
  sudo rm -rf $tmp_dir
  # || >< ||
  echo -e "\033[34m [step-1: Deploy juicefs] has been installed successfully! \033[0m"  
else
  echo -e "\033[31m [step-1: Deploy juicefs] has been already installed! \033[0m"
fi

# ----------------------------------------------------------
# step-2: Format juicefs
# ----------------------------------------------------------
juicefs config "$meta_url"
if [ $? -ne '0' ];then
  case $storage_type in
  minio)
    endpoint=$(yq '.juicefs.storage.config.endpoint' $CONF_FILE)
    bucket=$(yq '.juicefs.storage.config.bucket' $CONF_FILE)
    access_key=$(yq '.juicefs.storage.config.access-key' $CONF_FILE)
    secret_key=$(yq '.juicefs.storage.config.secret-key' $CONF_FILE)

    juicefs format \
            --storage $storage_type \
            --bucket $endpoint/$bucket \
            --access-key $access_key \
            --secret-key $secret_key \
            $meta_url \
            $filesystem_name
    ;;
  *)
    echo -e "\033[31m [step-2: Format juicefs] storage type [$storage_type] is not support! \033[0m"
    exit 1
    ;;
  esac
  if [ $? -eq '0' ];then
    echo -e "\033[34m [step-2: Format juicefs] has been formatted successfully! \033[0m"
  else
    echo -e "\033[31m [step-2: Format juicefs] has been formatted error! \033[0m"
  fi
else
  echo -e "\033[31m [step-2: Format juicefs] has been already formatted! \033[0m"
fi
