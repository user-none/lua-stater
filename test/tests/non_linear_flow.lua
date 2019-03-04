local fail = false
print("Test: non linear flow...")

local function state_a(arg)
    arg.val = arg.val + 1
    return stater.NEXT, "C"
end

local function state_b(arg)
    arg.val = arg.val + 1
    return stater.DONE
end

local function state_c(arg)
    arg.val = arg.val + 1
    return stater.NEXT, "b"
end

local arg = { val=0 }

local states = {
    { id=1, func=state_a },
    { id="b", func=state_b },
    { id="C", func=state_c }
}
local sm = stater(states)

ret = sm:run(arg)
if ret ~= stater.DONE then
    print(string.format("\tFail: ret = %d, expected %d", ret, stater.DONE))
    fail = true
end

if arg.val ~= 3 then
    print(string.format("\tFail: val = %d, expected %d", arg.val, 3))
    fail = true
end

if not fail then
    print("\tPass")
end
