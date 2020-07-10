#!/bin/bash

set -ex

#get the builder image
BUILDER_IMAGE=$(kubectl get clusterbuilder default -o=jsonpath='{.spec.image}')


#get the build init image
BUILD_INIT_IMAGE=$(kubectl get deployment -n kpack kpack-controller -o=jsonpath='{.spec.template.spec.containers[0].env[?(@.name=="BUILD_INIT_IMAGE")].value}')
BUILD_INIT_IMAGE_BASE=$(echo ${BUILD_INIT_IMAGE} | cut -f1 -d"@")

#get the rebase image
REBASE_IMAGE=$(kubectl get deployment -n kpack kpack-controller -o=jsonpath='{.spec.template.spec.containers[0].env[?(@.name=="REBASE_IMAGE")].value}')
REBASE_IMAGE_BASE=$(echo ${REBASE_IMAGE} | cut -f1 -d"@")

#build the new docker base image with the cert
docker build -t ${REGISTRY_URL}/${BUILDER_IMAGE} --build-arg IMAGE_NAME=${BUILDER_IMAGE} . -f cert-dockerfile
docker push ${REGISTRY_URL}/${BUILDER_IMAGE}

#build the new build init image
docker build -t ${REGISTRY_URL}/${BUILD_INIT_IMAGE_BASE}  --build-arg IMAGE_NAME=${BUILD_INIT_IMAGE} . -f cert-dockerfile
docker push ${REGISTRY_URL}/${BUILD_INIT_IMAGE_BASE}

#build the new REBASE image
docker build -t ${REGISTRY_URL}/${REBASE_IMAGE_BASE}  --build-arg IMAGE_NAME=${REBASE_IMAGE} . -f cert-dockerfile
docker push ${REGISTRY_URL}/${REBASE_IMAGE_BASE}

#create a secret with the ca cert
kubectl -n kpack create secret generic my-ca-cert --from-file ca.crt --dry-run -o yaml | kubectl apply -f -

#patch the kpack controller to use the new image for build init and inject certs with a init container
kubectl patch deployment kpack-controller -n kpack  -p '{"spec":{"template":{"spec":{"initContainers":[{"name":"add-ca-cert","image":"gcr.io/paketo-buildpacks/run:base","command":["sh","-c","cp /var/tmp/* /usr/local/share/ca-certificates && update-ca-certificates && cp /etc/ssl/certs/* /tmp/"],"volumeMounts":[{"mountPath":"/var/tmp","name":"custom-cert"},{"mountPath":"/tmp/","name":"ssl-certs"}]}],"containers":[{"name":"controller","env":[{"name":"BUILD_INIT_IMAGE","value":"'${REGISTRY_URL}/${BUILD_INIT_IMAGE_BASE}'"},{"name":"REBASE_IMAGE","value":"'${REGISTRY_URL}/${REBASE_IMAGE_BASE}'"}],"volumeMounts":[{"mountPath":"/etc/ssl/certs","name":"ssl-certs"}]}],"volumes":[{"name":"custom-cert","secret":{"secretName":"my-ca-cert"}},{"name":"ssl-certs","emptyDir":{}}]}}}}'

#patch the cluster builder to use the new builder image with certs
kubectl patch clusterbuilder default --type='json' -p='[{"op": "replace", "path": "/spec/image", "value":"'${REGISTRY_URL}/${BUILDER_IMAGE}'"}]'


