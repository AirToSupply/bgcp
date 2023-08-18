#!/bin/bash

WORK_DIR=`dirname $0`
WORK_DIR=`cd ${WORK_DIR};pwd`

CONF_DIR=`cd ${WORK_DIR};cd ../conf;pwd`
CONF_FILE=$CONF_DIR/setup.yaml

echo "[----------------------------------------> Hostname Setting <----------------------------------------]"

# ##########################################################
# configuration
# ##########################################################
ipaddr=$(yq '.network.ip' $CONF_FILE)
host_name=$(yq '.network.hostname' $CONF_FILE)

# ##########################################################
# step-1: hostname setting
# ##########################################################
host_name_value=$(hostname | grep "^$host_name$")
if [[ -n "$host_name_value" ]]; then
  echo -e "\033[31m [hostname: $host_name] has been already setted! \033[0m"
else
  # >||<
  hostnamectl set-hostname $host_name
  # >||<
  echo -e "\033[34m [hostname: $host_name] has been configured successfully! \033[0m"
fi

# ##########################################################
# step-2: registe hosts
# ##########################################################
ipaddr_value=$(cat /etc/hosts | grep "^$ipaddr")
if [[ -n "$ipaddr_value" ]]; then
  echo -e "\033[31m [ipaddr: $ipaddr] has been already registed! \033[0m"
else
  # >||<
  sed -i '$a\'$ipaddr' '$host_name'' /etc/hosts
  # >||<
  echo -e "\033[34m [ipaddr: $ipaddr] has registed to hosts successfully! \033[0m"
fi

echo "[----------------------------------------> Hostname Setting <----------------------------------------]"
