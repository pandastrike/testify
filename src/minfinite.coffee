EventEmitter = require("events").EventEmitter

module.exports = class FSM

  constructor: (initial_state="START") ->
    @state = initial_state
    @emitter = new EventEmitter()

  define: (table) ->
    if @validate(table)
      @table = table
    else
      throw new Error("Invalid state table")

  validate: (table) ->
    for state, def of table
      # All states must have transitions
      return false unless Object.keys(def).length > 0
      for event, transition of def
        {action, next} = transition
        unless typeof(action) == "function"
          console.log "Action for #{state}, #{event} is not a function"
          return false
        unless typeof(next) == "string"
          console.log "Next state for #{state}, #{event} is not a string"
          return false
        unless table[next]
          console.log "Next state for #{state}, #{event} does not exist"
          return false
    return true

  event: (name, args...) ->
    current_state = @state
    transition = @table[@state][name]
    if !transition
      error = new Error "State(#{@state}) has no transition for Event(#{name})"
      error.state = @state
      error.event = name
      throw(error)
    else
      {action, next} = transition
      action(args...)
      @state = next
      if @state != current_state
        @emitter.emit @state
    


