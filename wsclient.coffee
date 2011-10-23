#!/usr/bin/env coffee
#

ctx = require 'zmq'
EventEmitter = require('events').EventEmitter

class Node extends EventEmitter
	constructor: (@client) ->

class Client extends Node
	constructor: (@client) ->  # inst var inside constructor need this prefix
		@sock = ctx.createSocket('req')
		@sock.identity = 'CLI'
		@bindEvent()

	ready: (srv) ->
		@sock.connect("ipc://router-" + srv + ".ipc")
		console.log 'CLI ready...'
		self = this
		
		# do invoke the func with passed in arg
		tmot = do (self) ->
			() -> self.sendMsg '[CLI request location]'  # return a func with self closed over
		setTimeout tmot, 2000
	
	
	# prototype bind event
	bindEvent: ->
		@sock.on 'message', (msgs) =>
			msg = @parseMsg arguments
			# func created by => can access this property where they are defined.
			@processMsg(msg)

		process.on 'SIGINT', () => @sock.close()

	parseMsg: (args) ->
		msg = []
		for arg in args
			msg.push arg.toString()
		return msg
	
	# process msg sent to worker
	processMsg: (msg) ->
		console.log 'CLI gets resp <<< ', msg.toString()
		#@sendMsg 'to broker'

	sendMsg: (msg) ->
		console.log 'CLI >>> ', msg
		@sock.send msg

exports.Client = Client

cli = new Client('CLI')
cli.ready(process.argv[2])
