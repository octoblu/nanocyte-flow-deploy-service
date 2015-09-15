class InstancesController
  constructor: (dependencies={}) ->
    {@NanocyteDeployer, @nodeUuid} = dependencies
    @NanocyteDeployer ?= require 'nanocyte-deployer'
    @nodeUuid ?= require 'node-uuid'

  create: (request, response) =>
    flowId = request.params.flowId
    instanceId = @nodeUuid.v1()
    @nanocyteDeployer = @_createNanocyteDeployer flowId, instanceId
    @nanocyteDeployer.deploy (error) =>
      return response.status(422).end() if error?
      @nanocyteDeployer.startFlow (error) =>
        return response.status(422).end() if error?
        response.status(201).location("/flows/#{flowId}/instances/#{instanceId}").end()

  _createNanocyteDeployer: (flowId, instanceId) =>
    new @NanocyteDeployer flowId: flowId, instanceId: instanceId

module.exports = InstancesController
