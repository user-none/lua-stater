local fail = false
print("Test: restart complex...")

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

local function sm_skip_pre(arg)
    return false, 5
end

local arg = { val=2, val2=-100 }

local states = {
    { id=1, func=state_a },
    { id="b", func=state_b },
    { id="C", func=state_c }
}

local sm = stater(states, stater.FLAG_CLEANUP_DONE)
sm:add_sub_sm(4, sm, sm_pre, sm_post, sm)
sm:add_state(5, state_d)
sm:add_sub_sm("z", sm, sm_skip_pre, nil, sm)
sm:add_state(6, state_e)

repeat
    ret = sm:run(arg)
until ret ~= stater.WAIT

if ret ~= stater.DONE then
    print(string.format("\tFail: (1) ret = %d, expected %d", ret, stater.DONE))
    fail = true
end

if arg.val ~= 25 then
    print(string.format("\tFail: (1) val = %d, expected %d", arg.val, 25))
    fail = true
end

if arg.val2 ~= -91 then
    print(string.format("\tFail: (1) val = %d, expected %d", arg.val2, -91))
    fail = true
end

repeat
    ret = sm:run(arg)
until ret ~= stater.WAIT

if ret ~= stater.DONE then
    print(string.format("\tFail: (2) ret = %d, expected %d", ret, stater.DONE))
    fail = true
end

if arg.val ~= 41 then
    print(string.format("\tFail: (2) val = %d, expected %d", arg.val, 41))
    fail = true
end

if arg.val2 ~= -88 then
    print(string.format("\tFail: (2) val = %d, expected %d", arg.val2, -88))
    fail = true
end

repeat
    ret = sm:run(arg)
until ret ~= stater.WAIT

if ret ~= stater.DONE then
    print(string.format("\tFail: (3) ret = %d, expected %d", ret, stater.DONE))
    fail = true
end

if arg.val ~= 57 then
    print(string.format("\tFail: (3) val = %d, expected %d", arg.val, 57))
    fail = true
end

if arg.val2 ~= -85 then
    print(string.format("\tFail: (3) val = %d, expected %d", arg.val2, -85))
    fail = true
end

if not fail then
    print("\tPass")
end
