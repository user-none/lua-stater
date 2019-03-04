local fail = false
print("Test: complex 2...")

local function state_a(arg)
    arg.val = arg.val + 1
    arg.val2 = arg.val2 + 1
    return stater.NEXT
end

local function state_b(arg)
    if arg.val < 9 then
        return stater.PREV
    end
    return stater.NEXT
end

local function state_c(arg)
    arg.val = arg.val + 1
    if arg.val == 10 then
        return stater.WAIT
    end
    return stater.NEXT
end

local function state_d(arg)
    arg.val = arg.val + 10
    return stater.DONE
end

local function state_e(arg)
    arg.val = arg.val + 1000
    return stater.NEXT, 5
end

local function sm_pre(arg)
    return true
end

local function sm_post(status, arg)
    return stater.NEXT, "z"
end

local arg = { val=2, val2=-100 }

local states = {
    { id=1, func=state_a },
    { id="b", func=state_b },
    { id="C", func=state_c }
}

local states2 = {
    { id=1, func=state_a },
    { id="b", func=state_b },
    { id="C", func=state_c }
}

local sm   = stater(states, stater.FLAG_CLEANUP_DONE)
local subm = stater(states2)
sm:add_sub_sm(4, subm, sm_pre, sm_post, sm)
sm:add_state(5, state_d)
sm:add_sub_sm("z", subm, sm_pre, nil, sm)
sm:add_state(6, state_e)

repeat
    ret = sm:run(arg)
until ret ~= stater.WAIT

if ret ~= stater.DONE then
    print(string.format("\tFail: ret = %d, expected %d", ret, stater.DONE))
    fail = true
end

if arg.val ~= 23 then
    print(string.format("\tFail: val = %d, expected %d", arg.val, 23))
    fail = true
end

if arg.val2 ~= -87 then
    print(string.format("\tFail: val = %d, expected %d", arg.val2, -87))
    fail = true
end

if not fail then
    print("\tPass")
end
