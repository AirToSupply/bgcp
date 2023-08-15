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
cache_size=$(yq '.juicefs.mount.config.cache-size' $CONF_FILE)

hdfs_package_dir=$(yq '.hdfs.package-dir' $CONF_FILE)
hdfs_deploy_dir=$(yq '.hdfs.deploy-dir' $CONF_FILE)
hdfs_home_dir=$(yq '.hdfs.home-dir' $CONF_FILE)
hdfs_plugin_dir=$(yq '.hdfs.plugin-dir' $CONF_FILE)

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
    meta_url="$meta_url?$addons"
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
    meta_url="$meta_url?$addons"
  fi
  ;;
*)
  echo -e "\033[31m [ERROR] metadata type [$metadata_type] is not support! \033[0m"
  exit 1
  ;;
esac

echo -e "\033[34m [juicefs meta url] => $meta_url \033[0m"

# ----------------------------------------------------------
# step-0: Mkdir juicefs related path for HDFS
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
echo -e "\033[34m [step-0:  Mkdir juicefs related path for HDFS] has been created successfully! \033[0m"

# ----------------------------------------------------------
# step-1: decompress
# ----------------------------------------------------------
if [ ! -d $hdfs_home_dir ];then
  sudo tar -zxvf $hdfs_package_dir -C $hdfs_deploy_dir
  sudo chown -R $deploy_user:$deploy_user $hdfs_home_dir
  echo -e "\033[34m [step-1: decompress] HADOOP Package has been decompressed successfully! \033[0m"
else
  echo -e "\033[31m [step-1: decompress] HADOOP Package has been already decompressed! \033[0m"
fi

# ----------------------------------------------------------
# step-2: Environment Variables Injection
# ----------------------------------------------------------
source ~/.bashrc
hadoop_home_value=$(cat ~/.bashrc | grep '^export HADOOP_HOME=')
if [ -z "$hadoop_home_value" ];then
  echo -e "\n# HADOOP"                                                      >> ~/.bashrc
  echo -e "export HADOOP_HOME=$hdfs_home_dir"                               >> ~/.bashrc
  echo -e "export HADOOP_CLASSPATH=\$(\$HADOOP_HOME/bin/hadoop classpath)"  >> ~/.bashrc
  echo -e "export HADOOP_CONF_DIR=\$HADOOP_HOME/etc/hadoop"                 >> ~/.bashrc
  echo -e "export PATH=\$PATH:\$HADOOP_HOME/bin:\$HADOOP_HOME/sbin"         >> ~/.bashrc
  sleep 1s
  source ~/.bashrc
  hadoop version
  echo -e "\033[34m [step-2: Environment Variables Injection] has injected \$HADOOP_HOME successfully! \033[0m"
else
  echo -e "\033[31m [step-2: Environment Variables Injection] \$HADOOP_HOME has been already existed! \033[0m"
fi
source ~/.bashrc

# ----------------------------------------------------------
# step-3: JuiceFS plugin JAR deploy
# ----------------------------------------------------------
sudo cp $hdfs_plugin_dir $HADOOP_HOME/share/hadoop/common/lib/
sudo cp $hdfs_plugin_dir $HADOOP_HOME/share/hadoop/mapreduce/lib/
echo -e "\033[34m [step-3: Juicefs plugin JAR deploy] has been deployed successfully! \033[0m"

# ----------------------------------------------------------
# step-4: JuiceFS Setting for HDFS
# ----------------------------------------------------------
# tool
function update_core_site_xml {
  local x=`grep -c ">$1<" $3`
  if [ $x -eq 0 ];then
    CONTENT="\t<property>\n\t\t<name>$1</name>\n\t\t<value>$2</value>\n\t</property>"
    C=$(echo $CONTENT | sed 's/\//\\\//g')
    sed -i "/<\/configuration>/ s/.*/${C}\n&/" $3
  else
    sed -i "/>$1</{n;s#.*#\t\t<value>$2</value>#}" $3
  fi
}


core_site_file=$HADOOP_HOME/etc/hadoop/core-site.xml
# require config
# fs.defaultFS
update_core_site_xml "fs.defaultFS" "jfs://$filesystem_name" $core_site_file
# juicefs.meta
update_core_site_xml "juicefs.meta" $meta_url $core_site_file
# juicefs.cache-dir
update_core_site_xml "juicefs.cache-dir" $cache_dir $core_site_file
# juicefs.cache-size
update_core_site_xml "juicefs.cache-size" $cache_size $core_site_file
# custom  config
for entry in `yq '.hdfs.config' $CONF_FILE | grep -v "^#" | awk -F ': ' '{print $1"="$2}'`
do
  k=`echo $entry | awk -F '=' '{print $1}'`
  v=`echo $entry | awk -F '=' '{print $2}'`
  update_core_site_xml $k $v $core_site_file
done
echo -e "\033[34m [step-4: JuiceFS Setting for HDFS] has been setted successfully! \033[0m"

