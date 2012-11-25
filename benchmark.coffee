EventEmitter = require("events").EventEmitter
microtime = require "microtime"
#Ascribe = require("ascribe/ascribe.coffee")

Testify = require "./testify"

module.exports =
  benchmark: (name, fn) ->
    new Benchmark(name, fn)

class Benchmark extends Testify.Turtle

  constructor: (args...) ->
    super(args...)

  measure: (name, work) ->
    @child(name, work)

  run: (options, callback) ->
    {iterations} = options
    count = 0
    results = {}

    suite_start = microtime.now()
    @emitter.once "all_done", (results) =>
      finish_time = microtime.now()
      out =
        runtime: finish_time - suite_start
        data: {}
      for name, values of results
        data[name] = new Dataset(values)
      callback(out)

    iterate = =>
      if ++count < iterations
        @_run(results)
      else
        @emitter.emit "all_done"

    @emitter.on "done", iterate
    iterate()

  turtle_run: (args...) ->
    @work(@)
    if @work.length == 0
      @sync(args...)
    else
      @async(args...)

  _run: (results) ->
    array = (results[@name] ||= [])
    array.push(-microtime.now())
    super(results)

    #@work(@)
    #if @work.length == 0
      #@sync(args...)
    #else
      #@async(args...)

    #else
      #x = 0
      #for child in @children
        #child.once "done", =>
          #if ++x = @children.length
            #@done(results)
        #child.one_run(results)


  finish: ->
    finish_time = microtime.now()
    # do something with time
    #@done()

  done: (results) ->
    finish_time = microtime.now()
    times = results[@name]
    index = times.length - 1
    # the start time was added as a negative timestamp
    times[index] = times[index] + finish_time
    @emitter.emit "done", results


class Dataset
  constructor: (array) ->
    @data = array

  summarize: (args...) ->
    @data.summarize(args...)

  #draw: (options={}) ->
    #Ascribe.draw @data, options


