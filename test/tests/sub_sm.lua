local fail = false
print("Test: sub sm...")

local function state_a(arg)
    arg.val = arg.val + 1
    return stater.NEXT
end

local arg = { val=1 }

local subm = stater({
    { id=1, func=state_a }
})
local sm = stater({
    { id=1, subm=subm },
    { id=2, subm=subm },
    { id=3, subm=subm },
    { id=4, subm=subm }
})

ret = sm:run(arg)
if ret ~= stater.DONE then
    print(string.format("\tFail: ret = %d, expected %d", ret, stater.DONE))
    fail = true
end

if arg.val ~= 5 then
    print(string.format("\tFail: val = %d, expected %d", arg.val, 5))
    fail = true
end

if not fail then
    print("\tPass")
end

