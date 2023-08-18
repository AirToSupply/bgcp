#!/bin/bash

WORK_DIR=`dirname $0`
WORK_DIR=`cd ${WORK_DIR};pwd`

CONF_DIR=`cd ${WORK_DIR};cd ../conf;pwd`
CONF_FILE=$CONF_DIR/setup.yaml

# ----------------------------------------------------------
# Configuration
# ----------------------------------------------------------
package_dir=$(yq '.docker.package-dir' $CONF_FILE)
deploy_dir=$(yq '.docker.deploy-dir' $CONF_FILE)
data_dir=$(yq '.docker.data-dir' $CONF_FILE)

# ----------------------------------------------------------
# step-1: Close SELINUX
# ----------------------------------------------------------
setenforce 0
sed -i 's#SELINUX=enforcing#SELINUX=disabled#g' /etc/sysconfig/selinux
sed -i 's#SELINUX=enforcing#SELINUX=disabled#g' /etc/selinux/config
echo -e "\033[34m [step-1: Close SELINUX] has been closed successfully! \033[0m"

# ----------------------------------------------------------
# step-2: Mkdir docker related path
# ----------------------------------------------------------
if [ ! -d $data_dir ];then
  mkdir -p $data_dir
  echo -e "\033[34m [step-2:  Mkdir docker related path] has been created successfully! \033[0m"
else
  echo -e "\033[31m [step-2:  Mkdir docker related path] has been already created! \033[0m"
fi

# ----------------------------------------------------------
# step-3: Deploy docker
# ----------------------------------------------------------
docker --version
if [ $? -ne 0 ];then
  # || >< ||
  tmp_dir=$(mktemp -d /tmp/docker-install.XXXX)
  tar -zxf $package_dir -C $tmp_dir
  cp $tmp_dir/docker/* $deploy_dir/
  rm -rf $tmp_dir
  # || >< ||
  echo -e "\033[34m [step-3: Deploy docker] has been installed successfully! \033[0m"  
else
  echo -e "\033[31m [step-3: Deploy docker] has been already installed! \033[0m"
fi

# ----------------------------------------------------------
# step-4: Registe docker service
# ----------------------------------------------------------
cat <<EOF > /etc/systemd/system/docker.service
[Unit]
Description=Docker Application Container Engine
Documentation=https://docs.docker.com
After=network-online.target firewalld.service
Wants=network-online.target

[Service]
Type=notify
# the default is not to use systemd for cgroups because the delegate issues still
# exists and systemd currently does not support the cgroup feature set required
# for containers run by docker
ExecStart=/usr/bin/dockerd --data-root='$data_dir'
ExecReload=/bin/kill -s HUP \$MAINPID
# Having non-zero Limit*s causes performance problems due to accounting overhead
# in the kernel. We recommend using cgroups to do container-local accounting.
LimitNOFILE=infinity
LimitNPROC=infinity
LimitCORE=infinity
# Uncomment TasksMax if your systemd version supports it.
# Only systemd 226 and above support this version.
#TasksMax=infinity
TimeoutStartSec=0
# set delegate yes so that systemd does not reset the cgroups of docker containers
Delegate=yes
# kill only the docker process, not all processes in the cgroup
KillMode=process
# restart the docker process if it exits prematurely
Restart=on-failure
StartLimitBurst=3
StartLimitInterval=60s
 
[Install]
WantedBy=multi-user.target
EOF

chmod u+x /etc/systemd/system/docker.service

echo -e "\033[34m [step-4: Registe docker service] has been registed successfully! \033[0m"

# ----------------------------------------------------------
# step-5: Deploy Docker Service
# ----------------------------------------------------------
systemctl daemon-reload
dead_status_dead_value=`systemctl status docker | grep "dead"`
dead_status_activating_start_value=`systemctl status docker | grep "activating (start)"`
if [[ -n "$dead_status_activating_start_value" ]];then
  systemctl stop docker
  systemctl start docker
  echo -e "\033[34m [step-5: Deploy Docker Service] has been restarted!! \033[0m"
fi
if [[ -n "$dead_status_dead_value" ]];then
  systemctl start docker
  echo -e "\033[34m [step-5: Deploy Docker Service] has been started!! \033[0m"
else
  echo -e "\033[31m [step-5: Deploy Docker Service] has been already started!! \033[0m"
fi
systemctl enable docker
echo -e "\033[34m [step-5: Deploy Docker Service] has been deployed successfully! \033[0m"

