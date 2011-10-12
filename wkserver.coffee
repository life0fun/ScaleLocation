#!/usr/bin/env coffee
#

ctx = require 'zeromq'
EventEmitter = require('events').EventEmitter

class Node extends EventEmitter
	constructor: (@client) ->

class Worker extends Node
	constructor: (@client) ->  # inst var inside constructor need this prefix
		@sock = ctx.createSocket('req')
		@sock.identity = 'WRK'
		@bindEvent()

	ready: (srv) ->
		@sock.connect("ipc://router-wk-"+srv+".ipc")  # connect to be
		console.log 'WRK ready...'
		self = this
		
		# do invoke the func with passed in arg
		tmot = do (self) ->
			() -> self.sendMsg ['ready']  # return a func with self closed over
		setTimeout tmot, 1000
	
	# prototype bind event
	bindEvent: ->
		@sock.on 'message', (msgs) =>
			# func created by => can access this property where they are defined.
			msg = @parseMsg arguments
			@processMsg(msg)

		process.on 'SIGINT', () -> @sock.close()
	
	parseMsg: (args) ->
		msg = []
		for arg in args
			msg.push arg.toString()
		return msg
	
	# process msg sent to worker
	processMsg: (msg) ->
		console.log 'WRK <<< ', msg.toString()
		req = msg.pop()
		req += ' [ worker done, result 0 ]'
		msg.push req
		@sendMsg msg

	sendMsg: (msg) ->
		console.log 'WRK resp >>> ', msg.toString()
		@sock.send.apply @sock, msg

exports.Worker = Worker

work = new Worker('WRK')
work.ready(process.argv[2])
