Testify = require "../src/testify"
assert = require "assert"

saneTimeout = (ms, fn) -> setTimeout(fn, ms)

Testify.test "passing", (context0) ->

  context0.test "passing sync 1", ->
    assert.ok(true)

  context0.test "passing async", (context1) ->
    process.nextTick ->
      context1.pass()

  context0.test "passing async.mixed", (context1) ->
    saneTimeout 300, ->

      context1.test "passing async.mixed sync", ->
        assert.ok(true)

      context1.test "passing async.mixed async", (context2) ->
        saneTimeout 300, ->
          context2.pass()

  context0.test "passing async.sync", (context1) ->
    saneTimeout 300, ->

      context1.test "passing async.sync 1", ->
        assert.ok(true)

      context1.test "passing async sync 2", ->
        assert.ok(true)

  context0.test "passing async.async", (context1) ->
    saneTimeout 300, ->
      context1.test "passing async.async async", (context2) ->
        saneTimeout 300, ->
          context2.pass()


#Testify.test "allfail", (context0) ->

  #context0.test "allfail sync fail", ->
    #assert.ok(false)

  #context0.test "allfail async", (context1) ->
    #process.nextTick ->
      #context1.fail("Intentional failure")

  #context0.test "allfail async.mixed", (context1) ->
    #saneTimeout 300, ->

      #context1.test "allfail async.mixed sync", ->
        #assert.ok(false)

      #context1.test "allfail async.mixed async", (context2) ->
        #saneTimeout 300, ->
          #context2.fail("Intentional failure")

      #context1.test "allfail async.mixed error", ->
        #throw new Error("hello!")

  #context0.test "allfail async.sync", (context1) ->
    #saneTimeout 300, ->

      #context1.test "allfail async.sync 1", ->
        #assert.ok(false)

      #context1.test "allfail async sync 2", ->
        #assert.ok(false)

  #context0.test "allfail async.async", (context1) ->
    #saneTimeout 300, ->
      #context1.test "allfail async.async async", (context2) ->
        #saneTimeout 300, ->
          #context2.fail("Intentional Failure")


