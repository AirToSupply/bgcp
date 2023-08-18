# Docker



## Usage

​    This project is used to guide the deployment of Docker. You can run by the following command:

```shell
cd hcone-deploy-docker
bin/bootstrap.sh
```

​     The specific behavior of executing preset processing can be uniformly configured according to the `conf/setup.yaml` configuration file.



## Note

​	① Priority should be given to installing the `yq` parsing library when using it. The installation method is as follows: 

```shell
mkdir -p yq_linux_amd64 && tar -zxvf yq_linux_amd64.tar.gz -C ./yq_linux_amd64
mv ./yq_linux_amd64/yq_linux_amd64 ./yq_linux_amd64/yq && cp ./yq_linux_amd64/yq /usr/bin/ && chmod +x /usr/bin/yq
rm -rf ./yq_linux_amd64
```

​		`yq` package url refer to [yq](https://github.com/mikefarah/yq/releases). 

​     ③ All operations must be performed by the `root` user.

​     ④ The bootstrapper must be installed on that server where `Docker` needs to be deployed.

​     ⑤ If it is crashed during the execution process, type CTRL+D to exit the installation and execute again!