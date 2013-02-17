Testify = require "../src/testify"
assert = require "assert"

saneTimeout = (ms, fn) -> setTimeout(fn, ms)

Testify.test "context.timeout", (context) ->

  context.test "cancelled timeout", (context) ->
    context.timeout(8 * 1000)
    saneTimeout 1 * 1000, ->
      context.pass("context.timeout did not cancel the test")

  context.test "forced timeout", (context) ->
    context.timeout(1 * 1000)
    saneTimeout 20 * 1000, ->
      # This example should fail.  Failure to fail is a fail.
      context.pass()

  context.test "forced timeout with custom error", (context) ->
    context.timeout(1 * 1000, "I am custom error")
    saneTimeout 20 * 1000, ->
      # This example should fail.  Failure to fail is a fail.
      context.pass()
