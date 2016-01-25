InstancesController = require '../../src/controllers/instances-controller'
NanocyteDeployer = require 'nanocyte-deployer'

describe '/instances', ->
  beforeEach ->
    process.env['OCTOBLU_URL'] = 'http://yahho.com'
    process.env['FLOW_LOGGER_UUID'] = 'flow-logger-uuid'
    process.env['NANOCYTE_ENGINE_URL'] = 'https://genisys.com'
    @response =
      location: sinon.spy => @response
      status: sinon.spy => @response
      end: sinon.spy => @response
      send: sinon.spy => @response

    @UUID =
      v4: sinon.stub()

    @nanocyteDeployer =
      deploy: sinon.stub()
      destroy: sinon.stub()
      startFlow: sinon.stub()
      stopFlow: sinon.stub()

    @meshbluHttp =
      generateAndStoreToken: sinon.stub()

    @sut = new InstancesController UUID: @UUID
    @_createNanocyteDeployer = sinon.stub @sut, '_createNanocyteDeployer'
    @_createNanocyteDeployer.returns @nanocyteDeployer
    @_createMeshbluHttp = sinon.stub @sut, '_createMeshbluHttp'
    @_createMeshbluHttp.returns @meshbluHttp

  describe 'when /instances receives a post message', ->
    beforeEach ->
      request =
        get: sinon.stub().withArgs('deploymentUuid').returns('the-deployment-uuid')
        params:
          flowId: 'some-flow-uuid'
        meshbluAuth:
          uuid: 'the-user-uuid'
          token: 'the-user-token'

      @UUID.v4.returns 'an-instance-uuid'
      @sut.create request, @response

    describe 'when deploy is successful', ->
      beforeEach ->
        @meshbluHttp.generateAndStoreToken.yield null, token: 'cool-token-bro'
        @nanocyteDeployer.stopFlow.yield null
        @nanocyteDeployer.deploy.yield null

      it 'should call _createMeshbluHttp', ->
        expect(@_createMeshbluHttp).to.have.been.calledWith uuid: 'the-user-uuid', token: 'the-user-token'

      it 'should call generateAndStoreToken', ->
        expect(@meshbluHttp.generateAndStoreToken).to.have.been.calledWith 'some-flow-uuid'

      it 'should call deploy on the nanocyte deployer', ->
        expect(@nanocyteDeployer.deploy).to.have.been.called

      it 'should call _createNanocyteDeployer', ->
        expect(@_createNanocyteDeployer).to.have.been.calledWith
          deploymentUuid: 'the-deployment-uuid'
          flowUuid: 'some-flow-uuid'
          instanceId: 'an-instance-uuid'
          flowToken: 'cool-token-bro'
          userUuid: 'the-user-uuid'
          userToken: 'the-user-token'
          octobluUrl: 'http://yahho.com'
          forwardUrl: 'https://genisys.com/flows/some-flow-uuid/instances/an-instance-uuid/messages'
          flowLoggerUuid: 'flow-logger-uuid'

      describe 'and startFlow fails', ->
        beforeEach ->
          @nanocyteDeployer.startFlow.yield new Error 'something wrong'

        it 'should respond with a 422', ->
          expect(@response.status).to.have.been.calledWith 422
          expect(@response.send).to.have.been.calledWith 'something wrong'

        it 'should call startFlow on the nanocyte deployer', ->
          expect(@nanocyteDeployer.startFlow).to.have.been.called

      describe 'and startFlow succeeds', ->
        beforeEach ->
          @nanocyteDeployer.startFlow.yield null

        it 'should call startFlow on the nanocyte deployer', ->
          expect(@nanocyteDeployer.startFlow).to.have.been.called

        it 'should respond with a 201', ->
          expect(@response.status).to.have.been.calledWith 201
          expect(@response.location).to.have.been.calledWith '/flows/some-flow-uuid/instances/an-instance-uuid'
          expect(@response.end).to.have.been.called

    describe 'when deploy is failure', ->
      beforeEach ->
        @meshbluHttp.generateAndStoreToken.yield null
        @nanocyteDeployer.stopFlow.yield null
        @nanocyteDeployer.deploy.yield new Error 'something wrong'

      it 'should respond with a 422', ->
        expect(@response.status).to.have.been.calledWith 422
        expect(@response.send).to.have.been.calledWith 'something wrong'

  describe 'when /instances receives a different post message', ->
    beforeEach ->
      request =
        get: sinon.stub().withArgs('deploymentUuid').returns('some-other-deployment-uuid')
        params:
          flowId: 'some-other-flow-uuid'
        meshbluAuth:
          uuid: 'the-user-uuid'
          token: 'the-user-token'

      @UUID.v4.returns 'an-instance-uuid'
      @sut.create request, @response

    describe 'when deploy is successful', ->
      beforeEach ->
        @meshbluHttp.generateAndStoreToken.yield null, token: 'do-you-even-token-bro'
        @nanocyteDeployer.stopFlow.yield null
        @nanocyteDeployer.deploy.yield null
        @nanocyteDeployer.startFlow.yield null

      it 'should call generateAndStoreToken', ->
        expect(@meshbluHttp.generateAndStoreToken).to.have.been.calledWith 'some-other-flow-uuid'

      it 'should call _createNanocyteDeployer', ->
        expect(@_createNanocyteDeployer).to.have.been.calledWith
          deploymentUuid: 'some-other-deployment-uuid'
          flowUuid: 'some-other-flow-uuid'
          instanceId: 'an-instance-uuid'
          flowToken: 'do-you-even-token-bro'
          userUuid: 'the-user-uuid'
          userToken: 'the-user-token'
          octobluUrl: 'http://yahho.com'
          forwardUrl: 'https://genisys.com/flows/some-other-flow-uuid/instances/an-instance-uuid/messages'
          flowLoggerUuid: 'flow-logger-uuid'

      it 'should respond with a 201', ->
        expect(@response.status).to.have.been.calledWith 201
        expect(@response.location).to.have.been.calledWith '/flows/some-other-flow-uuid/instances/an-instance-uuid'
        expect(@response.end).to.have.been.called

      it 'should call deploy on the nanocyte deployer', ->
        expect(@nanocyteDeployer.deploy).to.have.been.called

  describe 'when nanocyte deployer is given a new instance uuid with post', ->
    beforeEach ->
      request =
        get: sinon.stub().withArgs('deploymentUuid').returns 'this-deployment-uuid'
        params:
          flowId: 'some-other-new-flow-uuid'
        meshbluAuth:
          uuid: 'the-user-uuid'
          token: 'the-user-token'

      @UUID.v4.returns 'a-new-instance-uuid'
      @sut.create request, @response

    describe 'when deploy is successful', ->
      beforeEach ->
        @meshbluHttp.generateAndStoreToken.yield null, token: 'lame-token-bro'
        @nanocyteDeployer.stopFlow.yield null
        @nanocyteDeployer.deploy.yield null
        @nanocyteDeployer.startFlow.yield null

      it 'should call _createNanocyteDeployer', ->
        expect(@_createNanocyteDeployer).to.have.been.calledWith
          deploymentUuid: 'this-deployment-uuid'
          flowUuid: 'some-other-new-flow-uuid'
          instanceId: 'a-new-instance-uuid'
          flowToken: 'lame-token-bro'
          userUuid: 'the-user-uuid'
          userToken: 'the-user-token'
          octobluUrl: 'http://yahho.com'
          forwardUrl: 'https://genisys.com/flows/some-other-new-flow-uuid/instances/a-new-instance-uuid/messages'
          flowLoggerUuid: 'flow-logger-uuid'

      it 'should respond with a 201', ->
        expect(@response.status).to.have.been.calledWith 201
        expect(@response.location).to.have.been.calledWith '/flows/some-other-new-flow-uuid/instances/a-new-instance-uuid'
        expect(@response.end).to.have.been.called

      it 'should call deploy on the nanocyte deployer', ->
        expect(@nanocyteDeployer.deploy).to.have.been.called

  describe 'when /instances receives a delete message', ->
    beforeEach ->
      request =
        get: sinon.stub().withArgs('deploymentUuid').returns 'this-deployment-uuid'
        params:
          flowId: 'some-flow-uuid'
        meshbluAuth:
          uuid: 'awesome-user-uuid'
          token: 'super-cool-user-token'

      @UUID.v4.returns 'an-instance-uuid'
      @sut.destroy request, @response

    describe 'when stopFlow is successful', ->
      beforeEach ->
        @meshbluHttp.generateAndStoreToken.yield null, token: 'cool-token-bro'
        @nanocyteDeployer.stopFlow.yield null

      it 'should call generateAndStoreToken', ->
        expect(@meshbluHttp.generateAndStoreToken).to.have.been.calledWith 'some-flow-uuid'

      it 'should call _createNanocyteDeployer', ->
        expect(@_createNanocyteDeployer).to.have.been.calledWith
          flowUuid: 'some-flow-uuid'
          instanceId: 'an-instance-uuid'
          flowToken: 'cool-token-bro'
          userUuid: 'awesome-user-uuid'
          userToken: 'super-cool-user-token'
          deploymentUuid: 'this-deployment-uuid'
          octobluUrl: 'http://yahho.com'
          forwardUrl: 'https://genisys.com/flows/some-flow-uuid/instances/an-instance-uuid/messages'
          flowLoggerUuid: 'flow-logger-uuid'

      it 'should call nanocyteDeployer.stopFlow', ->
        expect(@nanocyteDeployer.stopFlow).to.have.been.called

      describe 'and nanocyteDeployer.destroy is a success', ->
        beforeEach ->
          @nanocyteDeployer.destroy.yield null

        it 'should call nanocyteDeployer.destroy', ->
          expect(@nanocyteDeployer.destroy).to.have.been.called

        it 'should respond with a 201', ->
          expect(@response.status).to.have.been.calledWith 201
          expect(@response.end).to.have.been.called

      describe 'and nanocyteDeployer.destroy is a failure', ->
        beforeEach ->
          @nanocyteDeployer.destroy.yield new Error "wrong things happened"

        it 'should call nanocyteDeployer.destroy', ->
          expect(@nanocyteDeployer.destroy).to.have.been.called

        it 'should respond with a 422', ->
          expect(@response.status).to.have.been.calledWith 422
          expect(@response.send).to.have.been.calledWith "wrong things happened"

    describe 'when stopFlow is failure', ->
      beforeEach ->
        @meshbluHttp.generateAndStoreToken.yield null, token: 'cool-token-bro'
        @nanocyteDeployer.stopFlow.yield new Error "Oh no!"

      it 'should call generateAndStoreToken', ->
        expect(@meshbluHttp.generateAndStoreToken).to.have.been.calledWith 'some-flow-uuid'

      it 'should call _createNanocyteDeployer', ->
        expect(@_createNanocyteDeployer).to.have.been.calledWith
          deploymentUuid: 'this-deployment-uuid'
          flowUuid: 'some-flow-uuid'
          instanceId: 'an-instance-uuid'
          flowToken: 'cool-token-bro'
          userUuid: 'awesome-user-uuid'
          userToken: 'super-cool-user-token'
          octobluUrl: 'http://yahho.com'
          forwardUrl: 'https://genisys.com/flows/some-flow-uuid/instances/an-instance-uuid/messages'
          flowLoggerUuid: 'flow-logger-uuid'

      it 'should respond with a 422 and Error', ->
        expect(@response.status).to.have.been.calledWith 422
        expect(@response.send).to.have.been.calledWith 'Oh no!'

      it 'should call nanocyteDeployer.stopFlow', ->
        expect(@nanocyteDeployer.stopFlow).to.have.been.called
