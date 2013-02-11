EventEmitter = require("events").EventEmitter
microtime = require "microtime"
require "./statistics"
#Ascribe = require("ascribe/ascribe.coffee")

Testify = require "./testify"

module.exports =
  benchmark: (name, fn) ->
    new Benchmark(name, fn)

class Benchmark extends Testify.Context

  constructor: (args...) ->
    @results = {}
    super(args...)

  measure: (name, work) ->
    @child(name, work)

  run: (options, callback) ->
    {iterations} = options
    count = 0
    results = {}

    suite_start = microtime.now()
    @emitter.on "all_done", (results) =>
      finish_time = microtime.now()
      out =
        runtime: finish_time - suite_start
        data: data = {}
      for name, values of results
        data[name] = new Dataset(values)
      if callback
        callback(out)

    process.stdout.write("Iteration: ")
    iterate = =>
      if ++count <= iterations
        if count % 5 == 0 || count == 1
          process.stdout.write(count.toString())
        else
          process.stdout.write(".")
        @_run()
      else
        process.stdout.write("\n")
        @emitter.emit "all_done", @results

    @emitter.on "COMPLETE", =>
      @event "reset"
      iterate()
    iterate()


  _run: ->
    @record_start(@name, -microtime.now())
    @emitter.once "COMPLETE", =>
      finish_time = microtime.now()
      @record_end(@name, finish_time)
    super()

  record_start: (name, value) ->
    if @parent
      @parent.record_start(name, value)
    else
      if name != @name
        #console.log "start:", name, value
        array = (@results[name] ||= [])
        array.push(value)

  record_end: (name, value) ->
    if @parent
      @parent.record_end(name, value)
    else
      if name != @name
        #console.log "finish:", name, value
        array = (@results[name] ||= [])
        index = array.length - 1
        array[index] = array[index] + value

  finish: ->
    @event "child_done"



class Dataset
  constructor: (array) ->
    @data = array

  summarize: (args...) ->
    @data.summarize(args...)

  #draw: (options={}) ->
    #Ascribe.draw @data, options


