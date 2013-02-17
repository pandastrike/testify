Testify = require "../src/testify"
assert = require "assert"

saneTimeout = (ms, fn) -> setTimeout(fn, ms)

Testify.test "IntentionalFail", (context) ->

  context.test "IntentionalFail sync fail", ->
    assert.ok(false)

  context.test "IntentionalFail async", (context) ->
    process.nextTick ->
      context.fail("Intentional failure")

  context.test "IntentionalFail async.mixed", (context) ->
    saneTimeout 300, ->

      context.test "IntentionalFail async.mixed sync", ->
        assert.ok(false)

      context.test "IntentionalFail async.mixed async", (context) ->
        saneTimeout 300, ->
          context.fail("Intentional failure")

      context.test "IntentionalFail async.mixed error", ->
        throw new Error("hello!")

  context.test "IntentionalFail async.sync", (context) ->
    saneTimeout 300, ->

      context.test "IntentionalFail async.sync 1", ->
        assert.ok(false)

      context.test "IntentionalFail async sync 2", ->
        assert.ok(false)

  context.test "IntentionalFail async.async", (context) ->
    saneTimeout 300, ->
      context.test "IntentionalFail async.async async", (context) ->
        saneTimeout 300, ->
          context.fail("Intentional Failure")


  context.test "IntentionalFail async.async", (context) ->
    saneTimeout 300, ->
      context.test "IntentionalFail async.async incomplete", (context) ->
        saneTimeout 300, ->
          console.log "\nWork done, but no completion"

  context.test "Timing out intentionally", (context) ->
    context.test "forced timeout", (context) ->
      context.timeout(3 * 1000)
      saneTimeout 6 * 1000, ->
        # All of the tests in this file are supposed to fail in some way.
        # Thus if we see green in the output, the failure failed.
        context.pass()
    context.test "cancelled timeout", (context) ->
      saneTimeout 2 * 1000, ->
        context.fail("Intentional Failure")

