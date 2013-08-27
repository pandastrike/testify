# Testify

Simple synchronous and asynchronous testing, using the assertions of your choice.

Written (and most easily used) in CoffeeScript.

## Basic usage

```.coffee

Testify = require "../src/testify"
assert = require "assert"

Testify.test "straightforward synchronous testing", (context) ->

  context.test "arithmetic", ->
    assert.equal (2 + 2), 4

  context.test "strings", ->
    assert.equal "foo".toUpperCase(), "FOO"

  context.test "error handling", ->
    error = new Error "This is not okay"
    assert.ifError(error)

```

Output:

```.txt

..E
straightforward synchronous testing (FAILED) ( subtest failures )
    arithmetic
    strings
    error handling ( Error: This is not okay )
    /Users/matthew/projects/oss/testify/doc/basic_usage.coffee:13:5, <js>:17:15
```

## Asynchronous usage

```.coffee

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
          context.fail()

```


Run your test files with the `coffee` executable, or by requiring them.

    coffee path/to/test.coffee

## Examples

[Testing the Shred HTTP client](https://github.com/automatthew/shred/blob/master/test/shred_test.coffee)

You can also use test nesting with entirely synchronous work, as a way to structure the
test results:

[Shred's header processing test](https://github.com/automatthew/shred/blob/master/test/headers_test.coffee)




