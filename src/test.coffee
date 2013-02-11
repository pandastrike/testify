colors = require "colors"

Context = require("./context")

module.exports = class TestContext extends Context
  constructor: (args...) ->
    super(args...)
    @failed = false

  test: (description, work) ->
    @child(description, work)

  run: ->
    @emitter.on "COMPLETE", => @report()
    process.on "exit", =>
      if @state != "COMPLETE"
        console.log "Testify exited in an incomplete state!".bold.magenta
        @report()
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
    if error.constructor == String
      process.stdout.write "F".red
      # create fake error with munged stack trace
      throwaway = new Error(error)
      message = error.toString()
      error =
        name: "AssertionError"
        stack: throwaway.stack.split("\n").slice(1).join("\n")
        toString: -> message
    else if error.name == "AssertionError"
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
        line = indent + "Did not finish: #{test.name}".magenta
      else if test.failed == false
        line = indent + test.name.green
      else if test.failed.constructor == String || test.failed.name == "AssertionError"
        line = indent + "#{test.name} ( #{test.failed.toString()} )".red
      else
        line = indent + "#{test.name} ( #{test.failed.toString()} )".yellow
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


