-- Copyright (c) 2019 John Schember <john@nachtimwald.com>
--
-- Permission is hereby granted, free of charge, to any person obtaining
-- a copy of this software and associated documentation files (the "Software"),
-- to deal in the Software without restriction, including without limitation
-- the rights to use, copy, modify, merge, publish, distribute, sublicense,
-- and/or sell copies of the Software, and to permit persons to whom the
-- Software is furnished to do so, subject to the following conditions:
--
-- The above copyright notice and this permission notice shall be included in
-- all copies or substantial portions of the Software.
--
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
-- FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
-- DEALINGS IN THE SOFTWARE.

--- State Machine
--
-- Hybrid linear and non-linear state machine.
--
-- The state machine will run though every state in the order they
-- were added to the state machine by default. States can provide
-- an alternate state id to that should be called instead of the
-- directly next state. This provides the hybrid excitation.
--
-- By default when the last state is called, and a next id is
-- not provided, the state machine will return `DONE`. This behavior
-- can be changed to return an `ERROR` if desired.
--
-- State Overview
-- --------------
--
-- States can be either a function or another state machine to run.
--
-- All states and associated functions will be passed and `arg` object.
-- It is optional that this be provided but it is recommended. This allows
-- a local variable to be passed to each state so action can be preformed.
--
-- States are comprised of the following parts.
--
-- ### id (required)
--
-- An id referencing the state.
--
-- All states much have an id. The id is unique to the state machine
-- and a sub state machine can have the same ids without interfering
-- with the parent state machine.
--
-- id's can be any value. E.g. number, string...
--
-- ### func (required unless `subm` is provided)
--
-- Function to run when the state is called.
--
-- Prototype:
--
--     func(arg)
--
-- Must return a status. When the status is NEXT it can optionally
-- also return a state id that the state machine should transition
-- to instead of the direct next state. E.g.
--
--     return M.ERROR_STATE
--     return M.NEXT
--     return M.NEXT, "state_d"
--     return M.NEXT, 1
--
-- ### subm (required unless `func` is provided)
--
-- Sub state machine to run.
--
-- Adding a sub state machine will cause the sub state machine to be
-- copied. The sub state machine being added can be modified without
-- changing the now internal sub state machine. This allows sub state
-- machines to be built up and expanded needed.
--
-- ### pre (optional)
--
-- Called before a `subm` is run to determine if the sub state machine
-- should be run or skipped.
--
-- Prototype:
--
--     pre(arg)
--
-- Returns `true` to run.
-- `false` to skip and when `false`, optionally a next id. E.g.
--
--     return true
--     return false
--     return false, "state_d"
--     return false, 1
--
-- ### post (optional)
--
-- Called after a `subm` is run to determine if an action should
-- be taken. For example if the state machine should continue
-- running even when the sub state machine fails, the return
-- status of the sub state machine can be overridden with the
-- `post` function.
--
-- Prototype:
--
--     post(status, arg)
--
-- Must return a status. When the status is NEXT it can optionally
-- also return a state id that the state machine should transition
-- to instead of the direct next state. E.g.
--
--     return M.ERROR_STATE
--     return M.NEXT
--     return M.NEXT, "state_d"
--     return M.NEXT, 1
--
-- If `post` is not provided and the sub state machine itself
-- returned `DONE`, then NEXT will be returned to the parent state
-- machine so it will continue running.
--
-- If `post` is provided and the sub state machine executed without
-- error the status passed to `post` will be `DONE`. A `post` function
-- must check for `DONE` and change it to NEXT otherwise the parent state
-- machine will exit due to `post` returning `DONE`. E.g.
--
--     function post(status, arg)
--         if status == stater.DONE then
--             status = stater.NEXT
--         end
--         return status
--     end
--
-- Cleanup state machines
-- ----------------------
--
-- States can also have associated cleanup state machines `csm`.
-- The cleanup state machine will only be run if a state was entered.
-- If the state is a sub state machine, then the `csm` will only
-- be called if the `pre` function does not exit or if `pre` was
-- called and returned `true`
--
-- The return status of the parent state machine will be retained
-- and returned once all `csm`s have been run. The result of any
-- given `csm` will not be returned once the parent state machine 
-- finishes running. `csm` can still exit themselves on `ERROR` or `DONE`.
--
-- If a `csm` exits due to error, the other `csm`s in the cleanup
-- sequence will still be run. A `csm` cannot prevent another `csm`
-- from running. If this is required a flag in the `arg` object
-- should be used.
--
-- A cleanup state machine is very useful when combined with the
-- `FLAG_CLEANUP_DONE`. For example, a disconnection sequence that
-- needs to be run when the state machine exits regardless of
-- error or done. The state machine should be constructed as such.
--
--     state 1 = sub state machine connection sequence. csm = disconnect sequence sub state machine.
--     state n = processing
--
-- If any state returns an error or when the `DONE` is returned
-- the disconnect `csm` will be called. Depending on the cause
-- of the error a flag in `arg` can be set to determine if disconnect
-- should be run. Or since `csm` does not impact the final outcome
-- of the parent state machine it could always be attempted. The
-- failure can be ignored.
--
-- In this example if disconnect should only happen on a success
-- run then the last state should be the disconnect sequence. However,
-- if processing is all that matters and it doesn't matter the outcome
-- of the disconnect `subm` then the `post` function can be used
-- to override the error and exit.
--
-- Running
-- -------
--
-- Once the state machine has been setup the `run` function is used
-- to through the states. If `WAIT` is returned, then the state machine
-- should suspend until some even has occurred where it should be started
-- again. Calling `run` after `WAIT` will cause the state machine to
-- pickup where it left off and continue.
--
-- Once a state machine has exited due to `ERROR` or `DONE` calling
-- `run` again will reset the state machine and run from the beginning.
--
-- Example use
-- -----------
--
--     local stater = require("stater.sm")
--
--     local function state_a(arg)
--         arg.val = arg.val + 1
--         return stater.NEXT
--     end
--     
--     local function state_b(arg)
--         arg.val = arg.val + 1
--         return stater.NEXT
--     end
--     
--     local function state_c(arg)
--         arg.val = arg.val + 1
--         return stater.NEXT
--     end
--     
--     local arg = { val=0 }
--     
--     local states = {
--         { id=1, func=state_a },
--         { id="b", func=state_b },
--         { id="C", func=state_c }
--     }
--     local sm = stater(states)
--     
--     ret = sm:run(arg)

local M = {}
local M_mt = { __index = M }

--- Flags controlling behavior.
--
-- FLAG_NO_LINEAR_END: An explicit
--                     DONE returned by a state function is
--                     required. It is considered an error if
--                     the state machine ends due to running
--                     out of states to run.
-- FLAG_CLEANUP_DONE:  Run all cleanup state machines on DONE.
-- FLAG_CLEANUP_EVERY: Run a state's associated cleanup every
--                     time a given state is been called. This
--                     can cause cleanup the states to be run
--                     multiple times in order they were called.
--                     The default is to only run a clean up once,
--                     the first time the state is called.
M.FLAG_NONE          = 0
M.FLAG_NO_LINEAR_END = 1 << 0
M.FLAG_CLEANUP_DONE  = 1 << 1
M.FLAG_CLEANUP_EVERY = 1 << 2

--- Return values.
--
-- NEXT, PREV, WAIT, DONE, ERROR_STATE
-- can all be returned by state functions.
-- The rest of the return values can be
-- returned by :run() and inform about an
-- internal error.
M.NEXT          = 0
M.PREV          = 1
M.WAIT          = 2
M.DONE          = 3
M.ERROR_STATE   = 4
M.ERROR_ID      = 5
M.ERROR_NO_PREV = 6
M.ERROR_NO_NEXT = 7
M.ERROR_SELF    = 8

--- Insert a state into a state machine
--
-- Will validate the state.
--
-- @param self State machine
-- @param state Table representing a single state.
--
-- @return true on sucess
-- @return false, err on error
local function insert_state(self, state)
    if state == nil then
        return false, "state cannot be nil"
    end

    if type(state) ~= "table" then
        return false, "state must be a table"
    end

    if state.id == nil then
        return false, "id cannot be nil"
    end

    if self._states[state.id] then
        return false, "id already exists"
    end

    if state.func == nil and state.subm == nil then
        return false, "must have func or subm specified"
    end

    if state.func ~= nil and type(state.func) ~= "function" then
        return false, "func invalid"
    end

    if state.subm ~= nil and not M.is_sm(state.subm) then
        return false, "subm must be a state machine"
    end

    if state.pre and type(state.pre) ~= "function" then
        return false, "pre must be a funciton"
    end

    if state.post and type(state.post) ~= "function" then
        return false, "post must be a funciton"
    end

    if state.csm ~= nil and not M.is_sm(state.csm) then
        return false, "invalid cleanup_sm"
    end

    local subm = state.subm and state.subm:copy() or nil
    local csm = state.csm and state.csm:copy() or nil

    self._states[#self._states+1] = { id=state.id, func=state.func, subm=subm, pre=state.pre, post=state.post, csm=csm }
    self._ids[state.id] = #self._states

    return true
end

--- Determine if a we need to track this state for cleanup.
local function add_cleanup(self, state)
    -- No cleanup state machine so no need to
    -- worry about this state.
    if state.csm == nil then
        return
    end

    -- If we're not going to run every then we need
    -- to check if we've already added this state
    -- and not add it if we did.
    if (self._flags & M.FLAG_CLEANUP_EVERY) == 0 then
        if self._cleanup_seen_ids[state.id] then
            return
        end
    end

    -- Add the id to the cleanup list.
    self._cleanup_seen_ids[state.id] = 1
    self._cleanup_ids[#self._cleanup_ids+1] = state.id
end

--- Run cleanup state machines for state that have run.
local function run_cleanup(self, arg)
    if #self._cleanup_ids == 0 then
        return M.DONE
    end

    -- Go through the list of cleanup ids that have been collected.
    -- Cleanup happens in reverse order. They run backwards from
    -- the direction of the states. Last state's cleanup runs first.
    while #self._cleanup_ids > 0 do
        -- Get the id for the last id in the list.
        local id = self._cleanup_ids[#self._cleanup_ids]

        -- Get the state and its cleanup state machine.
        local state = self._states[self._ids[id]]

        -- Run the cleanup state machine.
        status = state.csm:run(arg)
        if status == M.NEXT or status == M.PREV or status == M.WAIT then
            return status
        else
            -- Remove the id from the list since it's all done.
            table.remove(self._cleanup_ids)
        end
    end

    -- Cleanups ignore errors and keep going
    -- We don't want to stop because of an error.
    -- That could cause the cleanup sequence to
    -- stop early.
    return M.DONE
end

--- Create a state machine
--
-- State machines are comprised of states which represent a function
-- or another sub state machine.
--
-- A table of state entries can be passed into this function
-- which will setup the state machine. For example:
--
-- {
--   { id=1, func=func, csm=cleanup_sm },
--   { id=2, subm=sm, pre=pre_func, post=post_func, csm=cleanup_sm }
-- }
--
-- @param states States
-- @param flags Flags
--
-- @return state machine
-- @return nil, error
function M:new(states, flags)
    if self ~= M then
        return nil, "First argument must be self"
    end

    local o = setmetatable({}, M_mt)
    o._flags = flags and flags or M.FLAG_NONE
    -- List of states.
    o._states = {}
    -- Mapping of id to index in states list
    -- id -> idx
    o._ids = {}
    -- Currently processing id while sm is running
    o._cid = nil
    -- List of ids that were processed before this one
    o._prev_ids = {}
    -- Is the sm running.
    o._running = false
    -- States that have run that are eligible for cleanup.
    o._cleanup_ids = {}
    -- Cleanup ids that have already run.
    o._cleanup_seen_ids = {}
    -- Do we need to run cleanup state machines.
    o._do_cleanup = false
    -- Return status after cleanup finishes.
    o._return_status = M.DONE

    -- Run though states (if provided) and add them.
    if states ~= nil then
        for _, state in ipairs(states) do
            local ret, err = insert_state(o, state)
            if not ret then
                return nil, err
            end
        end

        if #o._states == 0 then
            return nil, "No states found"
        end
    end
    return o
end
setmetatable(M, { __call = M.new })

--- Add a table of states
--
-- E.g
-- {
--   { id=1, func=func, csm=cleanup_sm },
--   { id=2, subm=sm, pre=pre_func, post=post_func, csm=cleanup_sm }
-- }
--
-- @param states States to add
--
-- @return true on success
-- @return false, err on error
function M:add(states)
    if states == nil or type(states) ~= "table" then
        return false, "states not table"
    end

    if #states == 0 then
        return nil, "No states found"
    end

    for _, state in ipairs(states) do
        local ret, err = insert_state(self, state)
        if not ret then
            return false, err
        end
    end

    return true
end

--- Add a single state
--
-- E.g
--
-- { id=1, func=func, csm=cleanup_sm },
--
-- @param state A state to add
--
-- @return true on success
-- @return false, err on error
function M:add_single(state)
    return insert_state(self, state)
end

--- Add a single state by passing parts as parameters
--
-- @param id ID
-- @param func State function
-- @param cleanup_sm Clean up state machine
--
-- @return true on success
-- @return false, err on error
function M:add_state(id, func, cleanup_sm)
    if func == nil then
        return false, "func cannot be nil"
    end
    return insert_state(self, { id=id, func=func, csm=cleanup_sm })
end

--- Add a single sub state machine state by passing parts as parameters
--
-- @param id ID
-- @param sm sub state machine
-- @param pre_func Function to run before running the sub state machine
-- @param post_func Function to run after running the sub state machine
-- @param cleanup_sm Clean up state machine
--
-- @return true on success
-- @return false, err on error
function M:add_sub_sm(id, sm, pre_func, post_func, cleanup_sm)
    if sm == nil then
        return false, "sm cannot be nil"
    end
    return insert_state(self, { id=id, subm=sm, pre=pre_func, post=post_func, csm=cleanup_sm })
end

--- Reset the state machine so it can be run again.
--
-- This is not required to be called once a state machine
-- has returned anything other than WAIT. This is only needed
-- to reset a state machine with is currently in a WAIT state.
function M:reset()
    for _,state in ipairs(self._states) do
        if state.subm ~= nil then
            state.subm:reset()
        end
    end

    self._cid = nil
    self._prev_ids = {}
    self._running = false
    self._cleanup_ids = {}
    self._cleanup_seen_ids = {}
    self._do_cleanup = false
    self._return_status = M.DONE
end

--- Cancel the currently running state machine and run cleanup machines.
function M:cancel()
    if not self._running then
        return
    end

    self._return_status = M.DONE
    self._do_cleanup = true
end

--- Copy the state machine.
--
-- @return sm
function M:copy()
    local sm = M:new(nil, self._flags)

    -- Go through each state and within the state machine
    -- and copy the parameters.
    for _,state in ipairs(self._states) do
        local subm = nil
        local csm = nil

        if state.subm ~= nil then
            subm = state.subm:copy()
        end
        if state.csm ~= nil then
            csm = state.csm:copy()
        end

        insert_state(sm, { id=state.id, func=state.func, subm=subm, pre=state.pre, post=state.post, csm=csm })
    end

    return sm
end

--- Run through the state machine states
--
-- @param arg Argument to pass to each state
function M:run(arg)
    if #self._states == 0 then
        return M.ERROR_ID
    end

    -- Clear the state machine in case we're rerunning after a DONE.
    if not self._running then
        self:reset()
    end

    -- If there isn't _cid set then this must be a
    -- "first" run. Use the first state in the list
    -- of states as the starting state.
    if self._cid == nil then
        self._cid = self._states[1].id
    end
    self._running = true

    while true do
        local state = self._states[self._ids[self._cid]]
        -- Default the next_id to the next state in the list.
        -- If this is the last state next_id will remain nil.
        local next_id = nil
        if self._states[self._ids[self._cid]+1] ~= nil then
            next_id = self._states[self._ids[self._cid]+1].id
        end
        -- Next state from functions will be set here. In
        -- some places we may need to throw this away so we
        -- only want to update next_id when we are sure we'll
        -- use the id.
        local pnext_id = nil
        local status   = M.NEXT

        -- If we're in a cleanup we need to do special cleanup processing.
        if self._do_cleanup then
            -- If the current state is a sub state machine and it's running
            -- we need to keep running it. It's most likely also running cleanup.
            if state ~= nil and state.subm ~= nil and state.subm._running then
                status = state.subm:run(arg)
                if status == M.WAIT then
                    return status
                end
            end

            -- Run the cleanup state machines for this state machine's states.
            status = run_cleanup(self, arg)
            if status == M.WAIT then
                return status
            end

            -- All done. Return the pre cleanup status.
            self._running = false
            return self._return_status
        end

        if state.subm then
            -- If pre doesn't tell us not to run the subm we will run it.
            local run_sub = true

            -- Run the pre function if it exists.
            if state.pre and not state.subm._running then
                run_sub, pnext_id = state.pre(arg)
            end

            if run_sub then
                -- We're running the sub so clear the pnext_id in case one was
                -- accidentally returned when we were told to run the subm.
                pnext_id = nil

                -- If we're running the subm then it's eligible for clean up.
                -- If it's not currently running (coming back to it because of WAIT),
                -- then we will add it. This prevents it from being added after
                -- each wait.
                --
                -- Only subms that run are eligible for cleanup. If it was skipped
                -- because pre said to not run that it's not eligible.
                if not state.subm._running then
                    add_cleanup(self, state)
                end

                -- Run the sub state machine.
                status, pnext_id = state.subm:run(arg)
                -- Run the post function if it's not a WAIT status because
                -- it's done running.
                if status ~= M.WAIT then
                    if state.post then
                        status, pnext_id = state.post(status, arg)
                    elseif status == M.DONE then
                        -- No post function turn a DONE into a NEXT so
                        -- we don't exit this state machine.
                        status = M.NEXT
                    end
                    if status == M.PREV then
                        -- Remove the state's id from the cleanup list
                        -- because it's not allowed to run anymore.
                        table.remove(self._cleanup_ids)
                    end
                end
            else
                -- Not running a subm so keep going because we're skipping this one state.
                status = M.NEXT
            end
        else
            -- Run the state function.
            status, pnext_id = state.func(arg)
            -- Any internal error values are turned into the ERROR_STATE value.
            -- That is the only error that a state is allowed to return. The others
            -- don't really make sense for a state to return.
            if status ~= M.NEXT and status ~= M.PREV and status ~= M.WAIT and status ~= M.DONE then
                status = M.ERROR_STATE
            end

            -- If this isn't WAIT or PREV than it finished running and is eligible for cleanup.
            if status ~= M.WAIT and status ~= M.PREV then
                add_cleanup(self, state)
            end
        end

        if status == M.NEXT then
            -- Check if pnext_id has been set.
            -- If it was then it overrides next_id which is
            -- currently the default, next state in the states list.
            if pnext_id ~= nil then
                next_id = pnext_id
            end

            -- Validate the next id is valid.
            if self._ids[next_id] == nil then
                -- Next id is nil if there legitimately wasn't
                -- a next state. Meaning this is the last state
                -- in the states list. Unless FLAG_NO_LINEAR_END is
                -- set than this is considered DONE.
                if next_id ~= nil then
                    status = M.ERROR_ID
                elseif self._states[self._ids[self._cid]+1] == nil and (self._flags & M.FLAG_NO_LINEAR_END) == 0 then
                    status = M.DONE
                else
                    status = M.ERROR_NO_NEXT
                end
            end

            -- A state cannot call itself!
            -- If it needs to run again it should return WAIT and
            -- allow the caller to run the state machine again.
            if self._cid == next_id then
                status = M.ERROR_SELF
            end

            -- If we're still going to move to the next state store
            -- this state in the ran list and set the current id
            -- to the next id so the next iteration of the loop
            -- will run that state.
            if status == M.NEXT then
                self._prev_ids[#self._prev_ids+1] = self._cid
                self._cid = next_id
            end
        elseif status == M.PREV then
            -- We need to move back so pop off the last
            -- state that was run and we'll run that one.
            local prev_id = self._prev_ids[#self._prev_ids]
            if prev_id == nil then
                status = M.ERROR_NO_PREV
            else
                self._cid = prev_id
                self._prev_ids[#self._prev_ids] = nil
            end
        end

        -- If we're DONE and FLAG_CLEANUP_DONE is set we need
        -- to run cleanup. If there is an error we also need
        -- to run cleanup.
        if (status == M.DONE and (self._flags & M.FLAG_CLEANUP_DONE) ~= 0) or (status ~= M.NEXT and status ~= M.PREV and status ~= M.WAIT and status ~= M.DONE) then
            self._do_cleanup = true
            -- Store the current status. This is the status we want
            -- to return after all clean up has been done.
            self._return_status = status
            -- Set stat to NEXT so we'll keep looping.
            status = M.NEXT
        end

        -- We're stopping so return.
        if status ~= M.NEXT and status ~= M.PREV then
            if status ~= M.WAIT then
                self._running = false
            end
            return status
        end
    end
end

--- Check if object is a state machine
--
-- @param sm Object to check
--
-- @return true of the object is a state machine
-- @return false of the object is not a state machine
function M.is_sm(sm)
    if type(sm) == "table" and getmetatable(sm) == M_mt then
        return true
    end
    return false
end

return M
