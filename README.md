# Kpack CA Patch

this script will patch a default install of kpack to add custom CA certificates to all of the right places so that private registries can be accessed as well as internal maven repos.

## Pre-reqs

* Docker installed - if you are on windows you will need to run this in WSL since it will need to be able to build linux container images
* Kubectl -  this is needed to access the cluster
* bash
* kpack installed via the instructions [here](https://github.com/pivotal/kpack/blob/master/docs/install.md) 

## What it does

this script will do the following

1. capture the current builder image being used by the default ClusterBuilder
2. capture the build init and rebase images used by the kpack controller
3. rebuild the builder, init, and rebase images to contain the `cacerts` you provide and retag and push them into your registry
4. patch the kpack controller deployment to use the new images as well as setup an init container to mount the certs into the kpack controller
5. patch the default `ClusterBuilder` to use the new image with the certs

## Usage

1. update the `vars.env` file with the registry you will be using. if using harbor be sure to include the path to your project like so `<regsitry.com>/<project>`
2. update the `ca.crt` file with one or more CA certs
3. login to your k8s cluster
4. login to your docker registry of choice

5. source the vars and execute the script 

```bash
source vars.env
./patch.sh
```
