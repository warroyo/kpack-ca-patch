FROM gcr.io/kaniko-project/executor:debug


FROM alpine

# need to have `nohup`
RUN apk add --update \
    curl \
    coreutils \
    && rm -rf /var/cache/apk/* && \
    curl -LO https://storage.googleapis.com/kubernetes-release/release/`curl -s https://storage.googleapis.com/kubernetes-release/release/stable.txt`/bin/linux/amd64/kubectl && \
    chmod +x ./kubectl && \
    mv ./kubectl /usr/local/bin/kubectl

COPY --from=0 /kaniko/executor /kaniko/executor
COPY --from=0 /kaniko/ssl/certs/ /kaniko/ssl/certs/

ENV PATH /bin:/usr/bin:/usr/local/bin
ENV SSL_CERT_DIR=/kaniko/ssl/certs

WORKDIR /workspace

COPY cert-dockerfile /workspace/cert-dockerfile
COPY patch.sh /workspace/patch.sh