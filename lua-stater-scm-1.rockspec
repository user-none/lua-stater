package = "lua-stater"
version = "scm-1"

source = {
    url = "git://github.com/user-none/lua-stater.git"
}

description = {
    summary    = "Lua state machine",
    homepage   = "https://github.com/user-none/lua-stater.git",
    license    = "MIT/X11",
    maintainer = "John Schember <john@nachtimwald.com>"
}

dependencies = {
    "lua >= 5.3"
}

build = {
    type    = "builtin",
    modules = {
        ["stater"]    = "stater/init.lua"
        ["stater.sm"] = "stater/sm.lua"
    }
}
