colors = require "colors"
EventEmitter = require("events").EventEmitter

module.exports = Testify =
  test: (name, fn) ->
    if fn
      context = new Context(name)
      Testify.count++
      context.emitter.once "done", ->
        Testify.count--
        context.report()
        if Testify.count == 0
          Testify.emitter.emit("done")
      fn(context)
    else
      process.once "exit", ->
        console.log "Unimplemented: #{name}".cyan
  count: 0
  emitter: new EventEmitter()
  once: (args...) ->
    Testify.emitter.once(args...)

process.on "exit", ->
  if Testify.count != 0
    console.log "Not all tests ran".yellow

class Context
  constructor: (@name, @parent) ->
    if @parent
      @level = @parent.level + 1
    else
      @level = 0

    @failed = false
    @children = []

    @emitter = new EventEmitter

  report: ->
    console.log()
    top_level =
      name: "Passed: #{@name}"
      level: @level
      failed: @failed
    if top_level.failed
      top_level.name = "Failed: #{@name}"
    result = [top_level]

    for context in @children
      context.collect_output(result)

    for test in result
      level = test.level
      indent = ""
      indent = indent + "    " while level--

      if test.failed == false
        console.log indent + test.name.green
      else if test.failed == true
        console.log indent + "#{test.name} - subtest/s failed".red
      else if test.failed.name == "AssertionError"
        console.log indent + "#{test.name} - #{test.failed}".red
      else
        console.log indent + "#{test.name} - #{test.failed}".yellow



  collect_output: (array=[]) ->
    array.push
      level: @level
      name: @name
      failed: @failed
    for context in @children
      context.collect_output(array)



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
    @emitter.once "done", =>
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

  done: () ->
    @emitter.emit("done")

  success: (description) ->
    console.log description.green

  assert: require("assert")

  pass: (description) ->
    @emitter.once "done", => @success("  * " + description)

  #fail: (description, error) ->
    #if !error
      #console.log "Failed: #{@name}\n  => #{description}".red.bold
    #else
      #if error.constructor == String || error.name == "AssertionError"
        #console.log "Failed: #{@name}\n  * #{description} => #{error}".red.bold
      #else
        #console.log colors.yellow("Error: '#{description}' => #{error}")
      # split,slice to remove the error message from the stack trace
      #if error.stack
        #console.log colors.white(error.stack.split("\n").slice(1).join("\n"))

  #fail: (error) ->
    #if error.constructor == String || error.name == "AssertionError"
      #console.log "Failed: #{@name}\n => #{error}".red.bold
    #else
      #console.log colors.yellow("Error: '#{description}' => #{error}")

