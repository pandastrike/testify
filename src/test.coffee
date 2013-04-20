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

  _run: ->
    @fsm.emitter.once "COMPLETE", =>
      clearTimeout(@timeout_id) if @timeout_id
      @timeout_id = undefined
    try
      super()
      if @type == "sync"
        @status("pass", ".")
    catch error
      @fail(error)
      @event("end_of_block")

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

