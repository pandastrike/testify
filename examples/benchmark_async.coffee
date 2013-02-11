Testify = require("../benchmark")

saneTimeout = (ms, fn) ->
  setTimeout(fn, ms)

async_benchmark = Testify.benchmark "asynchronousness", (bm) ->

  bm.measure "composite", (context) ->
    saneTimeout 13, ->
      context.measure "composite sync", ->
        string = ""
        for i in [1..3000]
          string += i.toString()

      context.measure "composite inner", (context) ->
        saneTimeout 8, ->
          context.finish()

async_benchmark.run {iterations: 12}, (results) ->
  for key, value of results.data
    console.log key, JSON.stringify(value.data.summarize(), null, 2)



