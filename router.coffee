#!/usr/bin/env coffee
#

# when sending to req socket, you got to have '' as delimiter.
# req type socket is relying on '' delimt to recv msg

ctx = require 'zeromq'

router = ctx.createSocket('router')
router.identity = 'SRV'

router.bind 'tcp://*:5555', (err) ->
#router.bind 'ipc://router.ipc', (err) ->
	console.log err if err
	console.log 'Listening on 5555'

router.on 'message', (addr, delim, data)->
	console.log 'SRV recvd msg:', addr.toString(), delim.toString(), data.toString()
	router.send addr, delim, 'reply from server'

process.on 'SIGINT', () -> router.close()
