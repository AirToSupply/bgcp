#!/bin/bash

WORK_DIR=`dirname $0`
WORK_DIR=`cd ${WORK_DIR};pwd`

CONF_DIR=`cd ${WORK_DIR};cd ../conf;pwd`
CONF_FILE=$CONF_DIR/setup.yaml

echo "[----------------------------------------> JDK Setting <----------------------------------------]"

# ##########################################################
# configuration
# ##########################################################
size=$(yq '.jdk | length' $CONF_FILE)

if [ $size -ne 0 ];then
  pkgs=$(expr $size - 1)
  for idx in $(seq 0 $pkgs)
  do
    version=`i=$idx yq '.jdk.[env(i)]' $CONF_FILE | yq '.version'`
    package_dir=`i=$idx yq '.jdk.[env(i)]' $CONF_FILE | yq '.package-dir'`
    deploy_dir=`i=$idx yq '.jdk.[env(i)]' $CONF_FILE | yq '.deploy-dir'`
    home_dir=`i=$idx yq '.jdk.[env(i)]' $CONF_FILE | yq '.home-dir'`
    deploy_user=`i=$idx yq '.jdk.[env(i)]' $CONF_FILE | yq '.deploy-user // "root"'`
    env_enable=`i=$idx yq '.jdk.[env(i)]' $CONF_FILE | yq '.env-enable // "false"'`
    
    # tar
    if [ ! -d $home_dir ];then 
      if [ "$deploy_user" = "root" ];then 
        tar -zxvf $package_dir -C $deploy_dir
      else
        tar -zxvf $package_dir -C $deploy_dir
        chown -R $deploy_user:$deploy_user $home_dir
      fi
      echo -e "\033[34m [JDK($version) USER($deploy_user)] has decompressed successfully! \033[0m"
    fi

    # env inject
    if [ "$env_enable" = "true" ];then
      if [ "$deploy_user" = "root" ];then
        java_home_value=`echo $JAVA_HOME`
        if [ -z "$java_home_value" ];then 
          echo -e "\n# JDK\nexport JAVA_HOME=$home_dir\nexport PATH=\$PATH:\$JAVA_HOME/bin" >> ~/.bashrc
          source ~/.bashrc
          java -version
        fi
      else
        java_home_value=$(su - $deploy_user -c "echo \$JAVA_HOME")
        if [ -z "$java_home_value" ];then
          echo -e "\n# JDK\nexport JAVA_HOME=$home_dir\nexport PATH=\$PATH:\$JAVA_HOME/bin" >> /home/$deploy_user/.bashrc
          su - $deploy_user -c "source ~/.bashrc"
          su - $deploy_user -c "java -version"
        fi
      fi
      echo -e "\033[34m [JDK($version) USER($deploy_user)] has injected \$JAVA_HOME successfully! \033[0m"
    else
      $home_dir/bin/java -version
      echo -e "\033[34m [JDK($version) USER($deploy_user)] has installed successfully! \033[0m"
    fi

  done
else
  echo -e "\033[31m Not Found JDK Configuration! \033[0m"
fi

echo "[----------------------------------------> JDK Setting <----------------------------------------]"
