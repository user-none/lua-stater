local fail = false
print("Test: csm done...")

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
local csm = stater(states)

local sm = stater(nil, stater.FLAG_CLEANUP_DONE)
sm:add_single({ id=1, func=state_a, csm=csm })
sm:add_single({ id=2, func=state_b, csm=csm })
sm:add_single({ id=3, func=state_c, csm=csm })

ret = sm:run(arg)
if ret ~= stater.DONE then
    print(string.format("\tFail: ret = %d, expected %d", ret, stater.DONE))
    fail = true
end

if arg.val ~= 12 then
    print(string.format("\tFail: val = %d, expected %d", arg.val, 12))
    fail = true
end

if not fail then
    print("\tPass")
end
