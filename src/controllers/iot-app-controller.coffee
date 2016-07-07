_                      = require 'lodash'
async                  = require 'async'
debug                  = require('debug')('nanocyte-flow-deploy-service:iot-app-controller')
redis                  = require 'ioredis'
MeshbluConfig          = require 'meshblu-config'
MeshbluHttp            = require 'meshblu-http'

mongojs                = require 'mongojs'
Datastore              = require 'meshblu-core-datastore'

ConfigurationGenerator = require 'nanocyte-configuration-generator'
ConfigurationSaver     = require 'nanocyte-configuration-saver-redis'
IotAppPublisher        = require 'nanocyte-iot-app-publisher'

class IotAppController
  constructor: (dependencies={}) ->
    {@NanocyteDeployer, @UUID, MONGODB_URI, REDIS_URI} = dependencies
    @meshbluConfig             = new MeshbluConfig
    @client                    = redis.createClient REDIS_URI, dropBufferSupport: true
    database                   = mongojs MONGODB_URI

    @datastore = new Datastore
      database: database
      collection: 'iot-apps'


  link: (req, res) =>
    {appId, version} = req.params
    config           = req.body
    flowId           = req.meshbluAuth.uuid
    meshbluHttp      = @_createMeshbluHttp req.meshbluAuth

    {instanceId} = config
    configSchema = config.schemas?.configure?.bluprint
    return res.sendStatus(422) unless configSchema? and instanceId?

    configurationSaver = new ConfigurationSaver {@client}

    stopMessage =
      devices: [flowId]
      metadata: to: nodeId: 'engine-stop'

    startMessage =
      devices: [flowId]
      metadata: to: nodeId: 'engine-start'

    async.series [
      async.apply configurationSaver.linkToBluprint, {flowId, instanceId, appId, version, configSchema, config}
      async.apply meshbluHttp.message, stopMessage
      async.apply meshbluHttp.message, startMessage
    ], (error) =>
      return res.status(error.code || 500).send({error}) if error?
      res.sendStatus 201

  publish: (req, res) =>
    {appId, version}  = req.params
    {flowId} = req.body
    debug("Publishing for AppId #{appId} Version: #{version}")
    debug("Generating new token for Flow", flowId)
    meshbluHttp       = @_createMeshbluHttp req.meshbluAuth

    meshbluHttp.generateAndStoreTokenWithOptions appId, {tag: 'nanocyte-flow-deploy-service'}, (error, appDevice={}) =>
      meshbluHttp.generateAndStoreTokenWithOptions flowId, {tag: 'nanocyte-flow-deploy-service'}, (error, flowDevice={}) =>
        debug("Error on generate and store token", error) if error?
        return res.status(error.code ? 403).send(error.message) if error?

        options         = appId: appId, flowId: flowId, appToken: appDevice.token, flowToken: flowDevice.token,  version: version
        iotAppPublisher = @_createIotAppPublisher options
        iotAppPublisher.publish (error) =>
          debug("Published the IoTApp and we got an error", error) if error?
          return res.status(error.code ? 422).send(error.message) if error?
          res.sendStatus(201)


  _createIotAppPublisher: (options) =>
    { appId, appToken } = options

    meshbluJSON =
      _.extend new MeshbluConfig().toJSON(), {uuid:  appId, token: appToken}

    configurationSaver     = new ConfigurationSaver {@client, @datastore}
    configurationGenerator = new ConfigurationGenerator {meshbluJSON}

    new IotAppPublisher options, {configurationSaver, configurationGenerator}

  _createMeshbluHttp: (options) =>
    meshbluJSON = _.assign {}, @meshbluConfig.toJSON(), options
    new MeshbluHttp meshbluJSON


module.exports = IotAppController
