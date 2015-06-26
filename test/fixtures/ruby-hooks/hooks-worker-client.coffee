hooks = require 'hooks'
net = require 'net'
EventEmitter = require('events').EventEmitter
{spawn} = require('child_process')

HOOK_TIMEOUT = 5000
WORKER_HOST = 'localhost'
WORKER_PORT = 61321
WORKER_MESSAGE_DELIMITER = "\n"
WORKER_COMMAND = ['ruby' ,['./test/fixtures/ruby-hooks/dredd-worker.rb', './test/fixtures/ruby-hooks/hookfile*.rb']]

emitter = new EventEmitter

worker = spawn.apply null, WORKER_COMMAND

console.log 'Spawning worker'

worker.stdout.on 'data', (data) ->
  console.log "Hook worker stdout:", data.toString()

worker.stderr.on 'data', (data) ->
  console.log "Hook worker stderr:", data.toString()

worker.on 'error', (error) ->
  console.log error

# Wait before connecting to a worker
# Hack for blocking sleep, loading of hooks in dredd is not async
# TODO Move connecting to worker to async beforeAll hook
now = new Date().getTime()
while new Date().getTime() < now + 1000
  true

workerClient = net.connect port: WORKER_PORT, host: WORKER_HOST, () ->
  # Do something when dredd starts
  # message =
  #   event: 'hooksInit'

  # worker.write JSON.stringify message
  # worker.write WORKER_MESSAGE_DELIMITER

workerClient.on 'error', () ->
  console.log 'Error connecting to the hook worker. Is the worker running?'
  process.exit()

workerBuffer = ""

workerClient.on 'data', (data) ->
  workerBuffer += data.toString()
  if data.toString().indexOf(WORKER_MESSAGE_DELIMITER) > -1
    splittedData = workerBuffer.split(WORKER_MESSAGE_DELIMITER)

    # add last chunk to the buffer
    workerBuffer = splittedData.pop()

    messages = []
    for message in splittedData
      messages.push JSON.parse message

    for message in messages
      if message.uuid?
        emitter.emit message.uuid, message
      else
        console.log 'UUID not present in message: ', JSON.stringify(message, null ,2)

# Wait before starting a test
# Hack for blocking sleep, loading of hooks in dredd is not async
# TODO Move connecting to worker to async beforeAll hook
now = new Date().getTime()
while new Date().getTime() < now + 1000
  true

hooks.beforeEach (transaction, callback) ->
  # avoiding dependency on external module here.
  uuid = Date.now().toString() + '-' + Math. random().toString(36).substring(7)

  # send transaction to the worker
  message =
    event: 'before'
    uuid: uuid
    data: transaction

  workerClient.write JSON.stringify message
  workerClient.write WORKER_MESSAGE_DELIMITER

  # set timeout for the hook
  timeout = setTimeout () ->
    transaction.fail = 'Hook timed out.'
    callback()
  , HOOK_TIMEOUT

  # register event for the sent transaction
  emitter.on uuid, (receivedMessage) ->
    clearTimeout timeout
    # workaround for assigning transacition
    # this does not work:
    # transaction = receivedMessage.data
    for key, value of receivedMessage.data
      transaction[key] = value
    callback()

hooks.beforeEachValidation (transaction, callback) ->
  # avoiding dependency on external module here.
  uuid = Date.now().toString() + '-' + Math. random().toString(36).substring(7)

  # send transaction to the worker
  message =
    event: 'beforeValidation'
    uuid: uuid
    data: transaction

  workerClient.write JSON.stringify message
  workerClient.write WORKER_MESSAGE_DELIMITER

  # set timeout for the hook
  timeout = setTimeout () ->
    transaction.fail = 'Hook timed out.'
    callback()
  , HOOK_TIMEOUT

  # register event for the sent transaction
  emitter.on uuid, (receivedMessage) ->
    clearTimeout timeout
    # workaround for assigning transacition
    # this does not work:
    # transaction = receivedMessage.data
    for key, value of receivedMessage.data
      transaction[key] = value
    callback()


hooks.afterEach (transaction, callback) ->
  # avoiding dependency on external module here.
  uuid = Date.now().toString() + '-' + Math. random().toString(36).substring(7)

  # send transaction to the worker
  message =
    event: 'after'
    uuid: uuid
    data: transaction

  workerClient.write JSON.stringify message
  workerClient.write WORKER_MESSAGE_DELIMITER

  timeout = setTimeout () ->
    transaction.fail = 'Hook timed out.'
    callback()
  , HOOK_TIMEOUT

  emitter.on uuid, (receivedMessage) ->
    clearTimeout timeout
    # workaround for assigning transacition
    # this does not work:
    # transaction = receivedMessage.data
    for key, value of receivedMessage.data
      transaction[key] = value
    callback()

hooks.beforeAll (transactions, callback) ->
  # avoiding dependency on external module here.
  uuid = Date.now().toString() + '-' + Math. random().toString(36).substring(7)

  # send transaction to the worker
  message =
    event: 'beforeAll'
    uuid: uuid
    data: transactions

  workerClient.write JSON.stringify message
  workerClient.write WORKER_MESSAGE_DELIMITER

  timeout = setTimeout () ->
    console.log 'Hook timeouted.'
    callback()
  , HOOK_TIMEOUT

  emitter.on uuid, (receivedMessage) ->
    clearTimeout timeout

    # workaround for assigning transacitions
    # this does not work:
    # transactions = receivedMessage.data
    for value, index in receivedMessage.data
      transactions[index] = value
    callback()

hooks.afterAll (transactions, callback) ->
  # avoiding dependency on external module here.
  uuid = Date.now().toString() + '-' + Math. random().toString(36).substring(7)

  # send transaction to the worker
  message =
    event: 'afterAll'
    uuid: uuid
    data: transactions

  workerClient.write JSON.stringify message
  workerClient.write WORKER_MESSAGE_DELIMITER

  timeout = setTimeout () ->
    console.log 'Hook timeouted.'
    callback()
  , HOOK_TIMEOUT

  emitter.on uuid, (receivedMessage) ->
    clearTimeout timeout

    # workaround for assigning transacition
    # this does not work:
    # transactions = receivedMessage.data
    for value, index in receivedMessage.data
      transactions[index] = value
    callback()


hooks.afterAll (transactions, callback) ->
  worker.kill 'SIGKILL'

  # this is needed to for transaction modification integration tests
  # it can be refactored to expectations on received body in the express app in tests
  # in test/unit/transaction-runner-test.coffee > Command line interface > Using workaround for hooks in ruby

  if process.env['TEST_DREDD_WORKER'] == "true"
    console.log 'CHOP HERE'
    console.log JSON.stringify transactions[0]['hooks_modifications'], null, 2
    console.log 'CHOP HERE'
  callback()