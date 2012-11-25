Testify = require("./testify")
microtime = require "microtime"

ts_bench = Testify.benchmark "Timestamp generation", (bm) ->

  bm.measure ->
    for i in [0..128]
      microtime.now()

dataset = ts_bench.run
  samples: 4000


#dataset.draw(units: "us", width: 90, height: 16, sample_function: "max")
console.log dataset.summarize(4)



