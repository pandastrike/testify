
EventEmitter = require("events").EventEmitter
FSM = require "./minfinite"

module.exports = class Context

  # Arity of a function can be determined using a function's `length` property
  # For the purposes of this library, a `work` function which takes no args
  # represents synchronous work. When the supplied function takes an argument,
  # it will be treated as asynchronous and passed this context as that argument.
  constructor: (@name, @work, @parent) ->
    if @work.length == 0
      @type = "sync"
    else
      @type = "async"

    if @parent
      @level = @parent.level + 1
    else
      @level = 0

    @children = []
    @emitter = new EventEmitter()

    # Finite State Machine
    #
    # States:
    #
    # START: starting state
    # SYNC: context has only synchronous children
    # ASYNC: context has at least one asynchronous child
    # CHILDLESS: context finished the work/setup function before any children were defined.
    #   The expectation is that children will be added in an asynchronous callback.
    # COMPLETE: all synchronous and asynchronous children have finished their work.
    #
    # Events:
    #
    # sync_child: signals the creation of a synchronous child context
    # async_child: signals creation of an asynchronous child
    # completion: one of the descendants of a context has finished
    # end_of_block: the context reached the end of its work function
    #
    # The return value of each event function is used to select the next state.
    @fsm = new FSM()
    @fsm.define
      START:
        sync_child:
          action: (args...) =>
          next: "SYNC"
        async_child:
          action: (args...) =>
          next: "ASYNC"

        childless:
          action: =>
          next: "CHILDLESS"

        end_of_block:
         action:  =>
            @notify_parent()
          next: "COMPLETE"
      SYNC:
        sync_child:
          action: (args...) =>
          next: "SYNC"

        async_child:
          action: (args...) =>
          next: "ASYNC"

        end_of_block:
         action:  =>
            @notify_parent()
          next: "COMPLETE"

        completion:
          action: =>
            @notify_parent()
          next: "COMPLETE"

      ASYNC:
        sync_child:
          action: (args...) =>
          next: "ASYNC"

        async_child:
          action: (args...) =>
          next: "ASYNC"

        end_of_block:
          action: =>
          next: "ASYNC"

        completion:
          action: =>
            @notify_parent()
          next: "COMPLETE"

      CHILDLESS:
        sync_child:
          action: (args...) =>
          next: "SYNC"

        async_child:
          action: (args...) =>
          next: "ASYNC"

        completion:
          action: =>
            @notify_parent()
          next: "COMPLETE"

      COMPLETE:
        completion:
          action: (args...) =>
          next: "COMPLETE"
        reset:
          action: =>
          next: "START"

  state: ->
    @fsm.state

  event: (name, args...) ->
    #current = @fsm.state
    @fsm.event(name, args...)
    #console.log()
    #console.log
      #name: @name
      #from: current
      #event: name
      #to: @fsm.state


  is_done: ->
    @children.every (child) -> child.state() == "COMPLETE"

  notify_parent: ->
    #process.nextTick =>
    setTimeout (=>
      if @parent?.is_done()
        @parent?.event "completion", @), 0

  done: ->
    @event "completion"

  child: (description, work) ->
    child = new @constructor(description, work, @)
    if child.type == "sync"
      @event "sync_child", child
    else if child.type == "async"
      @event "async_child", child
    else
      throw new Error("bad type: #{child.type}")
    @children.push(child)
    @emitter.emit "child", child
    child._run()


  _run: (args...) ->
    @work(@)
    if @type == "sync" || @children.length > 0
      @event "end_of_block"
    else
      @event "childless"


