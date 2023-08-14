#!/bin/bash

WORK_DIR=`dirname $0`
WORK_DIR=`cd ${WORK_DIR};pwd`
BASE_DIR=`cd ${WORK_DIR};cd ..;pwd`
CONF_DIR=`cd ${WORK_DIR};cd ../conf;pwd`
SCRIPT_DIR=`cd ${WORK_DIR};cd ../script;pwd`
CONF_FILE=$CONF_DIR/setup.yaml
TOPO_CONF_FILE=$CONF_DIR/topology.yaml
TIDB_VERSION=$(yq '.version' $CONF_FILE)

echo $SCRIPT_DIR
eval "cat <<EOF
$(<$BASE_DIR/blanner.txt)
EOF
" 2> /dev/null

# ----------------------------------------------------------
# Configuration
# ----------------------------------------------------------
cluser_name=$(yq '.tidb.cluster' $CONF_FILE)
deploy_user=$(yq '.global.user' $TOPO_CONF_FILE)
host=$(yq '.tidb.hosts.[0].host' $CONF_FILE)
port=$(yq '.tidb.port' $CONF_FILE)
user=$(yq '.tidb.user' $CONF_FILE)
charset=$(yq '.tidb.sys.character' $CONF_FILE)
lc=`cat $CONF_DIR/pass | grep -oP "The new password is: '\K[^ ]+"`
pass=${lc::-2}

if [ -z "$pass" ];then 
  echo -e "\033[31m [ERROR] tidb password is null, you need to init tidb cluster! \033[0m"
  exit
fi

echo -e "\033[34m [Connection] => mysql -u $user -h $host -P $port -p'$pass'  \033[0m"

echo -e "\033[31m [TiDB Client Select Options] \033[0m"
echo -e "\033[31m   [1] connect to tidb server. \033[0m"
echo -e "\033[31m   [2] refresh tidb system env. \033[0m"
echo -e "\033[31m   [3] print tidb version. \033[0m"
echo -e "\033[31m   [4] run tidb example script. \033[0m"
read -p "Your option [N]: " flag

function connect_to_server() {
  mysql -u $user -h $host -P $port -p$pass
}

function reflesh_server_sysenv() {
  charset_command="SET NAMES $charset; SET CHARACTER SET $charset;"
  mysql -u $user -h $host -P $port -p$pass -e "$charset_command"

  for entry in `yq '.tidb.sys.env' $CONF_FILE | grep -v "^#" | awk -F ': ' '{print $1"="$2}'`
  do
    k=`echo $entry | awk -F '=' '{print $1}'`
    v=`echo $entry | awk -F '=' '{print $2}'`
    c="SET GLOBAL $k = '$v';"
    mysql -u $user -h $host -P $port -p$pass -e "$c"
  done
  echo "Reset TiDB Server System Envoriments successfully!"
}

function print_tidb_version() {
  mysql -u $user -h $host -P $port -p$pass -e "source $SCRIPT_DIR/version.sql"  
}

function run_tidb_example() {
  mysql -u $user -h $host -P $port -p$pass -e "source $SCRIPT_DIR/example.sql"
}

case $flag in

"1")
  connect_to_server
  ;;

"2")
  reflesh_server_sysenv
  ;;

"3")
  print_tidb_version
  ;;

"4")
  run_tidb_example
  ;;

*)
  echo Invalid Options!
  ;;

esac


