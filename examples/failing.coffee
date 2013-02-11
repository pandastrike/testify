Testify = require "../testify"
assert = require "assert"

saneTimeout = (ms, fn) -> setTimeout(fn, ms)

Testify.test "IntentionalFail", (context0) ->

  context0.test "IntentionalFail sync fail", ->
    assert.ok(false)

  context0.test "IntentionalFail async", (context1) ->
    process.nextTick ->
      context1.fail("Intentional failure")

  context0.test "IntentionalFail async.mixed", (context1) ->
    saneTimeout 300, ->

      context1.test "IntentionalFail async.mixed sync", ->
        assert.ok(false)

      context1.test "IntentionalFail async.mixed async", (context2) ->
        saneTimeout 300, ->
          context2.fail("Intentional failure")

      context1.test "IntentionalFail async.mixed error", ->
        throw new Error("hello!")

  context0.test "IntentionalFail async.sync", (context1) ->
    saneTimeout 300, ->

      context1.test "IntentionalFail async.sync 1", ->
        assert.ok(false)

      context1.test "IntentionalFail async sync 2", ->
        assert.ok(false)

  context0.test "IntentionalFail async.async", (context1) ->
    saneTimeout 300, ->
      context1.test "IntentionalFail async.async async", (context2) ->
        saneTimeout 300, ->
          context2.fail("Intentional Failure")


  context0.test "IntentionalFail async.async", (context1) ->
    saneTimeout 300, ->
      context1.test "IntentionalFail async.async incomplete", (context2) ->
        saneTimeout 300, ->
          console.log "Work done, but no completion"


