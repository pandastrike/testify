EventEmitter = require("events").EventEmitter
microtime = require "microtime"
#Ascribe = require("ascribe/ascribe.coffee")

Testify = require "./testify"

module.exports =
  benchmark: (name, fn) ->
    new Benchmark(name, fn)

class Benchmark extends Testify.Turtle

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

    iterate = =>
      if ++count <= iterations
        console.log count
        @_run()
      else
        @emitter.emit "all_done", @results

    @emitter.on "COMPLETE", =>
      @event "reset"
      iterate()
    iterate()

  turtle_run: (args...) ->
    @work(@)
    @event "end"

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
      console.log "start:", name, value
      array = (@results[name] ||= [])
      array.push(value)

  record_end: (name, value) ->
    if @parent
      @parent.record_end(name, value)
    else
      console.log "finish:", name, value
      array = (@results[name] ||= [])
      index = array.length - 1
      array[index] = array[index] + value


  finish: ->
    #finish_time = microtime.now()
    #@record_end(@name, finish_time)
    @event "async_done"

  #done: (results) ->
    #finish_time = microtime.now()
    #times = results[@name]
    #index = times.length - 1
    ## the start time was added as a negative timestamp
    #times[index] = times[index] + finish_time


class Dataset
  constructor: (array) ->
    @data = array

  summarize: (args...) ->
    @data.summarize(args...)

  #draw: (options={}) ->
    #Ascribe.draw @data, options


