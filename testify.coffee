colors = require "colors"
EventEmitter = require("events").EventEmitter

module.exports = testify = (name, fn) ->
  if fn
    context = new Context(name)
    testify.count++
    context.emitter.on "done", ->
      testify.count--
      context.success("Passed: " + name)
      if testify.count == 0
        testify.emitter.emit("done")
    fn(context)
  else
    process.on "exit", ->
      console.log "Unimplemented: #{name}".cyan

testify.count = 0
testify.emitter = new EventEmitter()
testify.on = (args...) ->
  testify.emitter.on(args...)


class Context
  constructor: (@name, @parent) ->
    @emitter = new EventEmitter
    @assertions = {}

  test: (description, fn) ->
    try
      fn()
      @emitter.on "done", => @success("  * " + description)
    catch error
      @emitter.on "done", => @fail(description, error)

  done: () ->
    @emitter.emit("done")

  success: (name) ->
    console.log name.green

  assert: require("assert")

  pass: (description) ->
    @emitter.on "done", => @success("  * " + description)

  fail: (description, error) ->
    if !error
      console.log "Failed: #{@name}\n  => #{description}".red.bold
    else
      if error.constructor == String || error.name == "AssertionError"
        console.log "Failed: #{@name}\n  * #{description} => #{error}".red.bold
      else
        console.log colors.yellow("Error: '#{description}' => #{error}")
      # split,slice to remove the error message from the stack trace
      if error.stack
        console.log colors.white(error.stack.split("\n").slice(1).join("\n"))

