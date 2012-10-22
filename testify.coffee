assert = require "assert"
colors = require "colors"
EventEmitter = require("events").EventEmitter

module.exports = Testify =
  test: (name, fn) ->
    suite = new Context(name)
    fn(suite)
  emitter: new EventEmitter()
  count: 0
  once: (args...) ->
    Testify.emitter.once(args...)

process.on "exit", ->
  if Testify.count != 0
    console.log "#{Testify.count} async tests did not complete.".yellow

class Context
  constructor: (@name, @parent) ->
    @emitter = new EventEmitter
    if @parent
      @level = @parent.level + 1
    else
      @level = 0

    @finished = false
    @failed = false

    @children = []

    @assert = {}
    for name, method of assert
      @assert[name] = @wrap_assertion(name, method)

    if !@parent
      @emitter.once "done", =>
        process.nextTick =>
          console.log()
          @report()

  wrap_assertion: (name, fn) ->
    (args...) =>
      try fn(args...) catch error
        @fail(error)

  test: (description, fn) ->
    context = new Context(description, @)
    @children.push(context)
    context.emitter.once "done", =>
      @done()

    if fn.length == 0
      context.sync(fn)
      context.pass()
    else
      context.async(fn)

  sync: (fn) ->
    try fn() catch error
      @fail(error)

  async: (fn) ->
    Testify.count++
    @emitter.once "done", ->
      Testify.count--

    try
      fn(@)
    catch error
      @fail(error)

  pass: ->
    process.stdout.write ".".green
    @done()

  fail: (error) ->
    process.stdout.write "F".red
    @done()
    @propagate_failure(error)

  propagate_failure: (error) ->
    @failed = error
    @parent?.propagate_failure("subtest failures")

  done: () ->
    @finished = true
    flag = @children.every (child) ->
      child.finished || child.failed
    if flag
      @emitter.emit("done")

  report: ->
    suite =
      name: "Passed: #{@name}"
      level: @level
      failed: @failed
    if suite.failed
      suite.name = "Failed: #{@name}"
    result = [suite]

    for context in @children
      context.collect(result)

    for test in result
      level = test.level
      indent = ""
      indent = indent + "    " while level--

      if test.failed == false
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

