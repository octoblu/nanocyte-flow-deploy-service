morgan              = require 'morgan'
express             = require 'express'
bodyParser          = require 'body-parser'
errorHandler        = require 'errorhandler'
MeshbluConfig       = require 'meshblu-config'
MeshbluAuth         = require 'express-meshblu-auth'
meshbluHealthcheck  = require 'express-meshblu-healthcheck'
expressVersion      = require 'express-package-version'
InstancesController = require './src/controllers/instances-controller'
IotAppController    = require './src/controllers/iot-app-controller'
debug               = require('debug')('nanocyte-flow-deploy-service')
cors                = require 'cors'

serverOptions = {
  mongoDbUri: process.env.MONGODB_URI
  redisUri: process.env.REDIS_URI
  intervalServiceUri: process.env.INTERVAL_SERVICE_URI
  octobluUrl: process.env.OCTOBLU_URL
  flowLoggerUuid: process.env.FLOW_LOGGER_UUID
  nanocyteEngineUrl: process.env.NANOCYTE_ENGINE_URL
  nodeRegistryUrl: process.env.NODE_REGISTRY_URL
  awsAccessKeyId: process.env.AWS_ACCESS_KEY_ID
  awsSecretAccessKey: process.env.AWS_SECRET_ACCESS_KEY
}

throw new Error 'MONGODB_URI is required' unless serverOptions.mongoDbUri?
throw new Error 'REDIS_URI is required' unless serverOptions.redisUri?
throw new Error 'INTERVAL_SERVICE_URI is required' unless serverOptions.intervalServiceUri?
throw new Error 'OCTOBLU_URL is required' unless serverOptions.octobluUrl?
throw new Error 'NANOCYTE_ENGINE_URL is required' unless serverOptions.nanocyteEngineUrl?
throw new Error 'NODE_REGISTRY_URL is required' unless serverOptions.nodeRegistryUrl?
throw new Error 'AWS_ACCESS_KEY_ID is required' unless serverOptions.awsAccessKeyId?
throw new Error 'AWS_SECRET_ACCESS_KEY is required' unless serverOptions.awsSecretAccessKey?

instancesController = new InstancesController serverOptions
iotAppController    = new IotAppController serverOptions

PORT  = process.env.PORT ? 80

meshbluConfig = new MeshbluConfig
meshbluAuth = new MeshbluAuth meshbluConfig.toJSON()
app = express()
app.use cors()
app.use meshbluHealthcheck()
app.use expressVersion({format: '{"version": "%s"}'})
app.use morgan 'dev'
app.use errorHandler()
app.use meshbluAuth.get()
app.use meshbluAuth.gateway()
app.use bodyParser.urlencoded limit: '50mb', extended : true
app.use bodyParser.json limit : '50mb'

app.post '/bluprint/:appId',      iotAppController.publish
app.post '/bluprint/:appId/link', iotAppController.link

app.post '/flows/:flowId/instances',      instancesController.create
app.delete '/flows/:flowId/instances',    instancesController.destroy

server = app.listen PORT, ->
  host = server.address().address
  port = server.address().port

  console.log "Server running on #{host}:#{port}"

process.on 'SIGTERM', =>
  console.log 'SIGTERM caught, exiting'
  process.exit 0
