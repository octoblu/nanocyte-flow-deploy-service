_ = require 'lodash'
redis = require 'redis'
MeshbluConfig = require 'meshblu-config'
MeshbluHttp = require 'meshblu-http'
ConfigurationGenerator = require 'nanocyte-configuration-generator'
ConfigurationSaver = require 'nanocyte-configuration-saver-redis'

class InstancesController
  constructor: (dependencies={}) ->
    {@NanocyteDeployer, @UUID} = dependencies
    @NanocyteDeployer ?= require 'nanocyte-deployer'
    @UUID ?= require 'node-uuid'
    @meshbluConfig = new MeshbluConfig

  create: (request, response) =>
    flowId = request.params.flowId
    instanceId = @UUID.v4()
    meshbluAuth = request.meshbluAuth
    deploymentUuid = request.get('deploymentUuid') ? 'nanocyte-flow-deploy-default'

    @meshbluHttp = @_createMeshbluHttp meshbluAuth
    @meshbluHttp.generateAndStoreToken flowId, (error, result) =>
      options =
        flowUuid: flowId
        instanceId: instanceId
        flowToken: result?.token
        userUuid: meshbluAuth.uuid
        userToken: meshbluAuth.token
        deploymentUuid: deploymentUuid
        octobluUrl: process.env.OCTOBLU_URL
        forwardUrl: "#{process.env.NANOCYTE_ENGINE_URL}/flows/#{flowId}/instances/#{instanceId}/messages"

      @nanocyteDeployer = @_createNanocyteDeployer options
      @nanocyteDeployer.deploy (error) =>
        return response.status(422).send(error.message) if error?
        @nanocyteDeployer.startFlow (error) =>
          return response.status(422).send(error.message) if error?
          response.status(201).location("/flows/#{flowId}/instances/#{instanceId}").end()

  _createNanocyteDeployer: (options) =>
    client = redis.createClient process.env.REDIS_PORT, process.env.REDIS_HOST, auth_pass: process.env.REDIS_PASSWORD
    dependencies =
      configurationGenerator: new ConfigurationGenerator
        registryUrl:     process.env.NODE_REGISTRY_URL
        meshbluJSON:     @meshbluConfig.toJSON()
        accessKeyId:     process.env.AWS_ACCESS_KEY_ID
        secretAccessKey: process.env.AWS_SECRET_ACCESS_KEY
      configurationSaver: new ConfigurationSaver client

    new @NanocyteDeployer options, dependencies

  _createMeshbluHttp: (options) =>
    meshbluJSON = _.assign {}, @meshbluConfig.toJSON(), options
    new MeshbluHttp meshbluJSON

module.exports = InstancesController
