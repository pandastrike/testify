colors = require "colors"

Context = require("./context")

module.exports = class TestContext extends Context

  result: (args...) ->
    @constructor.output.result(args...)

  status: (args...) ->
    @constructor.output.status(args...)

  constructor: (args...) ->
    super(args...)
    @failed = false

  test: (description, work) ->
    @child(description, work)

  run: ->
    TestContext.reporter.add_suite(@)
    @emitter.on "COMPLETE", => TestContext.reporter.report_suite(@)
    fn = => TestContext.reporter.report_suite(@)

    if process.on
      process.on "exit", fn
    else
      setTimeout fn, 4000
    @_run()

  _run: ->
    @emitter.on "COMPLETE", =>
      clearTimeout(@timeout_id) if @timeout_id
      @timeout_id = undefined
    try
      super()
      if @type == "sync"
        @status("pass", ".")
    catch error
      @fail(error)
      @event("end_of_block")

  pass: ->
    @status("pass", ".")
    @done()

  fail: (error) ->
    if error.constructor == String
      @status("failure", "F")
      # create fake error with munged stack trace
      throwaway = new Error(error)
      message = error.toString()
      error =
        name: "AssertionError"
        stack: throwaway.stack.split("\n").slice(1).join("\n")
        toString: -> message
    else if error.name == "AssertionError"
      @status("failure", "F")
    else
      @status("error", "E")

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

