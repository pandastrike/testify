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

# A base class for creating nested contexts. I extracted this to try and
# use it for benchmarking, but haven't gotten the benchmarker baked yet.
Testify.Context = class Context
  constructor: (@name, @work, @parent) ->
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
    child.emitter.once "done", (args...) => @done(args...)
    child._run(work)

  _run: (args...) ->
    @work(@)
    # A function which takes no args represents synchronous work.
    if @work.length == 0
      @sync(args...)
    else
      @async(args...)

  async: (args...) ->

  sync: (args...) ->
    @done(args...)

  done: (args...) ->
    all = @children.every (child) -> child.finished
    if all && !@finished
      @finished = true
      @emitter.emit("done", args...)


class TestContext extends Context
  constructor: (args...) ->
    super(args...)
    @failed = false

  test: (description, work) ->
    @child(description, work)

  run: ->
    process.on "exit", => @report()
    @_run()

  _run: ->
    try
      super()
    catch error
      @fail(error)

  sync: (args...) ->
    @pass()

  async: (args...) ->

  pass: ->
    process.stdout.write ".".green
    @done()

  fail: (error) ->
    if error.constructor == String
      process.stdout.write "F".red
      # create fake error
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
    @propagate_failure(error)
    @done()

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
        line = indent + "#{test.name} ( #{test.failed.toString()} )".red
      else
        line = indent + "#{test.name} ( #{test.failed.toString()} )".yellow
      console.log(line)
      if test.failed?.stack
        where = test.failed.stack.split("\n")[1]
        regex = /\((.*)\)/
        match = regex.exec(where)
        console.log "#{indent}    #{match[1]}"

    console.log()
    if suite.failed
      process.exit(1)

  collect: (array=[]) ->
    array.push(@)
    for context in @children
      context.collect(array)

