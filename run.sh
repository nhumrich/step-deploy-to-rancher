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
function get_env_id { curl -s "$DTR_PROTO://$WERCKER_DEPLOY_TO_RANCHER_ACCESS_KEY:$WERCKER_DEPLOY_TO_RANCHER_SECRET_KEY@$WERCKER_DEPLOY_TO_RANCHER_RANCHER_URL/environments?name=$WERCKER_DEPLOY_TO_RANCHER_STACK_NAME" | "$WERCKER_STEP_ROOT/jq" '.data[0].id' | sed s/\"//g; }

DTR_ENV_ID=$(get_env_id)
echo "$DTR_ENV_ID"

# get zip
cd "$WERCKER_DEPLOY_TO_RANCHER_STACK_NAME"
pwd
wget -O file.zip "$DTR_PROTO://$WERCKER_DEPLOY_TO_RANCHER_ACCESS_KEY:$WERCKER_DEPLOY_TO_RANCHER_SECRET_KEY@$WERCKER_DEPLOY_TO_RANCHER_RANCHER_URL/environments/$DTR_ENV_ID/composeconfig"

# unzip
unzip file.zip
pwd
ls -la
# get old suffix
echo "$WERCKER_DEPLOY_TO_RANCHER_SERVICE_NAME"

echo "What is going on here!!!!"
cat docker-compose.yml | grep "$WERCKER_DEPLOY_TO_RANCHER_SERVICE_NAME"
echo sed -n "s/^\($WERCKER_DEPLOY_TO_RANCHER_SERVICE_NAME[^:]*\):$/\1/p"
sed -n '"s/^\($WERCKER_DEPLOY_TO_RANCHER_SERVICE_NAME[^:]*\):$/\1/p"' docker-compose.yml

echo "Blarg!"
function get_old_service_name { sed -n "s/^\($WERCKER_DEPLOY_TO_RANCHER_SERVICE_NAME[^:]*\):$/\1/p" docker-compose.yml; }

DTR_OLD_SERVICE_NAME=$(get_old_service_name)
echo "$DTR_OLD_SERVICE_NAME"

# update docker-compose.yml to include new service name
sed -i "s/^$DTR_OLD_SERVICE_NAME:/$DTR_OLD_SERVICE_NAME:\r\n$WERCKER_DEPLOY_TO_RANCHER_SERVICE_NAME-$DTR_SUFFIX:/g" docker-compose.yml
sed -i "s/^$DTR_OLD_SERVICE_NAME:/$DTR_OLD_SERVICE_NAME:\r\n$WERCKER_DEPLOY_TO_RANCHER_SERVICE_NAME-$DTR_SUFFIX:/g" rancher-compose.yml
sed -i "s/^\(\s *image: $WERCKER_DEPLOY_TO_RANCHER_DOCKER_ORG\/$WERCKER_DEPLOY_TO_RANCHER_DOCKER_IMAGE\).*$/\1:$WERCKER_DEPLOY_TO_RANCHER_TAG/g" docker-compose.yml

# For initial testing
cat docker-compose.yml
cat rancher-compose.yml

#do the deploy!

echo "$WERCKER_STEP_ROOT/rancher-compose" upgrade "$DTR_OLD_SERVICE_NAME" "$WERCKER_DEPLOY_TO_RANCHER_SERVICE_NAME-$DTR_SUFFIX" --pull --update-links -c --interval 30000 --url "$DTR_PROTO://$WERCKER_DEPLOY_TO_RANCHER_RANCHER_URL" --access-key "$WERCKER_DEPLOY_TO_RANCHER_ACCESS_KEY" --secret-key "$WERCKER_DEPLOY_TO_RANCHER_SECRET_KEY" --project-name "$WERCKER_DEPLOY_TO_RANCHER_STACK_NAME"

"$WERCKER_STEP_ROOT/rancher-compose" upgrade "$DTR_OLD_SERVICE_NAME" "$WERCKER_DEPLOY_TO_RANCHER_SERVICE_NAME-$DTR_SUFFIX" --pull --update-links -c --interval 30000 --url "$DTR_PROTO://$WERCKER_DEPLOY_TO_RANCHER_RANCHER_URL" --access-key "$WERCKER_DEPLOY_TO_RANCHER_ACCESS_KEY" --secret-key "$WERCKER_DEPLOY_TO_RANCHER_SECRET_KEY" --project-name "$WERCKER_DEPLOY_TO_RANCHER_STACK_NAME"
