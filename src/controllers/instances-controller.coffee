_ = require 'lodash'
MeshbluConfig = require 'meshblu-config'
MeshbluHttp = require 'meshblu-http'

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
    dependencies =
      ConfigurationGenerator: require 'nanocyte-configuration-generator'
      ConfigurationSaver: require 'nanocyte-configuration-saver-redis'
    new @NanocyteDeployer options, dependencies

  _createMeshbluHttp: (options) =>
    meshbluConfig = new MeshbluConfig
    meshbluJSON = _.assign {}, meshbluConfig.toJSON(), options
    new MeshbluHttp meshbluJSON

module.exports = InstancesController
