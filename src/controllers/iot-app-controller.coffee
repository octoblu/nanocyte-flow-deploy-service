_                      = require 'lodash'
async                  = require 'async'
debug                  = require('debug')('nanocyte-flow-deploy-service:iot-app-controller')
redis                  = require 'ioredis'
MeshbluConfig          = require 'meshblu-config'
MeshbluHttp            = require 'meshblu-http'
ConfigurationSaver     = require 'nanocyte-configuration-saver-redis'
client                 = redis.createClient process.env.REDIS_PORT, process.env.REDIS_HOST, auth_pass: process.env.REDIS_PASSWORD, dropBufferSupport: true
class IotAppController
  constructor: (dependencies={}) ->
    {@NanocyteDeployer, @UUID} = dependencies
    @meshbluConfig = new MeshbluConfig

  link: (req, res) =>
    {appId, version} = req.params
    config           = req.body
    flowId           = req.meshbluAuth.uuid
    @meshbluHttp     = @_createMeshbluHttp req.meshbluAuth

    {instanceId} = config
    configSchema = config.schemas?.configure?.iotApp
    return res.sendStatus(422) unless configSchema? and instanceId?
    @meshbluHttp.device appId, (error) =>
      return res.sendStatus(403) if error?
      configurationSaver = new ConfigurationSaver client
      configurationSaver.saveIotApp {flowId, instanceId, appId, version, configSchema, config}, (error) =>
        return res.status(error.code || 500).send({error}) if error?
        res.sendStatus 201

  _createMeshbluHttp: (options) =>
    meshbluJSON = _.assign {}, @meshbluConfig.toJSON(), options
    new MeshbluHttp meshbluJSON


module.exports = IotAppController
