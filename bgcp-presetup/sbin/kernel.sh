#!/bin/bash

WORK_DIR=`dirname $0`
WORK_DIR=`cd ${WORK_DIR};pwd`

CONF_DIR=`cd ${WORK_DIR};cd ../conf;pwd`
CONF_FILE=$CONF_DIR/setup.yaml

echo "[----------------------------------------> Kernel Optimization Setting <----------------------------------------]"

# ##########################################################
# step-1: os kernel optimze
# ##########################################################
sed -i '/^[^#]/,$d' /etc/sysctl.conf
yq '.os.kernel' $CONF_FILE | awk -F ': ' '{print $1 " = " $2}' >> /etc/sysctl.conf
sysctl -p
echo -e "\033[34m [kernel optimzer] has been configured successfully! \033[0m"

# ##########################################################
# step-2: os limit optimze
# ##########################################################
# centos 7.x is 20-xxx, centos 6.0 is 90-xxx
LIMIT_CONF=/etc/security/limits.d/20-nproc.conf
if [ ! -f $LIMIT_CONF ]; then
  mkdir -p $LIMIT_CONF
fi
sed -i '/^[^#]/,$d' $LIMIT_CONF
for entry in `yq '.os.limit' $CONF_FILE | awk -F ': ' '{print $1"="$2}'`
do
  c=`echo $entry | awk -F '=' '{print $1, $2}'`
  sed -i "\$a* soft $c\n* hard $c" $LIMIT_CONF
done
echo -e "\033[34m [limit optimzer] has been configured successfully! \033[0m"

# ##########################################################
# step-3: close SELINUX
# ##########################################################
setenforce 0
sed -i 's#SELINUX=enforcing#SELINUX=disabled#g' /etc/sysconfig/selinux
sed -i 's#SELINUX=enforcing#SELINUX=disabled#g' /etc/selinux/config
echo -e "\033[34m [SELINUX] has been closed successfully! \033[0m"

# ##########################################################
# step-4: close firewall
# ##########################################################
systemctl stop firewalld.service
systemctl disable firewalld.service
systemctl status firewalld.service
echo -e "\033[34m [firewall] has been closed successfully! \033[0m"

# ##########################################################
# step-5: close swap
# ##########################################################
swap_value=$(yq '.os.swap.enable // "false"' $CONF_FILE)
if [ "$swap_value" = "false" ]; then
  swapoff -a
  sed -ri '/^[^#]*swap/s@^@#@' /etc/fstab
  echo -e "\033[34m [swap] has been closed successfully! \033[0m"
fi

# ##########################################################
# step-6: time zone setting
# ##########################################################
time_zone_value=$(yq '.os.time-zone' $CONF_FILE)
echo $time_zone_value > /etc/timezone
timedatectl set-timezone $time_zone_value
echo -e "\033[34m [time zone] has been configured successfully! \033[0m"

# ##########################################################
# step-7: locale support zh
# ##########################################################
locale_value=$(yq '.locale.enable // "true"' $CONF_FILE)
if [ "$locale_value" = "true" ]; then
  support_zh=$(locale -a | grep -c XXXXXXXXXX)
  if [ $support_zh -eq 0 ];then
    yum -y install glibc-common
    yum -y install langpacks-zh_CN
  fi
  echo "LANG=\"zh_CN.utf8\"" > /etc/locale.conf
  source /etc/locale.conf
  echo -e "\033[34m [locale support zh] has been configured successfully! \033[0m"
fi

echo "[----------------------------------------> Kernel Optimization Setting <----------------------------------------]"
