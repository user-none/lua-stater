local fail = false
print("Test: restart...")

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
if ret ~= stater.DONE then
    print(string.format("\tFail: (1) ret = %d, expected %d", ret, stater.DONE))
    fail = true
end

if arg.val ~= 3 then
    print(string.format("\tFail: (1) val = %d, expected %d", arg.val, 3))
    fail = true
end

ret = sm:run(arg)
if ret ~= stater.DONE then
    print(string.format("\tFail: (2) ret = %d, expected %d", ret, stater.DONE))
    fail = true
end

if arg.val ~= 6 then
    print(string.format("\tFail: (2) val = %d, expected %d", arg.val, 6))
    fail = true
end

ret = sm:run(arg)
if ret ~= stater.DONE then
    print(string.format("\tFail: (3) ret = %d, expected %d", ret, stater.DONE))
    fail = true
end

if arg.val ~= 9 then
    print(string.format("\tFail: (3) val = %d, expected %d", arg.val, 9))
    fail = true
end

if not fail then
    print("\tPass")
end
