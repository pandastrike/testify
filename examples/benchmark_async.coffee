Testify = require("../benchmark")

saneTimeout = (ms, fn) ->
  setTimeout(fn, ms)

async_benchmark = Testify.benchmark "asynchronousness", (bm) ->

  bm.measure "composite", (outer) ->
    saneTimeout 5, ->
      outer.measure "composite sync", ->
        a = []
        for i in [1..1000]
          a.push i

      outer.measure "composite inner", (inner) ->
        saneTimeout 10, ->
          inner.finish()

async_benchmark.run {iterations: 3}, (results) ->
  console.log JSON.stringify(results, null, 2)


results_example =
  runtime: 1438
  data:
    composite: [5009, 5024, 5111]
    inner: [6, 9, 4]
    sync: [4, 4, 4]

