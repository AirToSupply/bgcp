# MinIO



## Usage

​    This project is used to guide the deployment of MinIO. You can run by the following command:

```shell
cd hcone-deploy-minio
bin/bootstrap.sh
```

​     The specific behavior of executing preset processing can be uniformly configured according to the `conf/setup.yaml` configuration file.



## Features

​      The responsibilities of each execution unit under the sbin directory are as follows:

| Script Name      | Description                                                  |
| ---------------- | ------------------------------------------------------------ |
| bin/bootstrap.sh | Deploy to bootstrap for each minio worker                    |
| bin/runc.sh      | It can view or start the cluster on the current server to facilitate centralized management, e.g. start, stop, restart and status. |



## Note

​	① Priority should be given to installing the `yq` parsing library when using it. The installation method is as follows: 

```shell
mkdir -p yq_linux_amd64 && tar -zxvf yq_linux_amd64.tar.gz -C ./yq_linux_amd64
mv ./yq_linux_amd64/yq_linux_amd64 ./yq_linux_amd64/yq && cp ./yq_linux_amd64/yq /usr/bin/ && chmod +x /usr/bin/yq
rm -rf ./yq_linux_amd64
```

​		`yq` package url refer to [yq](https://github.com/mikefarah/yq/releases). 

​    ② In order to execute simultaneously on multiple nodes, it is necessary to install `pssh` on the current server. The installation method is as follows: 

```shell
tar -zxvf pssh-2.3.1.tar.gz
cd pssh-2.3.1
python setup.py install
pssh --version
rm -rf pssh-2.3.1
```

​        pssh package url refer to [pssh](https://pypi.org/project/pssh/#files). 

​     ③ All executable files for this project must be executed under `deploy-user` in `setup.yaml`，and this user own `sudo` permission. 

​     ④ All servers specified in parameter `minio.volumns.*.worker` must be logged in without password in advance.

​     ⑤ If prompted for a password during the installation process, please enter the password of the user corresponding to the parameter `deploy user`.