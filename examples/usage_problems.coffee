Testify = require "../src/testify"
assert = require "assert"

saneTimeout = (ms, fn) -> setTimeout(fn, ms)

Testify.test "Usage problems", (context) ->


  context.test "sync after context completion", (context) ->
    context.test "complete me", ->
      assert.ok true

    process.nextTick ->
      context.test "here's the tardy sync", ->
        assert.ok true

  context.test "async after context completion", (context) ->
    context.test "complete me", ->
      assert.ok true

    process.nextTick ->
      context.test "here's the tardy async", (context) ->
        context.test "never get here", ->
          console.log "NOOO"
          assert.ok false
