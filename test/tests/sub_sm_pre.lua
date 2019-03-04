local fail = false
print("Test: sub sm pre...")

local function state_a(arg)
    arg.val = arg.val + 1
    return stater.NEXT
end

local function state_b(arg)
    arg.val = arg.val + 1000
    return stater.NEXT
end

local function sm_pre_run(arg)
    return true
end

local function sm_pre_skip(arg)
    return false
end

local function sm_pre_skip2(arg)
    return false, 4
end

local arg = { val=1 }

local subm = stater({
    { id=1, func=state_a }
})
local subm2= stater({
    { id=1, func=state_b }
})
local sm = stater({
    { id=1, subm=subm, pre=sm_pre_skip },
    { id=2, subm=subm, pre=sm_pre_skip2 },
    { id=3, subm=subm2 },
    { id=4, subm=subm, pre=sm_pre_run }
})

ret = sm:run(arg)
if ret ~= stater.DONE then
    print(string.format("\tFail: ret = %d, expected %d", ret, stater.DONE))
    fail = true
end

if arg.val ~= 2 then
    print(string.format("\tFail: val = %d, expected %d", arg.val, 2))
    fail = true
end

if not fail then
    print("\tPass")
end
