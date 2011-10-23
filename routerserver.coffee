#!/usr/bin/env coffee
#
# when router get a msg, the first argument is the sender's addr
# this sender's addr is added by zmp implicitly as part of envelop.
#
#RS = require 'routerserver'
#router = RS.create('SRV')
#router.ready()

EventEmitter = require('events').EventEmitter
path = require 'path'
#ctx = require 'zeromq'
ctx = require 'zmq'

class Node extends EventEmitter
	constructor: (@_ID) ->

class RouterServer extends Node
	constructor: (@_ID) ->
		@sock = ctx.createSocket('router')
		@sock.identity = @_ID
		@bindEvent()

	# factory pattern
	@create: (name, option) ->
		rter = new RouterServer(name)
		if typeof options is 'object'
			for own key, value of options
				rter[key] = value

		return rter

	ready: ->
		@sock.bind 'tcp://*:5555', (err) =>
			console.log 'server ' + @_ID + ' listening to 5555, ' + err
		console.log @_ID + ' ready...'

	parseMsg: (args) ->
		msg = []
		for arg in args
			msg.push arg.toString()
		return msg

	bindEvent: ->
		@sock.on 'message', (addr, data) =>
			msg = @parseMsg arguments
			# func created by => can access this property where they are defined.
			@processMsg(msg)

		process.on 'SIGINT', () =>
			@sock.close()

	# process msg sent to worker
	processMsg: (msg) ->
		console.log 'Req <<< ', msg.toString()
		from = msg.shift()
		@sendMsg from, msg

# when sending to req socket, you got to have '' as delimiter.
# req type socket is relying on '' delimt to recv msg
	sendMsg: (addr, msg) ->
		msg.unshift addr
		console.log @_ID + ' >>> ', addr, msg
		@sock.send.apply @sock, msg


exports.create = RouterServer.create

router = new RouterServer('SRV')
router.ready()
