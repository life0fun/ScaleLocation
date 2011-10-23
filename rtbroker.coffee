#!/usr/bin/env coffee
#

# msg exchange between rt-rt, just prepend rt addr, msg = [addr, body]
# msg exchange betwee rt-req, msg = [addr, delim, body]
# XXX when sending msg from router to req sock, you must have to have '' as delimiter.
# req sock is relying on that to apart msg body

ctx = require 'zmq'
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
		@_WORKERS = []
		@bindEvent()

	# factory pattern
	@create: (name, option) ->
		bk = new Broker(name)
		if typeof options is 'object'
			for own key, value of options
				bk[key] = value
		return bk

	ready: (me, peer) ->
		@_ID = me
		@_PEER = peer
		@cloudfe.identity = me+":CFE"
		@cloudfe.bind("ipc://router-" + me + ".ipc", (err) -> console.log err if err)

		@localbe.identity = me+":LBE"
		@localbe.bind("ipc://router-wk-"+me+".ipc", (err) -> console.log err if err)

		@cloudbe.identity = me+":CBE"
		@cloudbe.connect("ipc://router-"+peer+".ipc")

		console.log @_ID, ' ready...'
		self = this
		
		# do invoke the func with passed in arg
		tmot = do (self) =>
			() => # return a func with self closed over
				console.log 'send ready to peer broker'
				msg = []
				msg.push 'ready'
				self.sendMsg @cloudbe, @_PEER+":CFE", msg
		#setTimeout tmot, 2000
	
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

		@localbe.on 'message', (msgs) =>
			# func created by => can access this property where they are defined.
			msg = @parseMsg arguments
			from = msg[0]
			@processWk(from, msg)

		process.on 'SIGINT', () =>
			@cloudbe.close()
			@cloudfe.close()

	parseMsg: (args) ->
		msg = []
		for arg in args
			msg.push arg.toString()
		return msg
	
	# process request from Peer_BE -> this_FE
	processReq: (from, msg) ->
		if @_ID is 'b1'
			console.log @_ID, ':CFE <<< ', msg
			@sendMsg @cloudbe, @_PEER+":CFE", msg
		else
			console.log @_ID, ':CFE <<< ', msg
			# pick up a least loaded worked to sent the task.
			# when sending to req, need '' delimiter
			msg.unshift('')
			@sendMsg @localbe, @_WORKERS[0], msg # send the entire msg to worker 

	# process response from Peer_FE -> this_BE
	processRep: (from, msg) ->
		if @_ID is 'b1'
			console.log @_ID, ':CBE <<< ', msg
			from = msg.shift() # resp from peer router, just get rid of the send addr 

			client = msg.shift()  # now needs to send back to req client.
			@sendMsg @cloudfe, client, msg
		else
			console.log @_ID, ':CBE done done <<< ', msg

	processWk: (from, msg) ->
		data = msg[2]
		if data is 'ready'
			@_WORKERS.push from  # remember the worker addr
			console.log msg.toString()
			#@sendMsg @localbe, from, ['', 'reply'] # req recver needs '' delimiter
		else
			from = msg.shift()
			delim = msg.shift()
			nexthop = msg.shift()
			@sendMsg @cloudfe, nexthop, msg  # sent thru cloud fe, cloud be will get it.

	sendMsg: (sock, peer, msg) -> # when msg recv, msg[0] = send's addr, no need to prepend at sender side
		msg.unshift peer  # as we are using apply, need to prepend recver's addr
		console.log @_ID + ' >>> ', peer, msg
		sock.send.apply sock, msg

exports.create = Broker.create

broker = new Broker()
broker.ready(process.argv[2], process.argv[3])
