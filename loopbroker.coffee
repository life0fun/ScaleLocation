#!/usr/bin/env coffee
#

ctx = require 'zeromq'
EventEmitter = require('events').EventEmitter

class Node extends EventEmitter
	constructor: (@client) ->

class Broker extends Node
	constructor: (@client) ->  # inst var inside constructor need this prefix
		@cloudfe = ctx.createSocket('router')
		@cloudfe.identity = 'CFE'
		@cloudbe = ctx.createSocket('router')
		@cloudbe.identity = 'CBE'
		@localbe = ctx.createSocket('router')
		@localbe.identity = 'LBE'
		@bindEvent()

	ready: (me, peer) ->
		@_ID = me
		@_PEER = peer
		@cloudfe.identity = me+":CFE"
		@cloudfe.bind("ipc://router-" + me + ".ipc", (err) -> console.log err if err)

		@cloudbe.identity = me+":CBE"
		@cloudbe.connect("ipc://router-"+peer+".ipc")

		@localbe.identity = me+":LBE"
		@localbe.bind("ipc://router-wk-"+me+".ipc", (err) -> console.log err if err)

		console.log @_ID, ' ready...'
		self = this
		
		# do invoke the func with passed in arg
		tmot = do (self) =>
			() => # return a func with self closed over
				console.log 'send ready to peer broker'
				msg = []
				msg.push @_ID+' Ready'
				self.sendMsg @cloudbe, @_PEER+":CFE", msg
		#setTimeout tmot, 5000
	
	# prototype bind event
	bindEvent: ->
		@cloudfe.on 'message', (msg) =>
			# func created by => can access this property where they are defined.
			msg = @parseMsg arguments
			from = msg[0]
			@processReq(from, msg)

		@cloudbe.on 'message', (msg) =>
			# func created by => can access this property where they are defined.
			msg = @parseMsg arguments
			from = msg[0]
			@processRep(from, msg)

		@localbe.on 'message', (msg) =>
			# func created by => can access this property where they are defined.
			msg = @parseMsg arguments
			from = msg[0]
			data = msg[2]
			if data is 'ready'
				console.log msg.toString()
			else
				@processReq(from, msg)

		process.on 'SIGINT', () =>
			@cloudbe.close()
			@cloudfe.close()

	parseMsg: (args) ->
		msg = []
		for arg in args
			msg.push arg.toString()
		return msg
	
	# process msg sent to worker
	processReq: (from, msg) ->
		if @_ID is 'b1'
			# forward thru be, prepend be header
			#msg.unshift @_ID+':CBE'
			console.log @_ID, ':CFE <<< ', msg
			@sendMsg @cloudbe, @_PEER+":CFE", msg
		else
			console.log @_ID, ':CFE <<< ', msg
			from = msg.shift()  # get rid of env header if not forward anymore
			msg.push 'b2 done'
			@sendMsg @cloudfe, from, msg # reply back

	processRep: (from, msg) ->
		if @_ID is 'b1'
			console.log @_ID, ':CBE <<< ', msg
			from = msg.shift()
			#@sendMsg @cloudfe, @_PEER+":CBE", msg
			client = msg.shift()
			@sendMsg @cloudfe, client, msg
		else
			console.log @_ID, ':CBE done done <<< ', msg

	sendMsg: (sock, peer, msg) ->
		msg.unshift peer
		console.log @_ID + ' >>> ', peer, msg
		sock.send.apply sock, msg

exports.Broker = Broker

broker = new Broker()
broker.ready(process.argv[2], process.argv[3])
