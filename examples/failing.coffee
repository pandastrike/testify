Testify = require "../testify"
assert = require "assert"

saneTimeout = (ms, fn) -> setTimeout(fn, ms)

Testify.test "allfail", (context0) ->

  context0.test "allfail sync fail", ->
    assert.ok(false)

  context0.test "allfail async", (context1) ->
    process.nextTick ->
      context1.fail("Intentional failure")

  context0.test "allfail async.mixed", (context1) ->
    saneTimeout 300, ->

      context1.test "allfail async.mixed sync", ->
        assert.ok(false)

      context1.test "allfail async.mixed async", (context2) ->
        saneTimeout 300, ->
          context2.fail("Intentional failure")

      context1.test "allfail async.mixed error", ->
        throw new Error("hello!")

  context0.test "allfail async.sync", (context1) ->
    saneTimeout 300, ->

      context1.test "allfail async.sync 1", ->
        assert.ok(false)

      context1.test "allfail async sync 2", ->
        assert.ok(false)

  context0.test "allfail async.async", (context1) ->
    saneTimeout 300, ->
      context1.test "allfail async.async async", (context2) ->
        saneTimeout 300, ->
          context2.fail("Intentional Failure")



