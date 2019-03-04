Lua-stater
==========

Lua state machine.

Hybrid linear and non-linear state machine.

The state machine will run though every state in the order they
were added to the state machine by default. States can provide
an alternate state id to that should be called instead of the
directly next state. This provides the hybrid excitation.

By default when the last state is called, and a next id is
not provided, the state machine will return `DONE`. This behavior
can be changed to return an `ERROR` if desired.

State Overview
--------------

States can be either a function or another state machine to run.

All states and associated functions will be passed and `arg` object.
It is optional that this be provided but it is recommended. This allows
a local variable to be passed to each state so action can be preformed.

States are comprised of the following parts.

### id (required)

An id referencing the state.

All states much have an id. The id is unique to the state machine
and a sub state machine can have the same ids without interfering
with the parent state machine.

id's can be any value. E.g. number, string...

### func (required unless `subm` is provided)

Function to run when the state is called.

Prototype:

    func(arg)

Must return a status. When the status is NEXT it can optionally
also return a state id that the state machine should transition
to instead of the direct next state. E.g.

    return M.ERROR_STATE
    return M.NEXT
    return M.NEXT, "state_d"
    return M.NEXT, 1

### subm (required unless `func` is provided)

Sub state machine to run.

Adding a sub state machine will cause the sub state machine to be
copied. The sub state machine being added can be modified without
changing the now internal sub state machine. This allows sub state
machines to be built up and expanded needed.

### pre (optional)

Called before a `subm` is run to determine if the sub state machine
should be run or skipped.

Prototype:

    pre(arg)

Returns `true` to run.
`false` to skip and when `false`, optionally a next id. E.g.

    return true
    return false
    return false, "state_d"
    return false, 1

### post (optional)

Called after a `subm` is run to determine if an action should
be taken. For example if the state machine should continue
running even when the sub state machine fails, the return
status of the sub state machine can be overridden with the
`post` function.

Prototype:

    post(status, arg)

Must return a status. When the status is NEXT it can optionally
also return a state id that the state machine should transition
to instead of the direct next state. E.g.

    return M.ERROR_STATE
    return M.NEXT
    return M.NEXT, "state_d"
    return M.NEXT, 1

If `post` is not provided and the sub state machine itself
returned `DONE`, then NEXT will be returned to the parent state
machine so it will continue running.

If `post` is provided and the sub state machine executed without
error the status passed to `post` will be `DONE`. A `post` function
must check for `DONE` and change it to NEXT otherwise the parent state
machine will exit due to `post` returning `DONE`. E.g.

    function post(status, arg)
        if status == stater.DONE then
            status = stater.NEXT
        end
        return status
    end


Cleanup state machines
----------------------

States can also have associated cleanup state machines `csm`.
The cleanup state machine will only be run if a state was entered.
If the state is a sub state machine, then the `csm` will only
be called if the `pre` function does not exit or if `pre` was
called and returned `true`

The return status of the parent state machine will be retained
and returned once all `csm`s have been run. The result of any
given `csm` will not be returned once the parent state machine 
finishes running. `csm` can still exit themselves on `ERROR` or `DONE`.

If a `csm` exits due to error, the other `csm`s in the cleanup
sequence will still be run. A `csm` cannot prevent another `csm`
from running. If this is required a flag in the `arg` object
should be used.

A cleanup state machine is very useful when combined with the
`FLAG_CLEANUP_DONE`. For example, a disconnection sequence that
needs to be run when the state machine exits regardless of
error or done. The state machine should be constructed as such.

    state 1 = sub state machine connection sequence. csm = disconnect sequence sub state machine.
    state n = processing

If any state returns an error or when the `DONE` is returned
the disconnect `csm` will be called. Depending on the cause
of the error a flag in `arg` can be set to determine if disconnect
should be run. Or since `csm` does not impact the final outcome
of the parent state machine it could always be attempted. The
failure can be ignored.

In this example if disconnect should only happen on a success
run then the last state should be the disconnect sequence. However,
if processing is all that matters and it doesn't matter the outcome
of the disconnect `subm` then the `post` function can be used
to override the error and exit.

Running
-------

Once the state machine has been setup the `run` function is used
to through the states. If `WAIT` is returned, then the state machine
should suspend until some even has occurred where it should be started
again. Calling `run` after `WAIT` will cause the state machine to
pickup where it left off and continue.

Once a state machine has exited due to `ERROR` or `DONE` calling
`run` again will reset the state machine and run from the beginning.

Example use
-----------

    local stater = require("stater.sm")

    local function state_a(arg)
        arg.val = arg.val + 1
        return stater.NEXT
    end
    
    local function state_b(arg)
        arg.val = arg.val + 1
        return stater.NEXT
    end
    
    local function state_c(arg)
        arg.val = arg.val + 1
        return stater.NEXT
    end
    
    local arg = { val=0 }
    
    local states = {
        { id=1, func=state_a },
        { id="b", func=state_b },
        { id="C", func=state_c }
    }
    local sm = stater(states)
    
    ret = sm:run(arg)

Testing
-------

The test directory provides tests for various combinations of use.
Tests can be run directly from the test directory  like so:

    $ cd test
    $ LUA_PATH="../?.lua;./?.lua;" lua5.3 test_stater.lua
