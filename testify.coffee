assert = require "assert"
colors = require "colors"
EventEmitter = require("events").EventEmitter

module.exports = Testify =
  count: 0
  emitter: new EventEmitter()

  once: (args...) ->
    Testify.emitter.once(args...)

  test: (name, fn) ->
    suite = new TestContext(name, fn)
    Testify.count++
    suite.emitter.once "COMPLETE", ->
      Testify.count--
      if Testify.count == 0
        Testify.emitter.emit "done"
    suite.run()

Testify.Turtle = class Turtle
  constructor: (@name, @work, @parent) ->
    # A function which takes no args represents synchronous work.
    if @work.length == 0
      @type = "sync"
    else
      @type = "async"

    if @parent
      @level = @parent.level + 1
    else
      @level = 0

    @emitter = new EventEmitter()
    @children = []
    @state = "REST"

    @table =
      REST:
        sync_child: (args...) =>
          @add_sync(args...)
          "SYNC"
        async_child: (args...) =>
          @add_async(args...)
          "ASYNC"
        end: =>
          if @type == "sync"
            @complete()
            "COMPLETE"
          else
            "NO_CHILDREN"
      SYNC:
        sync_child: (args...) =>
          @add_sync(args...)
          "SYNC"
        async_child: (args...) =>
          @add_async(args...)
          "ASYNC"
        async_done: (args...) =>
          @complete()
          "COMPLETE"
        end: =>
          @complete()
          "COMPLETE"
      ASYNC:
        sync_child: (args...) =>
          @add_sync(args...)
          "ASYNC"
        async_child: (args...) =>
          @add_async(args...)
          "ASYNC"
        end: =>
          "ASYNC"
        async_done: (args...) =>
          if @is_done()
            @complete()
            "COMPLETE"
          else
            "ASYNC"
        timeout: =>
          "COMPLETE"
      NO_CHILDREN:
        sync_child: (args...) =>
          @add_sync(args...)
          "SYNC"
        async_child: (args...) =>
          @add_async(args...)
          "ASYNC"
        async_done: (args...) =>
          @complete()
          "COMPLETE"
        end: =>
          @complete()
          "COMPLETE"
        timeout: =>
          @complete()
          "COMPLETE"
      COMPLETE:
        async_done: (args...) =>
          "COMPLETE"

  is_done: ->
    flag = @children.every (child) -> child.state == "COMPLETE"

  complete: ->
    process.nextTick =>
      @parent?.event "async_done", @

  add_sync: (child) ->
    @children.push(child)

  add_async: (child) ->
    @children.push(child)

  event: (name, args...) ->
    current_state = @state
    transition = @table[@state][name]
    if !transition
      throw new Error("State '#{@state}' has no transition for event '#{name}'")
    else
      @state = transition(args...)
    if @state != current_state
      @emitter.emit @state


  child: (description, work) ->
    child = new @constructor(description, work, @)
    if child.type == "sync"
      @event "sync_child", child
    else if child.type == "async"
      @event "async_child", child
    else
      throw new Error("bad type: #{child.type}")
    child._run()


  _run: (args...) ->
    @work(@)
    @event "end"

  done: ->
    @event "async_done"



class TestContext extends Turtle
  constructor: (args...) ->
    super(args...)
    @failed = false

  test: (description, work) ->
    @child(description, work)

  run: ->
    @emitter.on "COMPLETE", => @report()
    @_run()

  _run: ->
    try
      super()
      if @type == "sync"
        process.stdout.write ".".green
    catch error
      @fail(error)

  pass: ->
    process.stdout.write ".".green
    @done()

  fail: (error) ->
    if error.name == "AssertionError" || error.constructor == String
      process.stdout.write "F".red
    else
      process.stdout.write "E".yellow
    @event("end")
    @propagate_failure(error)

  propagate_failure: (error) ->
    @failed = error
    @parent?.propagate_failure("subtest failures")

  report: ->
    console.log()
    suite =
      name: "Passed: #{@name}"
      level: @level
      failed: @failed
      state: @state

    if suite.failed
      suite.name = "Failed: #{@name}"
    result = [suite]

    for context in @children
      context.collect(result)

    for test in result
      level = test.level
      indent = ""
      indent = indent + "    " while level--

      if test.state != "COMPLETE"
        line = "Did not finish: #{test.name}".magenta
      else if test.failed == false
        line = indent + test.name.green
      else if test.failed.constructor == String || test.failed.name == "AssertionError"
        line = indent + "#{test.name} ( #{test.failed} )".red
      else
        line = indent + "#{test.name} ( #{test.failed} )".yellow
        console.log test.failed.stack
      console.log(line)
    console.log()

  collect: (array=[]) ->
    array.push(@)
    for context in @children
      context.collect(array)

