assert = require "assert"
colors = require "colors"
EventEmitter = require("events").EventEmitter

module.exports = Testify =
  count: 0
  emitter: new EventEmitter()

  once: (args...) ->
    Testify.emitter.once(args...)

  test: (name, fn) ->
    suite = new TestContext(name, fn)
    Testify.count++
    suite.emitter.once "done", ->
      Testify.count--
      if Testify.count == 0
        Testify.emitter.emit "done"
    suite.run()

Testify.Turtle = class Turtle
  idcounter = 0
  constructor: (@name, @work, @parent) ->
    @id = idcounter++
    @emitter = new EventEmitter
    @children = []
    @finished = false

    if @parent
      @level = @parent.level + 1
    else
      @level = 0

  child: (description, work) ->
    child = new @constructor(description, work, @)
    @children.push(child)
    child.emitter.on "sync", (args...) =>
      console.log "#{@name}:", "sync event:", child.name
      @async(args...)
    child.emitter.on "async", (args...) =>
      console.log "#{@name}:", "async event:", child.name
      @emitter.emit "done"
      #@done(args...)
    child._run(work)

  _run: (args...) ->
    @work(@)
    # A function which takes no args represents synchronous work.
    if @work.length == 0
      @sync(args...)
    else
      @async(args...)


  #done: (args...) ->
    #all = @children.every (child) -> child.finished
    #if all && !@finished
      #@finished = true
      #@emitter.emit("done", args...)

  async: (args...) ->
    all = @children.every (child) -> child.finished
    if all
      @finished = true
      @emitter.emit "async", args...
    else
      setTimeout (=> @async(args...)), 1000

  sync: (args...) ->
    @finished = true
    @emitter.emit "sync", args...

class TestContext extends Turtle
  constructor: (args...) ->
    super(args...)
    @failed = false

  test: (description, work) ->
    @child(description, work)

  run: ->
    #process.on "exit", => @report()
    @emitter.on "done", =>
      @report()
    @_run()

  _run: ->
    try
      super()
    catch error
      @fail(error)

  sync: (args...) ->
    @pass()

  pass: ->
    #process.stdout.write ".".green
    @finished = true
    @emitter.emit "sync"

  fail: (error) ->
    if error.name == "AssertionError" || error.constructor == String
      process.stdout.write "F".red
    else
      process.stdout.write "E".yellow
    @propagate_failure(error)
    @emitter.emit "sync"
    #@done()

  propagate_failure: (error) ->
    # TODO: can this be eventified?
    @failed = error
    @parent?.propagate_failure("subtest failures")

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

