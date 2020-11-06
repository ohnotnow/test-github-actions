#!/bin/bash

set -e

eval $(ssh-agent -s)
mkdir ~/.ssh
chmod 700 ~/.ssh
ssh-keyscan ${DEPLOY_SERVER} > ~/.ssh/known_hosts
chmod 644 ~/.ssh/known_hosts
echo "${DEPLOY_SSH_KEY}" | tr -d '\r' | ssh-add - > /dev/null
export NOW=`date +%Y-%m-%d-%H-%M-%S`
export DOTENV_NAME="${REPO_NAME}-prod-dotenv-${NOW}"
echo "${DEPLOY_DOTENV}" | docker secret create ${DOTENV_NAME} -
echo "Deploying stack ${STACK_NAME} image ${IMAGE_NAME} with secret ${DOTENV_NAME}"
docker stack deploy -c prod-stack.yml --prune ${STACK_NAME}
docker/docker-stack-wait.sh ${STACK_NAME}
if [ ! -z "${SLACK_WEBHOOK}" ]; then curl -X POST -H 'Content-type:application/json' --data "{\"username\":\"gitlab\", \"text\":\"Deployed Production ${STACK_NAME}\", \"channel\":\"#deployments\", \"icon_emoji\":\":ghost:\"}" ${SLACK_WEBHOOK}; fi
