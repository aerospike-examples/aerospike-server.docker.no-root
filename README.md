# Aerospike Container - Root Free Build

Docker files and images for standard builds of Aerospike have been available for some time

* https://github.com/aerospike/aerospike-server.docker
* https://github.com/aerospike/aerospike-server-enterprise.docker
* [Aerospike@DockerHub](https://registry.hub.docker.com/_/aerospike)

These all build and run Aerospike using a standard installation. The standard installation allows Aerospike to configured to run under any user id, but the service needs to be started using the root user. See [configuration](https://www.aerospike.com/docs/operations/configure/non_root/) for details.

There are however significant concerns around running containers under the root id, many of which are detailed [here](https://docs.docker.com/engine/security/). The OpenShift platform [prevents](https://www.openshift.com/blog/managing-sccs-in-openshift) this by default

With the above in mind, a container which runs under a non-privileged id is desirable. This repository provides build assets to support this.

## Community / Enterprise

Two editions of Aerospike are available - Community and Enterprise. The former is open source and can be [downloaded](https://www.aerospike.com/lp/aerospike-community-edition/) without charge. It has some scale limitations. The latter contains features not available in Community, removes the scale limits and is supported 24 x 7 by our Global Support team. See our [product matrix](https://www.aerospike.com/products/product-matrix/) for details. Enterprise Aerospike requires a valid feature key before it will run.

As such, two different build mechanisms here, one for Community, one for Enterprise.

### Community Aerospike build

To build a community container, run the command below from the directory containing your ```Dockerfile```. The 't' flag allows you to name your image.

```bash
docker build -t $COMMUNITY_IMAGE_NAME .
```

To run your image, giving your container a specific name

```bash
docker run -d --name $CONTAINER_NAME $COMMUNITY_IMAGE_NAME
```

You can directly access your running container using aql

```bash
docker exec -it $CONTAINER_NAME usr/bin/aql
```

Stop and remove your container 

```bash
docker container stop $CONTAINER_NAME
docker container rm $CONTAINER_NAME
```

### Enterprise Aerospike build

As noted above, Enterprise Aerospike requires a feature key. It is also build using a different binary. To build a non-root Enterprise Aerospike container the IS_ENTERPRISE flag needs to be set. By default the build process will expect the license key file to be named ```features.conf``` and placed in the same directory as the ```Dockerfile```. The container is then built as follows

```bash
docker build -t $ENTERPRISE_IMAGE_NAME --build-arg IS_ENTERPRISE=1 .
```

To run your image

```bash
docker run -d --name $CONTAINER_NAME $ENTERPRISE_IMAGE_NAME
```

The aql and container removal commands are the same as before.

License key location can be provided to the build process using the ```FEATURE_KEY_FILE``` argument, should the default requirement not be satisfied. Note this path must be relative to the build directory and cannot traverse upwards using the ```..``` operator.

```bash
docker build -t $ENTERPRISE_IMAGE_NAME --build-arg IS_ENTERPRISE=1 --build-arg FEATURE_KEY_FILE=mylicense.conf .
```

## Registering your image

You can register your image in a container registry. This decouples image build from image deployment.

By default Docker will use the [DockerHub](https://hub.docker.com/) registry. Assuming you have set up an account and [logged in](https://docs.docker.com/engine/reference/commandline/login/) you can push your image. Let's say I have been naming my image aerospike:non-root-community. ktune is my account name on Docker Hub, so first I tag it with my account name so I can then push it.

```bash
docker tag aerospike:non-root-community ktune/aerospike:non-root-community
docker push ktune/aerospike:non-root-community 
```

This will push it to the ```aerospike``` repository within my account. Obviously, use your own account name!

***Be very careful if/when pushing public images***. Firstly make sure you haven't inadverently included content you don't wish to make public. Secondly, you ***should not*** make Enterprise images public as they ***will contain your license file***. More on the ```docker push``` command [here](https://docs.docker.com/engine/reference/commandline/push/) - particularly useful if wanting to push to a private registry.

## Aerospike Version

By default the container will build using the latest version of Aerospike in both Community and Aerospike modes. A specific Aerospike version can be selected using the AEROSPIKE_VERSION build argument e.g.

```bash
docker build -t $COMMUNITY_IMAGE_NAME --build-arg AEROSPIKE_VERSION=5.3.0.3 .
```

You can find out what version of Aerospike a container is running using

```bash
docker exec -it $CONTAINER_NAME usr/bin/asinfo -v 'build' 
```

## Deploying vs Openshift

There are a number of ways of setting up an Openshift cluster - [this](https://www.openshift.com/try) is a good page to get you started.

Once you have your cluster set up, you can use the ```oc``` tool to administer it. Here's a useful [getting started](https://docs.openshift.com/container-platform/4.2/cli_reference/openshift_cli/getting-started-cli.html) to help you with installation of oc and basic orientation.

I used IBM cloud FWIW. You can set up an Openshift cluster very easily - they then give you a command that looks like

```bash
oc login --token=XXXXXXXXXX --server=https://XXXXX.containers.cloud.ibm.com:PORT_NO
```

From there, you can reference an image in a container registry and deploy that. e.g.

```bash
oc new-app ktune/aerospike:non-root --name aerospike
```

By way of demonstrating it's all working, we can get the name of the container

```bash
$ oc get pods
NAME                 READY   STATUS      RESTARTS   AGE
aerospike-1-6x7b2    1/1     Running     0          73s
aerospike-1-deploy   0/1     Completed   0          77s
```

And log in

```
$ oc exec -it aerospike-1-6x7b2 usr/bin/aql
...
Aerospike Query Client
Version 4.0.4
C Client Version 4.6.17
Copyright 2012-2020 Aerospike. All rights reserved.
aql> 

```

## Testing

```test-non-root-container-build.sh``` within the test directory can be used to test the success of the container build. The contents should be self evident.