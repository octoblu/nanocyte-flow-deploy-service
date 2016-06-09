_                      = require 'lodash'
async                  = require 'async'
debug                  = require('debug')('nanocyte-flow-deploy-service:instances-controller')
redis                  = require 'ioredis'
MeshbluConfig          = require 'meshblu-config'
MeshbluHttp            = require 'meshblu-http'
ConfigurationGenerator = require 'nanocyte-configuration-generator'
ConfigurationSaver     = require 'nanocyte-configuration-saver-redis'
SimpleBenchmark        = require 'simple-benchmark'
client                 = redis.createClient process.env.REDIS_PORT, process.env.REDIS_HOST, auth_pass: process.env.REDIS_PASSWORD, dropBufferSupport: true

class InstancesController
  constructor: (dependencies={}) ->
    {@NanocyteDeployer, @UUID} = dependencies
    @NanocyteDeployer ?= require 'nanocyte-deployer'
    @UUID ?= require 'node-uuid'
    @meshbluConfig = new MeshbluConfig

  create: (req, res) =>
    benchmark = new SimpleBenchmark label: "create-#{req.params.flowId}"
    @meshbluHttp = @_createMeshbluHttp req.meshbluAuth
    options =
      tag: 'nanocyte-flow-deploy-service'
    @meshbluHttp.generateAndStoreTokenWithOptions req.params.flowId, options, (error, result) =>
      return res.status(403).send(error.message) if error?
      options = @_buildOptions req, result
      nanocyteDeployer = @_createNanocyteDeployer options

      async.series [
        async.apply nanocyteDeployer.sendStopFlowMessage
        async.apply nanocyteDeployer.deploy
        async.apply nanocyteDeployer.startFlow
      ], (error) =>
        debug benchmark.toString()
        return res.status(422).send(error.message) if error?
        res.status(201).location("/flows/#{options.flowUuid}/instances/#{options.instanceId}").end()

  destroy: (req, res) =>
    benchmark = new SimpleBenchmark label: "create-#{req.params.flowId}"
    @meshbluHttp = @_createMeshbluHttp req.meshbluAuth
    options =
      tag: 'nanocyte-flow-deploy-service'
    @meshbluHttp.generateAndStoreTokenWithOptions req.params.flowId, options, (error, result) =>
      return res.status(403).send(error.message) if error?
      options = @_buildOptions req, result
      nanocyteDeployer = @_createNanocyteDeployer options
      async.series [
        async.apply nanocyteDeployer.stopFlow
        async.apply nanocyteDeployer.destroy
      ], (error) =>
        debug benchmark.toString()
        return res.status(422).send(error.message) if error?
        res.status(201).end()

  _createNanocyteDeployer: (options) =>
    {userUuid, userToken} = options
    meshbluConfig = new MeshbluConfig
      uuid: userUuid
      token: userToken
      server_env_name: 'MESHBLU_MESSAGES_SERVER'

    dependencies =
      configurationGenerator: new ConfigurationGenerator
        registryUrl:     process.env.NODE_REGISTRY_URL
        meshbluJSON:     meshbluConfig.toJSON()
        accessKeyId:     process.env.AWS_ACCESS_KEY_ID
        secretAccessKey: process.env.AWS_SECRET_ACCESS_KEY
      configurationSaver: new ConfigurationSaver client

    new @NanocyteDeployer options, dependencies

  _createMeshbluHttp: (options) =>
    meshbluJSON = _.assign {}, @meshbluConfig.toJSON(), options
    new MeshbluHttp meshbluJSON

  _buildOptions: (req, result) =>
    instanceId = @UUID.v4()
    return {
      flowUuid: req.params.flowId
      instanceId: instanceId
      flowToken: result?.token
      userUuid: req.meshbluAuth.uuid
      userToken: req.meshbluAuth.token
      deploymentUuid: req.get('deploymentUuid') ? 'nanocyte-flow-deploy-default'
      octobluUrl: process.env.OCTOBLU_URL
      forwardUrl: "#{process.env.NANOCYTE_ENGINE_URL}/flows/#{req.params.flowId}/instances/#{instanceId}/messages"
      flowLoggerUuid:  process.env.FLOW_LOGGER_UUID
    }

module.exports = InstancesController
