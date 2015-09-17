InstancesController = require '../../src/controllers/instances-controller'
NanocyteDeployer = require 'nanocyte-deployer'

describe '/instances', ->
  beforeEach ->
    process.env['OCTOBLU_URL'] = 'yahho.com'
    @response =
      location: sinon.spy => @response
      status: sinon.spy => @response
      end: sinon.spy => @response

    @nodeUuid =
      v1: sinon.stub()

    @nanocyteDeployer =
      deploy: sinon.stub()
      startFlow: sinon.stub()

    @meshbluHttp =
      generateAndStoreToken: sinon.stub()

    @sut = new InstancesController nodeUuid: @nodeUuid
    @_createNanocyteDeployer = sinon.stub @sut, '_createNanocyteDeployer'
    @_createNanocyteDeployer.returns @nanocyteDeployer
    @_createMeshbluHttp = sinon.stub @sut, '_createMeshbluHttp'
    @_createMeshbluHttp.returns @meshbluHttp

  describe 'when /instances receives a message', ->
    beforeEach ->
      request =
        params:
          flowId: 'some-flow-uuid'
        meshbluAuth:
          uuid: 'the-user-uuid'
          token: 'the-user-token'

      @nodeUuid.v1.returns 'an-instance-uuid'
      @sut.create request, @response

    describe 'when deploy is successful', ->
      beforeEach ->
        @meshbluHttp.generateAndStoreToken.yield null, token: 'cool-token-bro'
        @nanocyteDeployer.deploy.yield null

      it 'should call _createMeshbluHttp', ->
        expect(@_createMeshbluHttp).to.have.been.calledWith uuid: 'the-user-uuid', token: 'the-user-token'

      it 'should call generateAndStoreToken', ->
        expect(@meshbluHttp.generateAndStoreToken).to.have.been.calledWith 'some-flow-uuid'

      it 'should call deploy on the nanocyte deployer', ->
        expect(@nanocyteDeployer.deploy).to.have.been.called

      it 'should call _createNanocyteDeployer', ->
        expect(@_createNanocyteDeployer).to.have.been.calledWith
          flowUuid: 'some-flow-uuid'
          instanceId: 'an-instance-uuid'
          flowToken: 'cool-token-bro'
          userUuid: 'the-user-uuid'
          userToken: 'the-user-token'
          octobluUrl: 'yahho.com'

      describe 'and startFlow fails', ->
        beforeEach ->
          @nanocyteDeployer.startFlow.yield new Error 'something wrong'

        it 'should respond with a 422', ->
          expect(@response.status).to.have.been.calledWith 422
          expect(@response.end).to.have.been.called

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
        @nanocyteDeployer.deploy.yield new Error 'something wrong'

      it 'should respond with a 422', ->
        expect(@response.status).to.have.been.calledWith 422
        expect(@response.end).to.have.been.called

  describe 'when /instances receives a different message', ->
    beforeEach ->
      request =
        params:
          flowId: 'some-other-flow-uuid'
        meshbluAuth:
          uuid: 'the-user-uuid'
          token: 'the-user-token'

      @nodeUuid.v1.returns 'an-instance-uuid'
      @sut.create request, @response

    describe 'when deploy is successful', ->
      beforeEach ->
        @meshbluHttp.generateAndStoreToken.yield null, token: 'do-you-even-token-bro'
        @nanocyteDeployer.deploy.yield null
        @nanocyteDeployer.startFlow.yield null

      it 'should call generateAndStoreToken', ->
        expect(@meshbluHttp.generateAndStoreToken).to.have.been.calledWith 'some-other-flow-uuid'

      it 'should call _createNanocyteDeployer', ->
        expect(@_createNanocyteDeployer).to.have.been.calledWith
          flowUuid: 'some-other-flow-uuid'
          instanceId: 'an-instance-uuid'
          flowToken: 'do-you-even-token-bro'
          userUuid: 'the-user-uuid'
          userToken: 'the-user-token'
          octobluUrl: 'yahho.com'

      it 'should respond with a 201', ->
        expect(@response.status).to.have.been.calledWith 201
        expect(@response.location).to.have.been.calledWith '/flows/some-other-flow-uuid/instances/an-instance-uuid'
        expect(@response.end).to.have.been.called

      it 'should call deploy on the nanocyte deployer', ->
        expect(@nanocyteDeployer.deploy).to.have.been.called

  describe 'when nanocyte deployer is given a new instance uuid', ->
    beforeEach ->
      request =
        params:
          flowId: 'some-other-new-flow-uuid'
        meshbluAuth:
          uuid: 'the-user-uuid'
          token: 'the-user-token'

      @nodeUuid.v1.returns 'a-new-instance-uuid'
      @sut.create request, @response

    describe 'when deploy is successful', ->
      beforeEach ->
        @meshbluHttp.generateAndStoreToken.yield null, token: 'lame-token-bro'
        @nanocyteDeployer.deploy.yield null
        @nanocyteDeployer.startFlow.yield null

      it 'should call _createNanocyteDeployer', ->
        expect(@_createNanocyteDeployer).to.have.been.calledWith
          flowUuid: 'some-other-new-flow-uuid'
          instanceId: 'a-new-instance-uuid'
          flowToken: 'lame-token-bro'
          userUuid: 'the-user-uuid'
          userToken: 'the-user-token'
          octobluUrl: 'yahho.com'

      it 'should respond with a 201', ->
        expect(@response.status).to.have.been.calledWith 201
        expect(@response.location).to.have.been.calledWith '/flows/some-other-new-flow-uuid/instances/a-new-instance-uuid'
        expect(@response.end).to.have.been.called

      it 'should call deploy on the nanocyte deployer', ->
        expect(@nanocyteDeployer.deploy).to.have.been.called
