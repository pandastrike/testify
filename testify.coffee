assert = require "assert"
colors = require "colors"
EventEmitter = require("events").EventEmitter

module.exports = Testify =
  test: (name, fn) ->
    context = new Context(name)
    context.emitter.once "done", ->
      console.log "suite done"
      process.nextTick ->
        context.report()
        Testify.emitter.emit("done")
    fn(context)
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
    @failed = false
    @children = []
    @assert = {}
    @finished = false
    for name, method of assert
      @assert[name] = @wrap_assertion(name, method)

  wrap_assertion: (name, fn) ->
    (args...) =>
      try
        fn(args...)
      catch error
        @fail(error)

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
      else if test.failed == true
        line = indent + "#{test.name} - subtest failures".red
      else if test.failed.constructor == String || test.failed.name == "AssertionError"
        line = indent + "#{test.name} - #{test.failed}".red
      else
        line = indent + "#{test.name} - #{test.failed}".yellow
      console.log(line)
    console.log()

  collect: (array=[]) ->
    array.push(@)
    for context in @children
      context.collect(array)

  test: (description, fn) ->
    context = new Context(description, @)
    @children.push(context)
    if fn.length == 0
      context.sync(fn)
    else
      context.async(fn)

  sync: (fn) ->
    try
      fn()
    catch error
      @fail(error)

  async: (fn) ->
    Testify.count++
    @emitter.once "done", ->
      Testify.count--

    try
      fn(@)
    catch error
      @fail(error)
      @done()

  fail: (error) ->
    @failed = error
    if @parent
      @parent.fail(true)
    @done()

  done: () ->
    @finished = true
    flag = @children.every (child) -> child.finished
    if flag
      @emitter.emit("done")
    else
      console.log @children

  pass: ->
    @done()

