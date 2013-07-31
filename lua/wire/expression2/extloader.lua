--[[
  Loading extensions
]] --

-- Save E2's metatable for wire_expression2_reload
if ENT then
    local wire_expression2_ENT = ENT
    function wire_expression2_reload(ply, cmd, args)
        if IsValid(ply) and ply:IsPlayer() and not ply:IsSuperAdmin() and not game.SinglePlayer() then return end

        Msg("Calling destructors for all Expression2 chips.\n")
        local chips = ents.FindByClass("gmod_wire_expression2")
        for _, chip in ipairs(chips) do
            if not chip.error then
                chip:PCallHook('destruct')
            end
            chip.script = nil
        end
        Msg("Reloading Expression2 extensions.\n")

        ENT = wire_expression2_ENT
        wire_expression2_is_reload = true
        include("wire/expression2/extloader.lua")
        wire_expression2_is_reload = nil
        ENT = nil

        Msg("Calling constructors for all Expression2 chips.\n")
        wire_expression2_prepare_functiondata()
        if not args or args[1] ~= "nosend" then
            wire_expression2_sendfunctions(player.GetAll())
        end
        for _, chip in ipairs(chips) do
            pcall(chip.OnRestore, chip)
        end
        Msg("Done reloading Expression2 extensions.\n")
    end

    concommand.Add("wire_expression2_reload", wire_expression2_reload)
end

wire_expression2_reset_extensions()

include("extpp.lua")

local function luaExists(luaname)
    return #file.Find(luaname, "LUA") ~= 0
end

local included_files = {}

-- parses typename/typeid associations from a file and stores info about the file for later use by e2_include_finalize/e2_include_pass2
local function e2_include(name)
    local path, filename = string.match(name, "^(.-/?)([^/]*)$")

    local cl_name = path .. "cl_" .. filename
    if luaExists("wire/expression2/" .. cl_name) then
        -- If a file of the same name prefixed with cl_ exists, send it to the client and load it there.
        AddCSE2File(cl_name)
    end

    local luaname = "wire/expression2/" .. name
    local contents = file.Read(luaname, "LUA") or ""
    e2_extpp_pass1(contents)
    table.insert(included_files, { name, luaname, contents })
end

-- parses and executes an extension
local function e2_include_pass2(name, luaname, contents)
    local ok, ret = pcall(e2_extpp_pass2, contents)
    if not ok then
        ErrorNoHalt(luaname .. ret .. "\n")
        return
    end

    if not ret then
        -- e2_extpp_pass2 returned false => file didn't need preprocessing => use the regular means of inclusion
        return include(name)
    end
    -- file needed preprocessing => Run the processed file
    RunStringEx(ret, luaname)
    __e2setcost(nil) -- Reset ops cost at the end of each file
end

local function e2_include_finalize()
    for _, info in ipairs(included_files) do
        e2_include_pass2(unpack(info))
    end
    included_files = nil
    e2_include = nil
end

-- end preprocessor stuff

e2_include("builtin/core.lua")
e2_include("builtin/array.lua")
e2_include("builtin/number.lua")
e2_include("builtin/vector.lua")
e2_include("builtin/string.lua")
e2_include("builtin/angle.lua")
e2_include("builtin/entity.lua")
e2_include("builtin/player.lua")
e2_include("builtin/timer.lua")
e2_include("builtin/selfaware.lua")
e2_include("builtin/unitconv.lua")
e2_include("builtin/wirelink.lua")
e2_include("builtin/console.lua")
e2_include("builtin/find.lua")
e2_include("builtin/files.lua")
e2_include("builtin/cl_files.lua")
e2_include("builtin/globalvars.lua")
e2_include("builtin/ranger.lua")
e2_include("builtin/sound.lua")
e2_include("builtin/color.lua")
e2_include("builtin/serverinfo.lua")
e2_include("builtin/chat.lua")
e2_include("builtin/constraint.lua")
e2_include("builtin/weapon.lua")
e2_include("builtin/gametick.lua")
e2_include("builtin/npc.lua")
e2_include("builtin/matrix.lua")
e2_include("builtin/vector2.lua")
e2_include("builtin/signal.lua")
e2_include("builtin/bone.lua")
e2_include("builtin/table.lua")
e2_include("builtin/glon.lua")
e2_include("builtin/hologram.lua")
e2_include("builtin/complex.lua")
e2_include("builtin/bitwise.lua")
e2_include("builtin/quaternion.lua")
e2_include("builtin/debug.lua")
e2_include("builtin/http.lua")
e2_include("builtin/compat.lua")
e2_include("builtin/custom.lua")
e2_include("builtin/datasignal.lua")
e2_include("builtin/egpfunctions.lua")
e2_include("builtin/functions.lua")
e2_include("builtin/strfunc.lua")

do
    local list = file.Find("wire/expression2/custom/*.lua", "LUA")
    for _, filename in pairs(list) do
        if filename:sub(1, 3) == "cl_" then
            -- If the is prefixed with "cl_", send it to the client and load it there.
            AddCSE2File("custom/" .. filename)
        else
            e2_include("custom/" .. filename)
        end
    end
end

e2_include_finalize()

wire_expression2_CallHook("postinit")
