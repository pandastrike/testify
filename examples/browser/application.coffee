
Testify = require("testify")
assert = require("assert")
saneTimeout = (ms, fn) -> setTimeout(fn, ms)

window.onload = ->

  Testify.reporter = new Testify.DOMReporter("testify", 1000)

  Testify.test "These should all pass", (context0) ->

    context0.test "passing sync 1", ->
      assert.ok(true)

    context0.test "passing async", (context1) ->
      saneTimeout 0, ->
        context1.pass()

    context0.test "passing async.mixed", (context1) ->
      saneTimeout 400, ->

        context1.test "passing async.mixed sync", ->
          assert.ok(true)

        context1.test "passing async.mixed async", (context2) ->
          saneTimeout 400, ->
            context2.pass()

    context0.test "passing async.sync", (context1) ->
      saneTimeout 400, ->

        context1.test "passing async.sync 1", ->
          assert.ok(true)

        context1.test "passing async sync 2", ->
          assert.ok(true)

    context0.test "passing async.async", (context1) ->
      saneTimeout 400, ->
        context1.test "passing async.async async", (context2) ->
          saneTimeout 400, ->
            context2.pass()


  Testify.test "IntentionalFail", (context) ->

    context.test "IntentionalFail sync fail", ->
      assert.ok(false)

    context.test "IntentionalFail async", (context) ->
      saneTimeout 0, ->
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
            console.log "\nWork done, but no completion for this context"

    context.test "Timing out intentionally", (context) ->
      context.test "forced timeout", (context) ->
        context.timeout(3 * 100)
        saneTimeout 6 * 100, ->
          # All of the tests in this file are supposed to fail in some way.
          # Thus if we see green in the output, the failure failed.
          context.pass()
      context.test "cancelled timeout", (context) ->
        saneTimeout 2 * 100, ->
          context.fail("Intentional Failure")
