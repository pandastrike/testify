
EventEmitter = require("events").EventEmitter

module.exports = class Context

  constructor: (@name, @work, @parent) ->
    # Arity of a function can be determined using the `length` property
    # For the purposes of this library, a `work` function which takes no args
    # represents synchronous work. When the supplied function takes an argument,
    # it will be treated as asynchronous and passed this context as that argument.
    if @work.length == 0
      @type = "sync"
    else
      @type = "async"

    if @parent
      @level = @parent.level + 1
    else
      @level = 0

    @emitter = new EventEmitter()
    @children = []
    @state = "REST"

    # Finite State Machine
    #
    # States:
    #
    # REST: starting state
    # SYNC: context has only synchronous children
    # ASYNC: context has at least one asynchronous child
    # NO_CHILDREN: context finished the work/setup function before any children were defined.
    #   The expectation is that children will be added in an asynchronous callback.
    # COMPLETE: all synchronous and asynchronous children have finished their work.
    #
    # Events:
    #
    # sync_child: signals the creation of a synchronous child context
    # async_child: signals creation of an asynchronous child
    # child_done: one of the descendants of a context has finished
    # end: the context reached the end of its work function
    # timeout: I don't remember the exact intent, and it's not presently used.
    #
    # The return value of each event function is used to select the next state.
    @table =
      REST:
        sync_child: (args...) =>
          @add_sync(args...)
          "SYNC"
        async_child: (args...) =>
          @add_async(args...)
          "ASYNC"
        end: =>
          if @type == "sync"
            @complete()
            "COMPLETE"
          else
            "NO_CHILDREN"
      SYNC:
        sync_child: (args...) =>
          @add_sync(args...)
          "SYNC"
        async_child: (args...) =>
          @add_async(args...)
          "ASYNC"
        child_done: (args...) =>
          @complete()
          "COMPLETE"
        end: =>
          @complete()
          "COMPLETE"
      ASYNC:
        sync_child: (args...) =>
          @add_sync(args...)
          "ASYNC"
        async_child: (args...) =>
          @add_async(args...)
          "ASYNC"
        end: =>
          "ASYNC"
        child_done: (args...) =>
          if @is_done()
            @complete()
            "COMPLETE"
          else
            "ASYNC"
        timeout: =>
          "COMPLETE"
      NO_CHILDREN:
        sync_child: (args...) =>
          @add_sync(args...)
          "SYNC"
        async_child: (args...) =>
          @add_async(args...)
          "ASYNC"
        child_done: (args...) =>
          @complete()
          "COMPLETE"
        end: =>
          @complete()
          "COMPLETE"
        timeout: =>
          @complete()
          "COMPLETE"
      COMPLETE:
        sync_child: (args...) =>
          throw new Error "Testify Context '#{@name}' created a synchronous child after it had completed"
          "COMPLETE"
        child_done: (args...) =>
          "COMPLETE"
        reset: (args...) =>
          "REST"

  event: (name, args...) ->
    current_state = @state
    transition = @table[@state][name]
    if !transition
      throw new Error("Context(#{@name}) in State(#{@state}) has no transition for Event(#{name})")
    else
      @state = transition(args...)
      #console.log "Context(#{@name}) in State(#{current_state}) got Event(#{name}) -> #{@state}".cyan
    if @state != current_state
      @emitter.emit @state

  is_done: ->
    @children.every (child) -> child.state == "COMPLETE"

  complete: ->
    process.nextTick =>
      @parent?.event "child_done", @

  add_sync: (child) ->
    @children.push(child)

  add_async: (child) ->
    @children.push(child)


  child: (description, work) ->
    child = new @constructor(description, work, @)
    if child.type == "sync"
      @event "sync_child", child
    else if child.type == "async"
      @event "async_child", child
    else
      throw new Error("bad type: #{child.type}")
    child._run()


  _run: (args...) ->
    @work(@)
    @event "end"

  done: ->
    process.nextTick =>
      @event "child_done"


