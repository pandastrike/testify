Testify = require "../src/testify"
assert = require "assert"

Testify.test "Nesting contexts for better association", (context) ->

  context.test "Basic arithmetic", (context) ->

    context.test "addition", ->

      assert.equal (2 + 2), 4
      assert.equal (100 + 2), 102

    context.test "multiplication", ->

      assert.equal (6 * 7), 42
      assert.equal (8 * 8), 64




