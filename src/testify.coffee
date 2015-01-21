EventEmitter = require("events").EventEmitter

TestContext = require("./test")


Testify =
  Context: require("./context")
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
    stack: true

  test: (name, fn) ->
    TestContext.options = Testify.options
    TestContext.reporter ||= (
      Testify.reporter || new Testify.ConsoleReporter(Testify.options)
    )
    suite = new TestContext(name, fn)
    Testify.count++
    suite.fsm.emitter.once "COMPLETE", ->
      Testify.count--
      if Testify.count == 0
        Testify.emitter.emit "done"
    suite.run()
    suite


module.exports = Testify
