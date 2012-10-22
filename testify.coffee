assert = require "assert"
colors = require "colors"
EventEmitter = require("events").EventEmitter

module.exports = Testify =
  test: (name, fn) ->
    suite = new Context(name)
    Testify.count++
    suite.run(fn)
    suite.emitter.once "done", ->
      Testify.count--
      if Testify.count == 0
        Testify.emitter.emit "done"

  emitter: new EventEmitter()
  count: 0
  once: (args...) ->
    Testify.emitter.once(args...)

class Context
  constructor: (@name, @parent) ->
    @emitter = new EventEmitter
    @children = []
    @finished = false
    @failed = false

    if @parent
      @level = @parent.level + 1
    else
      @level = 0
      # Top level contexts are responsible for reporting.
      process.on "exit", => @report()


  test: (description, fn) ->
    context = new Context(description, @)
    @children.push(context)
    context.emitter.once "done", => @done()
    context.run(fn)


  run: (fn) ->
    try
      fn(@)
      # A function which takes no args is a synchronous test.
      @pass() if fn.length == 0
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
    @done()
    @propagate_failure(error)

  propagate_failure: (error) ->
    @failed = error
    @parent?.propagate_failure("subtest failures")

  done: () ->
    flag = @children.every (child) ->
      child.finished || child.failed
    if flag && !@finished
      @finished = true
      @emitter.emit("done")

  report: ->
    console.log()
    suite =
      name: "Passed: #{@name}"
      level: @level
      failed: @failed
      finished: @finished
    if suite.failed
      suite.name = "Failed: #{@name}"
    result = [suite]

    for context in @children
      context.collect(result)

    for test in result
      level = test.level
      indent = ""
      indent = indent + "    " while level--

      if !test.finished
        line = "Did not finish: #{test.name}".magenta
      else if test.failed == false
        line = indent + test.name.green
      else if test.failed.constructor == String || test.failed.name == "AssertionError"
        line = indent + "#{test.name} ( #{test.failed} )".red
      else
        line = indent + "#{test.name} ( #{test.failed} )".yellow
      console.log(line)
    console.log()

  collect: (array=[]) ->
    array.push(@)
    for context in @children
      context.collect(array)

