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
    @emitter.on "COMPLETE", => @report()
    fn = =>
      @report()

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

  report: ->
    if @_reported
      return
    else
      @_reported = true

    suite =
      name: "#{@name} (PASSED)"
      level: @level
      failed: @failed
      state: => @state()

    #if @state() != "COMPLETE"
      #@result "Testify exited in an incomplete state!", type: "incomplete"

    if @failed
      suite.name = "#{@name} (FAILED)"

    result = [suite]

    for context in @children
      context.collect(result)

    for test in result
      level = test.level

      if test.state() != "COMPLETE"
        @result "#{test.name} ( incomplete )", type: "incomplete", level: level
      else if test.failed == false
        @result test.name, type: "pass", level: level
      else if test.failed.constructor == String || test.failed.name == "AssertionError"
        @result "#{test.name} ( #{test.failed.toString()} )",
          type: "failure", level: level, stack: test.failed.stack
      else
        @result "#{test.name} ( #{test.failed.toString()} )",
          type: "error", level: level, stack: test.failed.stack

    if suite.failed && process.exit
      process.exit(1)

  collect: (array=[]) ->
    array.push(@)
    for context in @children
      context.collect(array)


