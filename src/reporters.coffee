
class ConsoleReporter

  constructor: ->
    #@suites = []

  add_suite: (suite) ->
    #@suites.push suite
    suite.emitter.on "child", (child) =>
      @hook(child)

    suite.fsm.emitter.on "COMPLETE", => @report_suite(suite)
    process.on "exit", => @report_suite(suite)

  hook: (child) ->
    child.emitter.on "child", (context) =>
      @hook(context)
    child.emitter.on "status", (status) =>
      @status(status)

  status: (type) ->
    if abbrev = @abbreviation[type]
      process.stdout.write(@colorize(type, abbrev))

  abbreviation:
    pass: "."
    incomplete: "I"
    failure: "F"
    error: "E"

  report_suite: (suite) ->
    if suite._reported
      return
    else
      suite._reported = true

    if suite.failed
      suite.name = "#{suite.name} (FAILED)"
    else
      suite.name = "#{suite.name} (PASSED)"

    result = []
    @collect(suite, result)

    for test in result
      level = test.level
      if test.state() != "COMPLETE"
        @result "#{test.name} ( incomplete )", type: "incomplete", level: level
      else if test.failed == false
        @result test.name, type: "pass", level: level
      else if test.failed.constructor == String || test.failed.name == "AssertionError"
        @result "#{test.name} ( #{test.failed.toString()} )",
          type: "failure", level: level, stack: test.failed.stack
      else
        @result "#{test.name} ( #{test.failed.toString()} )",
          type: "error", level: level, stack: test.failed.stack

    if suite.failed && process.exit
      process.exit(1)

  collect: (context, array=[]) ->
    array.push(context)
    for item in context.children
      @collect(item, array)

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
    if color = @color_map[type]
      string[color]
    else
      string

  color_map:
    pass: "green"
    incomplete: "magenta"
    failure: "red"
    error: "yellow"



class HTMLReporter

  constructor: (id) ->
    @root = document.getElementById(id)
    @suites = []

  add_suite: (suite) ->
    @suite_dom(suite)
    suite.emitter.on "child", (child) =>
      @handle_child(suite, child)
    suite.fsm.emitter.on "COMPLETE", => @report_suite(suite)
    setTimeout (=> @report_suite(suite)), 2000

  handle_child: (suite, child) ->
    @test_dom(child)

    child.emitter.on "child", (context) =>
      @handle_child(suite, context)
    child.emitter.on "status", (status) =>
      @status(suite, child, status)

  report_suite: (suite) ->
    if suite._reported
      return
    else
      suite._reported = true

    # We can iterate over the tests breadth-first because the hierarchical
    # structure was already arranged in the DOM.
    tests = @collect(suite)

    for test in tests
      level = test.level
      if test.state() != "COMPLETE"
        @result test, type: "incomplete"
      else if test.failed == false
        @result test, type: "pass"
      else if test.failed.constructor == String || test.failed.name == "AssertionError"
        @result test, type: "failure", stack: test.failed.stack
      else
        @result test, type: "error", stack: test.failed.stack

  collect: (context, array=[]) ->
    array.push(context)
    for item in context.children
      @collect(item, array)
    array


  suite_dom: (suite) ->
    suite._html =
      main: document.createElement("div")
      title: document.createElement("h3")
      tests: document.createElement("div")
    {main, tests, title} = suite._html
    main.classList.add "testify_suite"
    title.textContent = suite.name
    main.appendChild(title)
    main.appendChild(tests)
    @root.appendChild(main)
    
  test_dom: (test) ->
    test._html = {tests: document.createElement("p")}
    test._html.tests.textContent = test.name
    test.parent._html.tests.appendChild test._html.tests

  status: (suite, child, type) ->
    fn = =>
      element = child._html.tests
      element.classList.add type
    # fakery to make you feel like we're doing work
    setTimeout fn, 100

  result: (test, options) ->
    if test.children.length > 0
      element = test._html.tests
      if options.type
        element.classList.add options.type
        type_string = " (#{options.type})"



module.exports =
  ConsoleReporter: ConsoleReporter
  HTMLReporter: HTMLReporter

