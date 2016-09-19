# nanocyte-flow-deploy-service
Flow Deploy Service

[![Build Status](https://travis-ci.org/octoblu/nanocyte-flow-deploy-service.svg?branch=master)](https://travis-ci.org/octoblu/nanocyte-flow-deploy-service)
[![Test Coverage](https://codecov.io/gh/octoblu/nanocyte-flow-deploy-service/branch/master/graph/badge.svg)](https://codecov.io/gh/octoblu/nanocyte-flow-deploy-service)
[![Dependency status](http://img.shields.io/david/octoblu/nanocyte-flow-deploy-service.svg?style=flat)](https://david-dm.org/octoblu/nanocyte-flow-deploy-service)
[![devDependency Status](http://img.shields.io/david/dev/octoblu/nanocyte-flow-deploy-service.svg?style=flat)](https://david-dm.org/octoblu/nanocyte-flow-deploy-service#info=devDependencies)
[![Slack Status](http://community-slack.octoblu.com/badge.svg)](http://community-slack.octoblu.com)

[![NPM](https://nodei.co/npm/nanocyte-flow-deploy-service.svg?style=flat)](https://npmjs.org/package/nanocyte-flow-deploy-service)


## How to run
> Also involves manual changes and running nanocyte-engine-simple

1. `cd` to `nanocyte-engine-simple` dir and run `env PORT="5050" npm start`
1. Open a new terminal tab/window and `cd` to [nanocyte-flow-deploy-service](https://github.com/octoblu/nanocyte-flow-deploy-service) dir and run `env PORT="5051" env OCTOBLU_URL="https://app.octoblu.com" npm start`
1. Update `deploy-flow.sh` w/ your credentials from [Octoblu](https://app.octoblu.com)
1. Open a new terminal tab/window and `cd` to [nanocyte-flow-deploy-service](https://github.com/octoblu/nanocyte-flow-deploy-service) dir and run `./deploy-flow.sh`
1. After running `deply-flow.sh`, copy the _Instance UUID_ from the response (_you should see: /flows/{flowUUID}/instances/{instanceUUID}_)
1. Paste (replace) the instance UUID into nanocyte engine's `click-trigger.sh` - `INSTANCE_UUID`
1. `./click-trigger.sh`
1. Verify in the designer that the flow was deployed
