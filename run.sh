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
# $WERCKER_DEPLOY_TO_RANCHER_INPLACE

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

#mkdir "$WERCKER_DEPLOY_TO_RANCHER_STACK_NAME"
## Need to get environment id
function get_env_id { curl -s "$DTR_PROTO://$WERCKER_DEPLOY_TO_RANCHER_ACCESS_KEY:$WERCKER_DEPLOY_TO_RANCHER_SECRET_KEY@$WERCKER_DEPLOY_TO_RANCHER_RANCHER_URL/environments?name=$WERCKER_DEPLOY_TO_RANCHER_STACK_NAME" | "$WERCKER_STEP_ROOT/jq" '.data[0].id' | sed s/\"//g; }

DTR_ENV_ID=$(get_env_id)
#echo "$DTR_ENV_ID"

# get zip
#cd "$WERCKER_DEPLOY_TO_RANCHER_STACK_NAME"
wget -O file.zip "$DTR_PROTO://$WERCKER_DEPLOY_TO_RANCHER_ACCESS_KEY:$WERCKER_DEPLOY_TO_RANCHER_SECRET_KEY@$WERCKER_DEPLOY_TO_RANCHER_RANCHER_URL/environments/$DTR_ENV_ID/composeconfig"

# unzip
unzip -o file.zip

if [ "$WERCKER_DEPLOY_TO_RANCHER_INPLACE" != true ]; then
  # get old suffix
  #echo "$WERCKER_DEPLOY_TO_RANCHER_SERVICE_NAME"
  function get_old_service_name { sed -n "s/^\($WERCKER_DEPLOY_TO_RANCHER_SERVICE_NAME[^:]*\):[\r\n]$/\1/p" docker-compose.yml; }

  DTR_OLD_SERVICE_NAME=$(get_old_service_name)
  #echo "$DTR_OLD_SERVICE_NAME"
fi


if [ "$WERCKER_DEPLOY_TO_RANCHER_INPLACE" != true ]; then
  # update docker-compose.yml to include new service name
  sed -i "s/^$DTR_OLD_SERVICE_NAME:/$DTR_OLD_SERVICE_NAME:\r\n$WERCKER_DEPLOY_TO_RANCHER_SERVICE_NAME-$DTR_SUFFIX:/g" docker-compose.yml
  sed -i "s/^$DTR_OLD_SERVICE_NAME:/$DTR_OLD_SERVICE_NAME:\r\n$WERCKER_DEPLOY_TO_RANCHER_SERVICE_NAME-$DTR_SUFFIX:/g" rancher-compose.yml
fi

# update image in docker-compose.yml
sed -i "s/^\(\s *image: $WERCKER_DEPLOY_TO_RANCHER_DOCKER_ORG\/$WERCKER_DEPLOY_TO_RANCHER_DOCKER_IMAGE\).*$/\1:$WERCKER_DEPLOY_TO_RANCHER_TAG/g" docker-compose.yml


#do the deploy!
if [ "$WERCKER_DEPLOY_TO_RANCHER_INPLACE" == true ]; then
  # Echo the command cause it looks nice!
  echo "rancher-compose" --url "$DTR_PROTO://$WERCKER_DEPLOY_TO_RANCHER_RANCHER_URL" --access-key xxxx --secret-key xxxx --project-name "$WERCKER_DEPLOY_TO_RANCHER_STACK_NAME" up --upgrade "$WERCKER_DEPLOY_TO_RANCHER_SERVICE_NAME" --pull --interval 30000 --batch-size 1 -d
  "$WERCKER_STEP_ROOT/rancher-compose" --url "$DTR_PROTO://$WERCKER_DEPLOY_TO_RANCHER_RANCHER_URL" --access-key "$WERCKER_DEPLOY_TO_RANCHER_ACCESS_KEY" --secret-key "$WERCKER_DEPLOY_TO_RANCHER_SECRET_KEY" --project-name "$WERCKER_DEPLOY_TO_RANCHER_STACK_NAME" up --upgrade "$WERCKER_DEPLOY_TO_RANCHER_SERVICE_NAME" --pull --interval 30000 --batch-size 1 -d
  "$WERCKER_STEP_ROOT/rancher-compose" --url "$DTR_PROTO://$WERCKER_DEPLOY_TO_RANCHER_RANCHER_URL" --access-key "$WERCKER_DEPLOY_TO_RANCHER_ACCESS_KEY" --secret-key "$WERCKER_DEPLOY_TO_RANCHER_SECRET_KEY" --project-name "$WERCKER_DEPLOY_TO_RANCHER_STACK_NAME" up --upgrade "$WERCKER_DEPLOY_TO_RANCHER_SERVICE_NAME" --confirm-upgrade -d

else
  # Echo the command cause it looks nice!
  echo "rancher-compose" --url "$DTR_PROTO://$WERCKER_DEPLOY_TO_RANCHER_RANCHER_URL" --access-key xxxx --secret-key xxxx --project-name "$WERCKER_DEPLOY_TO_RANCHER_STACK_NAME" upgrade "$DTR_OLD_SERVICE_NAME" "$WERCKER_DEPLOY_TO_RANCHER_SERVICE_NAME-$DTR_SUFFIX" --pull --update-links -c --interval 30000

  "$WERCKER_STEP_ROOT/rancher-compose" --url "$DTR_PROTO://$WERCKER_DEPLOY_TO_RANCHER_RANCHER_URL" --access-key "$WERCKER_DEPLOY_TO_RANCHER_ACCESS_KEY" --secret-key "$WERCKER_DEPLOY_TO_RANCHER_SECRET_KEY" --project-name "$WERCKER_DEPLOY_TO_RANCHER_STACK_NAME" upgrade "$DTR_OLD_SERVICE_NAME" "$WERCKER_DEPLOY_TO_RANCHER_SERVICE_NAME-$DTR_SUFFIX" --pull --update-links -c --interval 30000 --batch-size 1
fi
