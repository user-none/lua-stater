local fail = false
print("Test: wait...")

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
    if arg.val < 11 then
        return stater.WAIT
    end
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
if ret ~= stater.WAIT then
    print(string.format("\tFail: Did not wait, ret = %d", ret))
    fail = true
end

repeat
    ret = sm:run(arg)
until ret ~= stater.WAIT

if ret ~= stater.DONE then
    print(string.format("\tFail: ret = %d, expected %d", ret, stater.DONE))
    fail = true
end

if arg.val ~= 11 then
    print(string.format("\tFail: val = %d, expected %d", arg.val, 11))
    fail = true
end

if not fail then
    print("\tPass")
end
