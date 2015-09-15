_ = require 'lodash'
redis = require 'redis'
MeshbluConfig = require 'meshblu-config'
MeshbluHttp = require 'meshblu-http'
ConfigurationGenerator = require 'nanocyte-configuration-generator'
ConfigurationSaver = require 'nanocyte-configuration-saver-redis'

class InstancesController
  constructor: (dependencies={}) ->
    {@NanocyteDeployer, @nodeUuid} = dependencies
    @NanocyteDeployer ?= require 'nanocyte-deployer'
    @nodeUuid ?= require 'node-uuid'

  create: (request, response) =>
    flowId = request.params.flowId
    instanceId = @nodeUuid.v1()

    @meshbluHttp = @_createMeshbluHttp request.meshbluAuth
    @meshbluHttp.generateAndStoreToken flowId, (error, result) =>
      options =
        flowUuid: flowId
        instanceId: instanceId
        flowToken: result?.token

      @nanocyteDeployer = @_createNanocyteDeployer options
      @nanocyteDeployer.deploy (error) =>
        return response.status(422).end() if error?
        @nanocyteDeployer.startFlow (error) =>
          return response.status(422).end() if error?
          response.status(201).location("/flows/#{flowId}/instances/#{instanceId}").end()

  _createNanocyteDeployer: (options) =>
    client = redis.createClient process.env.REDIS_PORT, process.env.REDIS_HOST, auth_pass: process.env.REDIS_PASSWORD
    dependencies =
      configurationGenerator: new ConfigurationGenerator
      configurationSaver: new ConfigurationSaver client

    new @NanocyteDeployer options, dependencies

  _createMeshbluHttp: (options) =>
    meshbluConfig = new MeshbluConfig
    meshbluJSON = _.assign {}, meshbluConfig.toJSON(), options
    new MeshbluHttp meshbluJSON

module.exports = InstancesController
