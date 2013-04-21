colors = require "colors"
EventEmitter = require("events").EventEmitter

Context = require("./context")


class TestOutput

  constructor: ->
    console.log()

  status: (type, string) ->
    process.stdout.write(@colorize(type, string))

  result: (string, options={}) ->
    if !@_receiving_results
      console.log()
      @_receiving_results = true

    if options.type
      string = @colorize(options.type, string)
    if level = options.level
      space = ""
      space = space + "    " while level--
      string = space + string
    console.log(string)

    # output first line of stack trace
    if options.stack
      where = options.stack.split("\n")[1]
      regex = /\((.*)\)/
      match = regex.exec(where)
      try
        console.log space + match[1]
      catch error
        console.log space + where.slice(7)

  colorize: (type, string) ->
    if Testify.options.color && color = @color_map[type]
      string[color]
    else
      string

  color_map:
    pass: "green"
    incomplete: "magenta"
    failure: "red"
    error: "yellow"


TestContext = require("./test")
#TestContext.output = new TestOutput()


Testify =
  ConsoleReporter: require("./reporters").ConsoleReporter
  DOMReporter: require("./reporters").DOMReporter
  TestContext: TestContext
  count: 0
  emitter: new EventEmitter()

  once: (args...) ->
    Testify.emitter.once(args...)
  # set at runtime to modify behavior
  options:
    color: true

  test: (name, fn) ->
    TestContext.options = Testify.options
    TestContext.reporter = Testify.reporter || new Testify.ConsoleReporter()
    suite = new TestContext(name, fn)
    Testify.count++
    suite.emitter.once "COMPLETE", ->
      Testify.count--
      if Testify.count == 0
        Testify.emitter.emit "done"
    suite.run()

  benchmark: (name, fn) ->
    Benchmark = require("./benchmark")
    new Benchmark(name, fn)


module.exports = Testify
