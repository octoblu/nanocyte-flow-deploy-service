_ = require 'lodash'
async = require 'async'
mongojs = require 'mongojs'
Redis   = require 'ioredis'
request = require 'request'
MeshbluHttp = require 'meshblu-http'

throw new Error("INTERVAL_REDIS_URI is required") unless process.env.INTERVAL_REDIS_URI?

client = new Redis process.env.REDIS_URI, dropBufferSupport: true
intervalClient = new Redis process.env.INTERVAL_REDIS_URI, dropBufferSupport: true
database = mongojs process.env.MONGODB_URI, ['instances']
datastore = database.instances

convertFlow = (record, callback) =>
  {flowId, instanceId} = record
  flowId = flowId.replace /-stop/, ''
  console.log {flowId}
  datastore.findOne {flowId, instanceId}, (error, record) =>
    flowData = JSON.parse record.flowData
    {uuid, token} = flowData['engine-output']?.config
    return callback() unless uuid? && token?

    meshbluHttp = new MeshbluHttp {uuid, token, hostname: 'meshblu-http.octoblu.com'}
    meshbluHttp.whoami (error) =>
      return callback() if error?

      intervals = getIntervals flowData
      uniqIntervals = _.uniqBy intervals, 'id'
      async.map uniqIntervals, async.apply(convertToDevice, uuid, token), (error, data) =>
        return callback error if error?
        data = _.compact data
        async.each data, async.apply(updateInterval, flowId, instanceId, intervals), (error) =>
          updatePermissions {uuid, token, data}, (error) =>
            return callback error if error?
            updateMongoFlow {flowId, instanceId, flowData}, (error) =>
              return callback error if error?
              update =
                $set:
                  intervalDeviceMigration: Date.now()
              datastore.update flowId: "#{flowId}-stop", update, callback

updateMongoFlow = ({flowId, instanceId, flowData}, callback) =>
  update =
    $set:
      flowData: JSON.stringify(flowData)
      intervalDeviceMigration: Date.now()
  datastore.update {flowId, instanceId}, update, callback

updatePermissions = ({uuid, token, data}, callback) =>
  deviceIds = _.map data, 'uuid'

  updateSendWhitelist =
    $addToSet:
      sendWhitelist:
        $each: deviceIds

  meshbluHttp = new MeshbluHttp {uuid, token, hostname: 'meshblu-http.octoblu.com'}
  meshbluHttp.updateDangerously uuid, updateSendWhitelist, callback

updateInterval = (flowId, instanceId, intervals, intervalDevice, callback) =>
  intervals = _.filter intervals, id: intervalDevice.nodeId
  async.each intervals, (interval, callback) =>
    interval.deviceId = intervalDevice.deviceId
    nodeId = interval.id

    client.hset flowId, "#{instanceId}/#{interval.id}/config", JSON.stringify(interval), (error) =>
      return callback error if error?

      redisData = [
        "interval/uuid/#{flowId}/#{nodeId}"
        intervalDevice.uuid
        "interval/token/#{flowId}/#{nodeId}"
        intervalDevice.token
      ]
      intervalClient.mset redisData, callback
  , callback

convertToDevice = (uuid, token, interval, callback) =>
  return callback() unless interval.deviceId == '765bd3a4-546d-45e6-a62f-1157281083f0'
  createFlowDevice {uuid, token, nodeId: interval.id}, (error, response) =>
    return callback error if error?
    callback null, nodeId: interval.id, uuid: response.uuid, token: response.token

createFlowDevice = ({uuid, token, nodeId}, callback) =>
  options =
    uri: "https://interval.octoblu.com/nodes/#{nodeId}/intervals"
    json: true
    auth:
      username: uuid
      password: token

  request.post options, (error, response, body) =>
    return callback error if error?
    return callback new Error "Bad response: #{response.statusCode}" unless response.statusCode < 300
    callback null, body

getIntervals = (flowData) =>
  nodes = _.map _.values(flowData), 'config'
  _.filter nodes, (node) =>
    return _.includes ['interval', 'schedule', 'throttle', 'debounce', 'delay', 'leading-edge-debounce'], node?.class

query =
  flowId: /-stop$/
  intervalDeviceMigration: $eq: null

cursor = datastore.find(query).limit 1000, (error, records) =>
  throw error if error?
  async.eachSeries records, convertFlow, (error) =>
    throw error if error?
    process.exit 0
