Testify = require "../src/testify"
assert = require "assert"

Testify.test "straightforward synchronous testing", (context) ->

  context.test "arithmetic", ->
    assert.equal (2 + 2), 4

  context.test "strings", ->
    assert.equal "foo".toUpperCase(), "FOO"

  context.test "error handling", ->
    error = new Error "I failed."
    assert.ifError(error)

