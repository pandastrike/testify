Testify = require "../src/testify"
assert = require "assert"

some_async_call = (callback) ->
  process.nextTick ->
    callback null, "pie"

another_async_call = (input, callback) ->
  process.nextTick ->
    callback null, ["bacon", "cheese", "pie"]

Testify.test "a suite of tests", (context) ->

  # When you need to test the results of an asynchronous function,
  # give context.test() a function that takes an argument.  You can
  # then use that argument as a new context for nesting tests.
  context.test "testing something asynchronous", (context) ->

    some_async_call (error, result1) ->

      # If you give context.test() a function that takes no arguments,
      # the test is required to be synchronous, and considered to have
      # passed if the function runs without throwing an error.
      context.test "result makes me happy", ->
        assert.ifError(error)
        assert.equal(result1, "pie")

      context.test "a nested asynchronous test", (context) ->

        another_async_call result1,  (error, result2) ->

          context.test "result makes me deeply happy", ->
            assert.ifError(error)
            assert.deepEqual result2, ["bacon", "cheese", "pie"]

      context.test "shortcut for passing an async test", (context) ->
        process.nextTick ->
          # you can call context.pass() instead of using a synchronous test
          context.pass()

      context.test "shortcut for failing an async test", (context) ->
        process.nextTick ->
          context.fail("I just couldn't go on")

