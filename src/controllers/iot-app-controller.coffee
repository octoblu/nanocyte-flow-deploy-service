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
    {@NanocyteDeployer, @UUID, mongoDbUri, redisUri} = dependencies
    @meshbluConfig             = new MeshbluConfig
    @client                    = redis.createClient redisUri, dropBufferSupport: true
    database                   = mongojs mongoDbUri
    @datastore = new Datastore
      database: database
      collection: 'iot-apps'

    setInterval =>
      database.runCommand {ping: 1}, (error) =>
        if error?
          console.error 'MongoDB connection failed, exiting.'
          process.exit 1
    , 10 * 1000

  link: (req, res) =>
    {appId, version} = req.params
    config           = req.body
    flowId           = req.meshbluAuth.uuid
    meshbluHttp      = @_createMeshbluHttp req.meshbluAuth

    {instanceId, online} = config
    configSchema = config.schemas?.configure?.bluprint

    return res.sendStatus(422) unless configSchema? and instanceId?

    configurationSaver = new ConfigurationSaver {@client}

    stopMessage =
      devices: [flowId]
      metadata: to: nodeId: 'engine-stop'

    startMessage =
      devices: [flowId]
      metadata: to: nodeId: 'engine-start'

    steps = [
      async.apply configurationSaver.linkToBluprint, {flowId, instanceId, appId, version, configSchema, config}
      async.apply meshbluHttp.message, stopMessage
    ]

    unless online == false
      steps.push async.apply meshbluHttp.message, startMessage

    async.series steps, (error) =>
      return res.status(error.code || 500).send({error}) if error?
      res.sendStatus 201

  publish: (req, res) =>
    {appId, version}  = req.params
    {flowId} = req.body

    debug("Publishing for AppId #{appId} Version: #{version}")
    meshbluHttp       = @_createMeshbluHttp req.meshbluAuth

    meshbluHttp.generateAndStoreTokenWithOptions appId, {tag: 'nanocyte-flow-deploy-service'}, (error, {token}={}) =>
      debug("Error on generate and store token", error) if error?
      return res.status(error.code ? 403).send(error.message) if error?

      options         = appId: appId, appToken: token, flowId: flowId, version: version
      iotAppPublisher = @_createIotAppPublisher options

      iotAppPublisher.publish (error) =>
        debug("Published the IoTApp and we got an error", error) if error?
        return res.status(error.code ? 422).send(error.message) if error?
        res.sendStatus 201

  _createIotAppPublisher: (options) =>
    { appId, appToken } = options

    meshbluJSON = _.defaults {uuid:  appId, token: appToken}, new MeshbluConfig().toJSON()

    configurationSaver     = new ConfigurationSaver {@client, @datastore}
    configurationGenerator = new ConfigurationGenerator {meshbluJSON}

    new IotAppPublisher options, {configurationSaver, configurationGenerator}

  _createMeshbluHttp: (options) =>
    meshbluJSON = _.assign {}, @meshbluConfig.toJSON(), options
    new MeshbluHttp meshbluJSON


module.exports = IotAppController
