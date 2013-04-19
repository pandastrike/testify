
class ConsoleReporter

  constructor: ->
    @suites = []

  add_suite: (suite) ->
    @suites.push suite

  report: ->
    for suite in @suites
      @report_suite(suite)

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


module.exports =
  ConsoleReporter: ConsoleReporter

