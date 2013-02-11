colors = require "colors"
EventEmitter = require("events").EventEmitter

Context = require("./context")
TestContext = require("./test")
Benchmark = require("./benchmark")

module.exports = Testify =
  count: 0
  emitter: new EventEmitter()

  once: (args...) ->
    Testify.emitter.once(args...)
  # set at runtime to modify behavior
  options:
    color: true

  test: (name, fn) ->
    TestContext.options = Testify.options
    suite = new TestContext(name, fn)
    Testify.count++
    suite.emitter.once "COMPLETE", ->
      Testify.count--
      if Testify.count == 0
        Testify.emitter.emit "done"
    suite.run()

  benchmark: (name, fn) ->
    new Benchmark(name, fn)


