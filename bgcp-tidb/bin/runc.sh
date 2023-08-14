#!/bin/bash

WORK_DIR=`dirname $0`
WORK_DIR=`cd ${WORK_DIR};pwd`
BASE_DIR=`cd ${WORK_DIR};cd ..;pwd`
CONF_DIR=`cd ${WORK_DIR};cd ../conf;pwd`
CONF_FILE=$CONF_DIR/setup.yaml
TOPO_CONF_FILE=$CONF_DIR/topology.yaml
CLUSTER_NAME=`echo $TIDB_CLUSTER_NAME`
CLUSTER_VERSION=$(yq '.tidb.version' $CONF_FILE)
TIDB_VERSION=$(yq '.version' $CONF_FILE)
DEPLOY_USER=$(yq '.global.user' $TOPO_CONF_FILE)

eval "cat <<EOF
$(<$BASE_DIR/blanner.txt)
EOF
" 2> /dev/null

who=`whoami`
if [ "$who" != "$DEPLOY_USER" ];then
  echo -e "\033[31m current user[$who] is not deploy user[$DEPLOY_USER]! \033[0m"
  exit
fi

# echo $@
# shift 1
# echo $@

case $1 in

"check")
  tiup cluster check $TOPO_CONF_FILE --user $DEPLOY_USER
  ;;

"check-apply")
  tiup cluster check $TOPO_CONF_FILE --apply --user $DEPLOY_USER
  ;;

"deploy")
  tiup cluster deploy $CLUSTER_NAME $CLUSTER_VERSION $TOPO_CONF_FILE --user $DEPLOY_USER
  ;;

"list")
  tiup cluster list
  ;;

"display")
  tiup cluster display $CLUSTER_NAME
  ;;

"init")
  tiup cluster start $CLUSTER_NAME --init | tee $CONF_DIR/pass
  ;;

"start")
  shift 1
  tiup cluster start $CLUSTER_NAME $@
  ;;

"stop")
  shift 1
  tiup cluster stop $CLUSTER_NAME $@
  ;;

"edit")
  tiup cluster edit-config $CLUSTER_NAME
  ;;

"reload")
  tiup cluster reload $CLUSTER_NAME $@
  ;;

"--help")
  echo -e "\033[34m [check]       \033[0m  => tiup cluster check /tmp/topology.yaml --user foo"
  echo -e "\033[34m [check-apply] \033[0m  => tiup cluster check /tmp/topology.yaml --apply --user foo"
  echo -e "\033[34m [deploy]      \033[0m  => tiup cluster deploy <cluster name> <cluster version> /tmp/topology.yaml --user foo"
  echo -e "\033[34m [list]        \033[0m  => tiup cluster list"
  echo -e "\033[34m [display]     \033[0m  => tiup cluster display <cluster name>"
  echo -e "\033[34m [init]        \033[0m  => tiup cluster start <cluster name> --init"
  echo -e "\033[34m [start]       \033[0m  => tiup cluster start <cluster name>"
  echo -e "                 => tiup cluster start <cluster name> -N 192.168.0.1"
  echo -e "                 => tiup cluster start <cluster name> -R tidb,tikv"
  echo -e "\033[34m [stop]        \033[0m  => tiup cluster stop <cluster name>"
  echo -e "                 => tiup cluster stop <cluster name> -N 192.168.0.1"
  echo -e "                 => tiup cluster stop <cluster name> -R tidb,tikv"
  echo -e "\033[34m [edit]        \033[0m  => tiup cluster edit-config <cluster name>"
  echo -e "\033[34m [reload]      \033[0m  => tiup cluster reload <cluster name>"
  echo -e "                 => tiup cluster reload <cluster name> -N 192.168.0.1"
  echo -e "                 => tiup cluster reload <cluster name> -R tidb,tikv"
  ;;

*)
  echo Invalid Args!
  echo You can specfiy --help to show commands!
  ;;

esac

