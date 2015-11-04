_ = require 'lodash'
redis = require 'redis'
MeshbluConfig = require 'meshblu-config'
MeshbluHttp = require 'meshblu-http'
ConfigurationGenerator = require 'nanocyte-configuration-generator'
ConfigurationSaver = require 'nanocyte-configuration-saver-redis'
client = redis.createClient process.env.REDIS_PORT, process.env.REDIS_HOST, auth_pass: process.env.REDIS_PASSWORD

class InstancesController
  constructor: (dependencies={}) ->
    {@NanocyteDeployer, @UUID} = dependencies
    @NanocyteDeployer ?= require 'nanocyte-deployer'
    @UUID ?= require 'node-uuid'
    @meshbluConfig = new MeshbluConfig

  create: (request, response) =>
    @meshbluHttp = @_createMeshbluHttp request.meshbluAuth
    @meshbluHttp.generateAndStoreToken request.params.flowId, (error, result) =>
      options = @_buildOptions request, result
      @nanocyteDeployer = @_createNanocyteDeployer options
      @nanocyteDeployer.deploy (error) =>
        return response.status(422).send(error.message) if error?
        @nanocyteDeployer.startFlow (error) =>
          return response.status(422).send(error.message) if error?
          response.status(201).location("/flows/#{options.flowUuid}/instances/#{options.instanceId}").end()

  destroy: (request, response) =>
    @meshbluHttp = @_createMeshbluHttp request.meshbluAuth
    @meshbluHttp.generateAndStoreToken request.params.flowId, (error, result) =>
      options = @_buildOptions request, result
      @nanocyteDeployer = @_createNanocyteDeployer options
      @nanocyteDeployer.stopFlow (error) =>
        return response.status(422).send(error.message) if error?
        @nanocyteDeployer.destroy (error) =>
          return response.status(422).send(error.message) if error?
          response.status(201).end()

  _createNanocyteDeployer: (options) =>
    meshbluConfig = new MeshbluConfig server_env_name: 'MESHBLU_MESSAGES_SERVER'
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

  _buildOptions: (request, result) =>
    instanceId = @UUID.v4()
    return {
      flowUuid: request.params.flowId
      instanceId: instanceId
      flowToken: result?.token
      userUuid: request.meshbluAuth.uuid
      userToken: request.meshbluAuth.token
      deploymentUuid: request.get('deploymentUuid') ? 'nanocyte-flow-deploy-default'
      octobluUrl: process.env.OCTOBLU_URL
      forwardUrl: "#{process.env.NANOCYTE_ENGINE_URL}/flows/#{request.params.flowId}/instances/#{instanceId}/messages"
      flowLoggerUuid:  process.env.FLOW_LOGGER_UUID
    }
module.exports = InstancesController
