morgan              = require 'morgan'
express             = require 'express'
bodyParser          = require 'body-parser'
errorHandler        = require 'errorhandler'
MeshbluConfig       = require 'meshblu-config'
MeshbluAuth         = require 'express-meshblu-auth'
meshbluHealthcheck  = require 'express-meshblu-healthcheck'
debug               = require('debug')('nanocyte-flow-deploy-service')
expressVersion      = require 'express-package-version'
InstancesController = require './src/controllers/instances-controller'
IotAppController    = require './src/controllers/iot-app-controller'

instancesController = new InstancesController
iotAppController    = new IotAppController

PORT  = process.env.PORT ? 80

meshbluConfig = new MeshbluConfig
meshbluAuth = new MeshbluAuth meshbluConfig.toJSON()
app = express()
app.use meshbluHealthcheck()
app.use expressVersion({format: '{"version": "%s"}'})
app.use morgan 'dev'
app.use errorHandler()
app.use meshbluAuth.retrieve()
app.use meshbluAuth.gateway()
app.use bodyParser.urlencoded limit: '50mb', extended : true
app.use bodyParser.json limit : '50mb'
app.post '/bluprint/link/:appId/:version', iotAppController.link
app.post '/flows/:flowId/instances',      instancesController.create
app.delete '/flows/:flowId/instances',    instancesController.destroy

server = app.listen PORT, ->
  host = server.address().address
  port = server.address().port

  console.log "Server running on #{host}:#{port}"

process.on 'SIGTERM', =>
  console.log 'SIGTERM caught, exiting'
  process.exit 0
