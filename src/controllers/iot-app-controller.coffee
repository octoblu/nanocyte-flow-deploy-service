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
    configurationSaver.linkToBluprint {flowId, instanceId, appId, version, configSchema, config}, (error) =>
      return res.status(error.code || 500).send({error}) if error?
      res.sendStatus 201

  publish: (req, res) =>
    {appId, version}  = req.params
    meshbluHttp       = @_createMeshbluHttp req.meshbluAuth

    meshbluHttp.generateAndStoreTokenWithOptions appId, {tag: 'nanocyte-flow-deploy-service'}, (error, {token}={}) =>
      return res.status(error.code ? 403).send(error.message) if error?

      options         = appId: appId, appToken: token, version: version
      iotAppPublisher = @_createIotAppPublisher options
      iotAppPublisher.publish (error) =>
        return res.status(error.code ? 422).send(error.message) if error?
        res.sendStatus(201)


  _createIotAppPublisher: (options) =>
    {appId, appToken} = options

    meshbluJSON =
      _.extend new MeshbluConfig().toJSON(), {uuid:  appId, token: appToken}

    configurationSaver     = new ConfigurationSaver {@client, @datastore}
    configurationGenerator = new ConfigurationGenerator {meshbluJSON}

    new IotAppPublisher options, {configurationSaver, configurationGenerator}


  _createMeshbluHttp: (options) =>
    meshbluJSON = _.assign {}, @meshbluConfig.toJSON(), options
    new MeshbluHttp meshbluJSON


module.exports = IotAppController
