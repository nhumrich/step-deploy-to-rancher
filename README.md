[![wercker status](https://app.wercker.com/status/ff788e3e0eb4b14e7c3363fb0f64789e/m/master "wercker status")](https://app.wercker.com/project/bykey/ff788e3e0eb4b14e7c3363fb0f64789e)[![License](http://img.shields.io/:license-mit-blue.svg)](http://doge.mit-license.org)
## step-deploy-to-rancher

Does a rolling update to rancher

You will need to create an API access token and secret for rancher

The rancher URL needs to be your full url including project id. You will get the url on your api key page. Make sure you are using the environment you want to use. Do not include http/s in the url. There is an option for https.

If I wanted to deploy billybob/awesome:3.0 I would use `docker_org: billybob`, `docker_image: awesome`, and `tag: 3.0`.

If your tag is unique each deploy, you should set `use_tag` to true. But it you always deploy the same tag (i.e. latest) you should set `use_tag` to false. `use_tag` just sets the rancher service name to include the tag, for example awesome-3.0 -> awesome-3.1. But if your tag is not unique, then a random number will be generated for you. Rancher enforces that the service has to have a new unique name on every deploy.


Example:

    deploy:
      steps:
        - nhumrich/deploy-to-rancher:
            access_key: $RANCHER_ACCESS_KEY
            secret_key: $RANCHER_SECRET_KEY
            rancher_url: $RANCHER_URL
            https: false # should https protocol be used?
            tag: latest  # docker tag for the `image:` section in docker-compose
            stack_name: my-awesome-stack  # Rancher stack name
            service_name: awesome  # Name of service in rancher
            docker_org: billybob  # name of organaztion
            docker_image: awesome
            use_tag: false
            inplace: false

Inplace upgrades added in 8.0. Just add the `inplace: true` section to the yaml
