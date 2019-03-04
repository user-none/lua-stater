local fail = false
print("Test: csm csm csm...")

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

local csm3 = stater(nil, stater.FLAG_CLEANUP_DONE)
csm3:add_single({ id=1, func=state_a })
csm3:add_single({ id=2, func=state_b })
csm3:add_single({ id=3, func=state_c })

local csm2 = stater(nil, stater.FLAG_CLEANUP_DONE)
csm2:add_single({ id=1, func=state_a, csm=csm3 })
csm2:add_single({ id=2, func=state_b, csm=csm3 })
csm2:add_single({ id=3, func=state_c, csm=csm3 })

local csm1 = stater(nil, stater.FLAG_CLEANUP_DONE)
csm1:add_single({ id=1, func=state_a, csm=csm2 })
csm1:add_single({ id=2, func=state_b, csm=csm2 })
csm1:add_single({ id=3, func=state_c, csm=csm2 })

local sm = stater(nil, stater.FLAG_CLEANUP_DONE)
sm:add_single({ id=1, func=state_a, csm=csm1 })
sm:add_single({ id=2, func=state_b, csm=csm1 })
sm:add_single({ id=3, func=state_c, csm=csm1 })

ret = sm:run(arg)
if ret ~= stater.DONE then
    print(string.format("\tFail: ret = %d, expected %d", ret, stater.DONE))
    fail = true
end

if arg.val ~= 120 then
    print(string.format("\tFail: val = %d, expected %d", arg.val, 120))
    fail = true
end

if not fail then
    print("\tPass")
end
