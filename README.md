# nanocyte-flow-deploy-service
Flow Deploy Service

[![Build Status](https://travis-ci.org/octoblu/nanocyte-flow-deploy-service.svg?branch=master)](https://travis-ci.org/octoblu/nanocyte-flow-deploy-service)
[![Code Climate](https://codeclimate.com/github/octoblu/nanocyte-flow-deploy-service/badges/gpa.svg)](https://codeclimate.com/github/octoblu/nanocyte-flow-deploy-service)
[![Test Coverage](https://codeclimate.com/github/octoblu/nanocyte-flow-deploy-service/badges/coverage.svg)](https://codeclimate.com/github/octoblu/nanocyte-flow-deploy-service)
[![npm version](https://badge.fury.io/js/nanocyte-flow-deploy-service.svg)](http://badge.fury.io/js/nanocyte-flow-deploy-service)
[![Gitter](https://badges.gitter.im/octoblu/help.svg)](https://gitter.im/octoblu/help)

## How to run
> Also involves manual changes and running nanocyte-engine-simple

1. open terminal and `cd` to `nanocyte-engine-simple` dir and run `env PORT="5050" npm start`
1. open a new tab and `cd` to [nanocyte-flow-deploy-service](https://github.com/octoblu/nanocyte-flow-deploy-service) dir and run `env PORT="5051" env OCTOBLU_URL="https://app.octoblu.com" npm start`
1. open a new tab and `cd` to [nanocyte-flow-deploy-service](https://github.com/octoblu/nanocyte-flow-deploy-service) dir and run `./deploy-flow.sh`
1. After running `deply-flow.sh`, copy the instance UUID from the response (you should see: /flows/{flowUUID}/instances/{instanceUUID})
1. Paste (replace) the instance UUID into nanocyte engine's click-trigger script - `INSTANCE_UUID`
1. `./click-trigger.sh`
1. Log into [Octoblu](https://app.octoblu.com).
