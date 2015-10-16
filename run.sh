#!/bin/bash

# Have access to the following variables
# $WERCKER_DEPLOY_TO_RANCHER_ACCESS_KEY
# $WERCKER_DEPLOY_TO_RANCHER_SECRET_KEY
# $WERCKER_DEPLOY_TO_RANCHER_RANCHER_URL
# $WERCKER_DEPLOY_TO_RANCHER_HTTPS
# $WERCKER_DEPLOY_TO_RANCHER_TAG
# $WERCKER_DEPLOY_TO_RANCHER_STACK_NAME
# $WERCKER_DEPLOY_TO_RANCHER_SERVICE_NAME
# $WERCKER_DEPLOY_TO_RANCHER_DOCKER_ORG
# $WERCKER_DEPLOY_TO_RANCHER_DOCKER_IMAGE
# $WERCKER_DEPLOY_TO_RANCHER_USE_TAG


#export RANCHER_SECRET_KEY=
#export RANCHER_ACCESS_KEY=
#export RANCHER_URL=
#export HTTPS=false
#export TAG=v0.2.1
#export STACK_NAME=workflow-stage
#export SERVICE_NAME=workflow
#export DOCKER_ORG=canopytax
#export DOCKER_IMAGE=workflow-service
#export USE_TAG=false

if [ "$WERCKER_DEPLOY_TO_RANCHER_USE_TAG" == true ]; then
    export DTR_SUFFIX=$TAG;
else
    export DTR_SUFFIX=$RANDOM;
fi

if [ "$WERCKER_DEPLOY_TO_RANCHER_HTTPS" == true ]; then
    export DTR_PROTO=https;
else
    export DTR_PROTO=http;
fi

mkdir "$WERCKER_DEPLOY_TO_RANCHER_STACK_NAME"
## Need to get environment id
function get_env_id { curl -s "$DTR_PROTO://$WERCKER_DEPLOY_TO_RANCHER_ACCESS_KEY:$WERCKER_DEPLOY_TO_RANCHER_SECRET_KEY@$WERCKER_DEPLOY_TO_RANCHER_RANCHER_URL/environments?name=$WERCKER_DEPLOY_TO_RANCHER_STACK_NAME" | "$WERCKER_STEP_ROOT/jq" '.data[0].id'; }

DTR_ENV_ID=$(get_env_id)

# get zip
cd "$WERCKER_DEPLOY_TO_RANCHER_STACK_NAME"
wget -O file.zip "$DTR_PROTO://$WERCKER_DEPLOY_TO_RANCHER_ACCESS_KEY:$WERCKER_DEPLOY_TO_RANCHER_SECRET_KEY@$WERCKER_DEPLOY_TO_RANCHER_RANCHER_URL/environments/$DTR_ENV_ID/composeconfig"

# unzip
unzip file.zip

# get old suffix
DTR_OLD_SERVICE_NAME="$(sed -n "s/^\($WERCKER_DEPLOY_TO_RANCHER_SERVICE_NAME[^:]*\):$/\1/p" docker-compose.yml)"

# update docker-compose.yml to include new service name
sed -i "s/^$DTR_OLD_SERVICE_NAME:/$DTR_OLD_SERVICE_NAME:\r\n$WERCKER_DEPLOY_TO_RANCHER_SERVICE_NAME-$DTR_SUFFIX:/g" docker-compose.yml
sed -i "s/^$DTR_OLD_SERVICE_NAME:/$DTR_OLD_SERVICE_NAME:\r\n$WERCKER_DEPLOY_TO_RANCHER_SERVICE_NAME-$DTR_SUFFIX:/g" rancher-compose.yml
sed -i "s/^\(\s *image: $WERCKER_DEPLOY_TO_RANCHER_DOCKER_ORG\/$WERCKER_DEPLOY_TO_RANCHER_DOCKER_IMAGE\).*$/\1:$WERCKER_DEPLOY_TO_RANCHER_TAG/g" docker-compose.yml

# For initial testing
cat docker-compose.yml
cat rancher-compose.yml

#do the deploy!
"$WERCKER_STOP_ROOT/rancher-compose" upgrade "$DTR_OLD_SERVICE_NAME" "$WERCKER_DEPLOY_TO_RANCHER_SERVICE_NAME-$DTR_SUFFIX" --pull --update-links -c --interval 30000
