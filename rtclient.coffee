#!/usr/bin/env coffee
#

ctx = require 'zeromq'

cli = ctx.createSocket('router')
#cli = ctx.createSocket('dealer')
cli.identity = 'CLI'

cli.on 'message', (addr, delim, data)->
	msg = []
	for arg in arguments
		msg.push arg.toString()
	console.log 'CLI recvd msg= ', msg

sendMsg = (msg) ->
	cli.send('SRV', 'del', msg)

sendReady = () ->
	sendMsg ('hello from cli')

host = process.argv[2]
port = process.argv[3]
cli.connect("tcp://"+host+":"+port)
#cli.connect("ipc://router.ipc")
setTimeout sendReady, 1000

process.on 'SIGINT', () -> cli.close()
