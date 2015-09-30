morgan = require 'morgan'
express = require 'express'
bodyParser = require 'body-parser'
errorHandler = require 'errorhandler'
MeshbluConfig = require 'meshblu-config'
meshbluAuth = require 'express-meshblu-auth'
meshbluHealthcheck = require 'express-meshblu-healthcheck'
debug = require('debug')('nanocyte-flow-deploy-service')

InstancesController = require './src/controllers/instances-controller'
instancesController = new InstancesController

PORT  = process.env.PORT ? 80

meshbluConfig = new MeshbluConfig

app = express()
app.use morgan 'dev'
app.use errorHandler()
app.use meshbluHealthcheck()
app.use meshbluAuth meshbluConfig.toJSON()
app.use bodyParser.urlencoded limit: '50mb', extended : true
app.use bodyParser.json limit : '50mb'

app.post '/flows/:flowId/instances', instancesController.create
app.del '/flows/:flowId/instances', instancesController.destroy

server = app.listen PORT, ->
  host = server.address().address
  port = server.address().port

  console.log "Server running on #{host}:#{port}"
