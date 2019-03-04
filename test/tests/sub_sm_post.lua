local fail = false
print("Test: sub sm post...")

local function state_a(arg)
    arg.val = arg.val + 1
    return stater.NEXT
end

local function state_b(arg)
    arg.val = arg.val + 10
    return stater.NEXT
end

local function state_c(arg)
    arg.val = 777
end

local function post_next(status, arg)
    return stater.NEXT
end

local function post_prev(status, arg)
    if arg.val < 100 then
        return stater.PREV
    end
    return stater.NEXT
end

local function post_skip(status, arg)
    return stater.NEXT, 5
end

local function post_error(status, arg)
    return stater.ERROR_STATE
end

local arg = { val=1 }

local subm = stater({
    { id=1, func=state_a }
})
local subm2= stater({
    { id=1, func=state_b }
})
local sm = stater({
    { id=1, subm=subm, post=post_next },
    { id=2, subm=subm, post=post_prev },
    { id=3, subm=subm2, post=post_skip },
    { id=4, func=state_c },
    { id=5, subm=subm, post=post_error }
})

ret = sm:run(arg)
if ret ~= stater.ERROR_STATE then
    print(string.format("\tFail: ret = %d, expected %d", ret, stater.ERROR_STATE))
    fail = true
end

if arg.val ~= 112 then
    print(string.format("\tFail: val = %d, expected %d", arg.val, 112))
    fail = true
end

if not fail then
    print("\tPass")
end
