#!/usr/bin/env coffee
#
# CLI = require('rtclient')
# client = CLI.create('CLI')
# client.ready()

EventEmitter = require('events').EventEmitter
path = require 'path'
ctx = require 'zmq'

class Node extends EventEmitter
	constructor: (@_ID) ->

class Client extends Node
	constructor: (@_ID) ->
		@sock = ctx.createSocket('router')
		#@sock = ctx.createSocket('dealer')
		@sock.identity = @_ID
		@bindEvent()

	# factory pattern
	@create: (name, option) ->
		cli = new Client(name)
		if typeof options is 'object'
			for own key, value of options
				cli[key] = value
		return cli

	ready: (host, port) ->
		host ?= 'localhost'
		port ?= 5555
		@sock.connect("tcp://"+host+":"+port)
		console.log @_ID + ' client connected to ' + host
		self = this
		tof = do (self) ->
			-> # return a func, wrap with the passed in sock
				self.sendMsg 'SRV', [ 'hello from cli']
		setTimeout tof, 1000

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
		from = msg.shift()
		console.log 'client recvd rep <<< ', msg.toString()
		@sendMsg from, msg

	sendMsg: (addr, msg) ->
		msg.unshift addr  #prepend dest addr first, do not need this if sock is dealer.
		console.log 'cli >>> ', msg
		@sock.send.apply @sock, msg

exports.create = Client.create
client = new Client('CLI')
client.ready(process.argv[2], process.argv[3])
