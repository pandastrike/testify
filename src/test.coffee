colors = require "colors"

Context = require("./context")

module.exports = class TestContext extends Context

  constructor: (args...) ->
    super(args...)
    @failed = false

  test: (description, work) ->
    @child(description, work)

  run: ->
    TestContext.reporter.add_suite(@)
    @_run()

  _run: (args...) ->
    @work(@)
    if @type == "sync" || @children.length > 0
      @event "end_of_block"
    else
      @event "childless"

  _run: ->
    @fsm.emitter.once "COMPLETE", =>
      clearTimeout(@timeout_id) if @timeout_id
      @timeout_id = undefined
    try
      @work(@) unless @failed
      if @type == "sync" || @children.length > 0
        @event "end_of_block"
        @status("pass", ".")
      else
        @event "childless" unless @failed
    catch error
      @fail(error)
      @event("end_of_block")

  event: (args...) ->
    try
      current = @fsm.state
      super(args...)
      #console.log
        #name: @name
        #current: current
        #event: args[0]
        #next: @fsm.state
    catch error
      if error.state == "COMPLETE" && error.event == "async_child"
        my_error = new Error "Asynchronous test created after parent had completed"
        my_error.stack = error.stack.split("\n").slice(5).join("\n")
        args[1].fail my_error
      else if error.state == "COMPLETE" && error.event == "sync_child"
        my_error = new Error "Synchronous test created after parent had completed"
        my_error.stack = error.stack.split("\n").slice(5).join("\n")
        args[1].fail my_error
      else
        throw error

  status: (type) ->
    @emitter.emit "status", type

  pass: ->
    # required because of the @timeout function
    # Possibly should be rolled into the state machine
    unless @failed
      @status("pass")
      @done()

  fail: (error) ->
    if error.constructor == String
      @status("failure")
      # create fake error with munged stack trace
      throwaway = new Error(error)
      message = error.toString()
      error =
        name: "AssertionError"
        stack: throwaway.stack.split("\n").slice(1).join("\n")
        toString: -> message
    else if error.name == "AssertionError"
      @status("failure")
    else
      @status("error")

    if @type == "async"
      @event("completion")

    @propagate_failure(error)

  timeout: (milliseconds, message) ->
    fn = =>
      @fail(message || "Timed out after #{milliseconds} milliseconds")
    @timeout_id = setTimeout(fn, milliseconds)


  propagate_failure: (error) ->
    @failed = error
    @parent?.propagate_failure("subtest failures")

