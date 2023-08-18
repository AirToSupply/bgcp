#!/bin/bash

WORK_DIR=`dirname $0`
WORK_DIR=`cd ${WORK_DIR};pwd`

CONF_DIR=`cd ${WORK_DIR};cd ../conf;pwd`
CONF_FILE=$CONF_DIR/setup.yaml

echo "[----------------------------------------> SSH Setting <----------------------------------------]"

# ##########################################################
# configuration
# ##########################################################
user=$(yq '.user.name' $CONF_FILE)
hostname=$(yq '.network.hostname' $CONF_FILE)
port=$(yq '.ssh.port' $CONF_FILE)

SSH_DIR=/home/$user/.ssh
SSH_ID_RSA_DIR=/home/$user/.ssh/id_rsa
SSH_ID_RSA_PUB_DIR=/home/$user/.ssh/id_rsa.pub

if [ ! -d $SSH_DIR ] || [ ! -f $SSH_ID_RSA_DIR ] || [ ! -f $SSH_ID_RSA_PUB_DIR ]; then
  # >||<
  su - $user -c "ssh-keygen -t rsa"
  su - $user -c "cat ~/.ssh/id_rsa.pub > ~/.ssh/authorized_keys && chmod 600 ~/.ssh/authorized_keys"
  # >||<
  echo -e "\033[34m [ssh: $user] has been configured successfully! \033[0m"
else
  echo -e "\033[31m [ssh: $user] has been already configured! \033[0m"
fi

echo "[----------------------------------------> SSH Setting <----------------------------------------]"
