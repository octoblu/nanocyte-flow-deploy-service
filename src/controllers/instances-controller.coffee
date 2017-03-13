_                       = require 'lodash'
async                   = require 'async'
debug                   = require('debug')('nanocyte-flow-deploy-service:instances-controller')
redis                   = require 'ioredis'
MeshbluConfig           = require 'meshblu-config'
MeshbluHttp             = require 'meshblu-http'
mongojs                 = require 'mongojs'
Datastore               = require 'meshblu-core-datastore'
ConfigurationGenerator  = require 'nanocyte-configuration-generator'
ConfigurationSaverMongo = require 'nanocyte-configuration-saver-mongo'
SimpleBenchmark         = require 'simple-benchmark'

class InstancesController
  constructor: (dependencies={}) ->
    {
      @NanocyteDeployer
      @UUID
      @mongoDbUri
      @redisUri
      @intervalServiceUri
      @octobluUrl
      @nanocyteEngineUrl
      @nodeRegistryUrl
      @flowLoggerUuid
    } = dependencies
    throw new Error 'InstancesController requires mongoDbUri' unless @mongoDbUri?
    throw new Error 'InstancesController requires redisUri' unless @redisUri?
    throw new Error 'InstancesController requires intervalServiceUri' unless @intervalServiceUri?
    throw new Error 'InstancesController requires nanocyteEngineUrl' unless @nanocyteEngineUrl?
    throw new Error 'InstancesController requires octobluUrl' unless @octobluUrl?
    throw new Error 'InstancesController requires nodeRegistryUrl' unless @nodeRegistryUrl?
    @NanocyteDeployer ?= require 'nanocyte-deployer'
    @UUID ?= require 'node-uuid'
    @meshbluConfig = new MeshbluConfig
    @client = redis.createClient @redisUri, dropBufferSupport: true
    database = mongojs @mongoDbUri
    @datastore = new Datastore
      database: database
      collection: 'instances'

    setInterval =>
      database.runCommand {ping: 1}, (error) =>
        if error?
          console.error 'MongoDB connection failed, exiting.'
          process.exit 1
    , 10 * 1000

  create: (req, res) =>
    benchmark = new SimpleBenchmark label: "create-#{req.params.flowId}"
    @meshbluHttp = @_createMeshbluHttp req.meshbluAuth
    options = tag: 'nanocyte-flow-deploy-service'

    @meshbluHttp.generateAndStoreTokenWithOptions req.params.flowId, options, (error, result) =>
      return res.status(error.code ? 403).send(error.message) if error?
      options = @_buildOptions req, result
      nanocyteDeployer = @_createNanocyteDeployer options

      async.series [
        async.apply nanocyteDeployer.sendStopFlowMessage
        async.apply nanocyteDeployer.deploy
        async.apply nanocyteDeployer.startFlow
      ], (error) =>
        debug benchmark.toString()
        if error?
          console.error error.stack
          return res.status(error.code ? 422).send(error.message)
        res.status(201).location("/flows/#{options.flowUuid}/instances/#{options.instanceId}").end()

  destroy: (req, res) =>
    benchmark = new SimpleBenchmark label: "create-#{req.params.flowId}"
    @meshbluHttp = @_createMeshbluHttp req.meshbluAuth
    options =
      tag: 'nanocyte-flow-deploy-service'
    @meshbluHttp.generateAndStoreTokenWithOptions req.params.flowId, options, (error, result) =>
      return res.status(error.code ? 403).send(error.message) if error?
      options = @_buildOptions req, result
      nanocyteDeployer = @_createNanocyteDeployer options
      async.series [
        async.apply nanocyteDeployer.stopFlow
        async.apply nanocyteDeployer.destroy
      ], (error) =>
        debug benchmark.toString()
        if error?
          console.error error.stack
          return res.status(error.code ? 422).send(error.message)
        res.status(204).end()

  _createNanocyteDeployer: (options) =>
    {userUuid, userToken} = options
    meshbluConfig = new MeshbluConfig
      uuid: userUuid
      token: userToken

    dependencies =
      configurationGenerator: new ConfigurationGenerator
        registryUrl:     @nodeRegistryUrl
        meshbluJSON:     meshbluConfig.toJSON()
        accessKeyId:     @awsAccessKeyId
        secretAccessKey: @awsSecretAccessKey
      configurationSaver: new ConfigurationSaverMongo {@datastore}

    new @NanocyteDeployer options, dependencies

  _createMeshbluHttp: (options) =>
    meshbluJSON = _.defaults options, @meshbluConfig.toJSON()
    new MeshbluHttp meshbluJSON

  _buildOptions: (req, result) =>
    instanceId = @UUID.v4()
    return {
      client: @client
      flowUuid: req.params.flowId
      instanceId: instanceId
      flowToken: result?.token
      userUuid: req.meshbluAuth.uuid
      userToken: req.meshbluAuth.token
      deploymentUuid: req.get('deploymentUuid') ? 'nanocyte-flow-deploy-default'
      octobluUrl: @octobluUrl
      forwardUrl: "#{@nanocyteEngineUrl}/flows/#{req.params.flowId}/instances/#{instanceId}/messages"
      flowLoggerUuid:  @flowLoggerUuid
      intervalServiceUri: @intervalServiceUri
    }

module.exports = InstancesController
