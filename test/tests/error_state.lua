local fail = false
print("Test: error state...")

local function state_a(arg)
    arg.val = arg.val + 1
    return stater.NEXT
end

local function state_b(arg)
    arg.val = arg.val + 1
    return stater.ERROR_STATE
end

-- This state should not run because state_b exited the sm early.
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
if ret ~= stater.ERROR_STATE then
    print(string.format("\tFail: ret = %d, expected %d", ret, stater.ERROR_STATE))
    fail = true
end

if arg.val ~= 2 then
    print(string.format("\tFail: val = %d, expected %d", arg.val, 2))
    fail = true
end

if not fail then
    print("\tPass")
end
