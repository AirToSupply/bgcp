#!/bin/bash

WORK_DIR=`dirname $0`
WORK_DIR=`cd ${WORK_DIR};pwd`

CONF_DIR=`cd ${WORK_DIR};cd ../conf;pwd`
CONF_FILE=$CONF_DIR/setup.yaml

echo "[----------------------------------------> User Setting <----------------------------------------]"

# ##########################################################
# configuration
# ##########################################################
user=$(yq '.user.name' $CONF_FILE)
passwd=$(yq '.user.passwd' $CONF_FILE)
sudo_enable=$(yq '.user.sudo' $CONF_FILE)

# ##########################################################
# step-1: create group 
# ##########################################################
grep "^$user" /etc/group >& /dev/null
if [ $? -ne 0 ]; then
  # >||<
  groupadd $user
  # >||<
  echo -e "\033[34m [group: $user] create success! \033[0m"
else
  echo -e "\033[31m [group: $user] has been already existed! \033[0m"
fi

# ##########################################################
# step-2: create user
# ##########################################################
grep "^$user" /etc/passwd >& /dev/null
if [ $? -ne 0 ]; then
  # >||<
  useradd -s /bin/bash -m -d /home/$user -g $user $user
  # >||<
  echo -e "\033[34m [user: $user] create success! \033[0m"
else
  echo -e "\033[31m [user: $user] has been already existed! \033[0m"
fi

# ##########################################################
# step-3: add user password
# ##########################################################
# >||<
echo "$user":"$passwd" | chpasswd
# >||<
echo -e "\033[34m [passwd: ******] add user password success! \033[0m"

# ##########################################################
# step-4: user sudo setting
# ##########################################################
if [[ $sudo_enable = "true" ]]; then
  sudoers=$(cat /etc/sudoers |grep "^$user")
  if [[ -n "$sudoers" ]]; then
    echo -e "\033[31m [user: $user] sudo has been already existed! \033[0m"
  else
    # >||<
    sed -i "/^root/a\\$user  ALL=(ALL:ALL) NOPASSWD: ALL" /etc/sudoers
    # >||<
    echo -e "\033[34m [user: $user] sudo has been configured successfully! \033[0m"
  fi
fi

echo "[----------------------------------------> User Setting <----------------------------------------]"
