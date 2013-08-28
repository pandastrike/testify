graphviz = require "graphviz"
Context = require "../src/context"

{fsm: {table}} = new Context "name", (->), null
#console.log table

graph = graphviz.digraph("Context")
graph.set "rankdir", "LR"

for state, dictionary of table
  for event, rule of dictionary when event != "reset"
    next = rule.next
    graph.addNode state, style: "bold"
    graph.addEdge state, next, label: event

#console.log graph.to_dot()
graph.output "png", "doc/chart.png"



