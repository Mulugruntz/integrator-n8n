FROM n8nio/n8n:0.172.0@sha256:0ad8ddb2055744b7f4c4869faeb82d425e80843e0d8b5aa6457ffaeb58703b5d

#####
# Future improvements:
# SSH key should not appear in the image
# https://stackoverflow.com/a/48565025/8933502
#####

ARG N8N_CONFIG_FILES
ARG N8N_USER_FOLDER=/home/node
ARG GIT_BACKUP_REPO=git@github.com:Mulugruntz/integrator-n8n-backups.git

ENV N8N_CONFIG_FILES=${N8N_CONFIG_FILES:-$N8N_USER_FOLDER/.n8n/n8n_config.json}
ENV N8N_USER_FOLDER=${N8N_USER_FOLDER:-$N8N_USER_FOLDER/.n8n/shared}

ENV ROOT_DIR_N8N=$N8N_USER_FOLDER/.n8n
ENV SHARED_DIR_N8N=$ROOT_DIR_N8N/shared
ENV GIT_BACKUP_DIR=$ROOT_DIR_N8N/integrator-n8n-backups

RUN mkdir -p $SHARED_DIR_N8N

#VOLUME $SHARED_DIR_N8N

WORKDIR $ROOT_DIR_N8N

RUN npm install -g npm@8.7.0

RUN apk add --update --no-cache openssh openssl tar openrc

# Setting up SSH keys
COPY ssh/ssh.tar.gz.enc $ROOT_DIR_N8N/ssh.tar.gz.enc
# Encrypted payload contains './ssh/id_rsa' and './ssh/id_rsa.pub'.
COPY decrypt_key.secret .
RUN openssl enc -aes-256-cbc -iter 10000 -pass "pass:`cat decrypt_key.secret`" -d -in ssh.tar.gz.enc | tar xz -C $ROOT_DIR_N8N
RUN rm decrypt_key.secret
COPY ssh/known_hosts $ROOT_DIR_N8N/ssh/
RUN mkdir -p $N8N_USER_FOLDER/.ssh
RUN mv $ROOT_DIR_N8N/ssh/* $N8N_USER_FOLDER/.ssh/

RUN echo "PermitRootLogin yes" >> /etc/ssh/sshd_config && \
    eval `ssh-agent` && \
    ssh-add $N8N_USER_FOLDER/.ssh/id_rsa

COPY ./n8n_config.json $ROOT_DIR_N8N/n8n_config.json

RUN chown node -R $N8N_USER_FOLDER

# Load backups and import them.
USER node
RUN git clone $GIT_BACKUP_REPO $GIT_BACKUP_DIR
RUN echo $SHARED_DIR_N8N
RUN #ls -la $SHARED_DIR_N8N/*
RUN npx n8n import:workflow --separate --input=$GIT_BACKUP_DIR/workflows
RUN npx n8n import:credentials --separate --input=$GIT_BACKUP_DIR/credentials

USER root
