Testify = require "../testify"
assert = require "assert"

Testify.test "gnome", (suite) ->
  assert.ok(true)

  suite.test "gnome sync", ->
    assert.ok(true)

  suite.test "gnome async", (context) ->
    process.nextTick ->
      assert.ok(true)
      context.pass()

  suite.test "gnome nested async", (context) ->
    assert.ok(true)
    process.nextTick ->
      context.test "gnome inner async", (context) ->

        context.test "gnome inner async sync", ->
          assert.ok(true)

        context.test "gnome inner async async", (context) ->
          assert.ok(true)
          context.pass()


Testify.test "smurf", (c1) ->
  c1.test "smurf sync", ->
    assert.ok(true)

  c1.test "smurf sync fail", ->
    assert.ok(false)

  c1.test "smurf async", (c2) ->
    assert.ok(true)
    c2.pass()

  c1.test "smurf async fail", (c3) ->
    assert.ok(false)
    c3.pass()

  c1.test "smurf nested async", (c4) ->
    assert.ok(true)

    c4.test "smurf async inner", (c5) ->
      assert.ok(true)
      c5.pass()
    c4.pass()


    c4.test "smurf async inner failure", (c6) ->
      assert.ok(false)
      c6.pass()
    c4.pass()
  c1.test "smurf error", ->
    throw new Error("hi there")



