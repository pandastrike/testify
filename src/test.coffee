colors = require "colors"

Context = require("./context")

colorize = (color, string) ->
  if TestContext.options.color
    string[color]
  else
    string

module.exports = class TestContext extends Context


  constructor: (args...) ->
    super(args...)
    @failed = false

  test: (description, work) ->
    @child(description, work)

  run: ->
    @emitter.on "COMPLETE", => @report()
    process.on "exit", =>
      if @state() != "COMPLETE"
        message = colorize("bold", "Testify exited in an incomplete state!")
        message = colorize("magenta", message)
        console.log message
        @report()
    @_run()

  _run: ->
    @emitter.on "COMPLETE", =>
      clearTimeout(@timeout_id) if @timeout_id
      @timeout_id = undefined
    try
      super()
      if @type == "sync"
        process.stdout.write(colorize("green", "."))
    catch error
      @fail(error)

  pass: ->
    process.stdout.write(colorize("green", "."))
    @done()

  fail: (error) ->
    if error.constructor == String
      process.stdout.write(colorize("red", "F"))
      # create fake error with munged stack trace
      throwaway = new Error(error)
      message = error.toString()
      error =
        name: "AssertionError"
        stack: throwaway.stack.split("\n").slice(1).join("\n")
        toString: -> message
    else if error.name == "AssertionError"
      process.stdout.write(colorize("red", "F"))
    else
      process.stdout.write(colorize("yellow", "E"))

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
    console.log()
    # NOTE: I can't remember why I'm constructing a pseudo context here. It's
    # possible the reason disappeared in the reworking around an FSM.
    suite =
      name: "Passed: #{@name}"
      level: @level
      failed: @failed
      state: => @state()

    if suite.failed
      suite.name = "Failed: #{@name}"
    result = [suite]

    for context in @children
      context.collect(result)

    for test in result
      level = test.level
      indent = ""
      indent = indent + "    " while level--

      if test.state() != "COMPLETE"
        line = colorize("magenta", indent + "Did not finish: #{test.name}")
      else if test.failed == false
        line = colorize("green", indent + test.name)
      else if test.failed.constructor == String || test.failed.name == "AssertionError"
        line = colorize("red", indent + "#{test.name} ( #{test.failed.toString()} )")
      else
        line = colorize("yellow", indent + "#{test.name} ( #{test.failed.toString()} )")
      console.log(line)
      if test.failed?.stack
        where = test.failed.stack.split("\n")[1]
        regex = /\((.*)\)/
        match = regex.exec(where)
        try
          console.log "#{indent}    #{match[1]}"
        catch error
          console.log "#{indent}    #{where.slice(7)}"

    console.log()
    if suite.failed
      process.exit(1)

  collect: (array=[]) ->
    array.push(@)
    for context in @children
      context.collect(array)


