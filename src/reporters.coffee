colors = require "colors"

class ConsoleReporter

  constructor: ({@color, @stack})->
    @counts =
      passed: 0
      failed: 0
      errored: 0
      incomplete: 0
    process.on "exit", =>
      @summarize()
      if @counts.failed > 0
        process.exit(1)

  summarize: ->
    summary = [
      @colorize "pass", "Passed: #{@counts.passed}"
    ]
    if @counts.failed > 0
      summary.push @colorize "failure", "Failed: #{@counts.failed}"
    if @counts.errored > 0
      summary.push @colorize "error", "Errored: #{@counts.errored}"
    if @counts.incomplete > 0
      summary.push @colorize "incomplete", "Incomplete: #{@counts.errored}"

    console.log()
    console.log summary.join("    ")

  add_suite: (suite) ->
    suite.emitter.on "child", (child) =>
      @hook(child)

    suite.fsm.emitter.on "COMPLETE", =>
      process.nextTick (=> @report_suite(suite))

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
        @counts.incomplete++
      else if test.failed == false
        @result test.name, type: "pass", level: level
        @counts.passed++
      else if test.failed.constructor == String || test.failed.name == "AssertionError"
        if test.failed == "subtest failures"
          @result "#{test.name} ( #{test.failed.toString()} )",
            type: "container", level: level, stack: test.failed.stack
        else
          @result "#{test.name} ( #{test.failed.toString()} )",
            type: "failure", level: level, stack: test.failed.stack
          @counts.failed++
      else
        @result "#{test.name} ( #{test.failed.toString()} )",
          type: "error", level: level, stack: test.failed.stack
        @counts.errored++

    #if suite.failed && process.exit
      #process.exit(1)

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

    space = ""
    if level = options.level
      space = space + "    " while level--
      string = space + string
    console.log(string)

    # output first line of stack trace
    if @stack && options.stack
      where = options.stack.split("\n")[1]
      regex = /\((.*)\)/
      match = regex.exec(where)
      try
        console.log space + match[1]
      catch error
        console.log space + where.slice(7)

  colorize: (type, string) ->
    if @color && color = @color_map[type]
      if typeof(color) == "string"
        string[color]
      else
        for value in color
          string = string[value]
        string
    else
      string

  color_map:
    pass: "green"
    incomplete: "magenta"
    failure: ["red", "underline"]
    error: "yellow"
    container: ["red"]



class DOMReporter

  constructor: (id, options={}) ->
    @timeout = options.timeout || 2000
    @root = document.getElementById(id)
    @suites = []

  add_suite: (suite) ->
    @suite_dom(suite)
    suite.emitter.on "child", (child) =>
      @handle_child(suite, child)
    suite.fsm.emitter.on "COMPLETE", => @report_suite(suite)
    setTimeout (=> @report_suite(suite)), @timeout

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

    if suite.state() != "COMPLETE"
      suite._html.title.classList.add "incomplete"
    else if suite.failed == false
      suite._html.title.classList.add "pass"
    else
      suite._html.title.classList.add "failed"

    # We can iterate over the tests breadth-first because the hierarchical
    # structure was already arranged in the DOM.
    tests = []
    for test in suite.children
      @collect(test, tests)

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
      tests: document.createElement("ul")
    {main, tests, title} = suite._html
    main.classList.add "testify_suite"
    title.textContent = suite.name
    main.appendChild(title)
    main.appendChild(tests)
    @root.appendChild(main)
    
  test_dom: (test) ->
    test._html =
      name: document.createElement("li")

    test._html.name.classList.add("testify_test")
    span = document.createElement("span")
    span.classList.add("testify_test_name")
    span.textContent = test.name
    test._html.name.appendChild(span)
    if test.parent._html.tests
    else
      tests = test.parent._html.tests = document.createElement("ul")
      test.parent._html.name.appendChild(tests)
    test.parent._html.tests.appendChild test._html.name

  status: (suite, test, type) ->
    fn = =>
      element = test._html.name
      span = element.children[0]
      span.classList.add type
      if type == "failure" || type == "error"
        span.textContent = span.textContent + " (#{test.failed.toString()})"

        stacky = document.createElement("pre")
        where = test.failed.stack.split("\n")[1]
        regex = /\((.*)\)/
        match = regex.exec(where)
        try
          stacky.textContent = match[1]
        catch error
          stacky.textContent = where.slice(7)

        stacky.classList.add "stack"
        element.insertBefore(stacky, span.nextSibling)
      else if type == "incomplete"
        span.textContent = span.textContent + " (incomplete)"
    # fakery to make you feel like we're doing work
    setTimeout fn, 50

  result: (test, options) ->
    if test.children.length > 0 || options.type == "incomplete"
      element = test._html.name
      if options.type
        span = element.children[0]
        span.classList.add options.type
        type_string = " (#{options.type})"
        if options.type == "failure"
          span.textContent = span.textContent + " (#{test.failed.toString()})"
        else if options.type == "incomplete"
          span.textContent = span.textContent + " (incomplete)"



module.exports =
  ConsoleReporter: ConsoleReporter
  DOMReporter: DOMReporter

