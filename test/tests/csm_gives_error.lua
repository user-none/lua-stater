local fail = false
print("Test: csm gives error...")

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

local function state_err(arg)
    return stater.ERROR_STATE
end

local arg = { val=0 }

local csm = stater()
csm:add_single({ id=1, func=state_a })
csm:add_single({ id=2, func=state_b })
csm:add_single({ id=3, func=state_err })
csm:add_single({ id=4, func=state_c })

local sm = stater(nil, stater.FLAG_CLEANUP_DONE)
sm:add_single({ id=1, func=state_a, csm=csm })
sm:add_single({ id=2, func=state_b, csm=csm })
sm:add_single({ id=3, func=state_c, csm=csm })

ret = sm:run(arg)
if ret ~= stater.DONE then
    print(string.format("\tFail: ret = %d, expected %d", ret, stater.DONE))
    fail = true
end

if arg.val ~= 9 then
    print(string.format("\tFail: val = %d, expected %d", arg.val, 9))
    fail = true
end

if not fail then
    print("\tPass")
end
