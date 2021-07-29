ENT.Type = "point"
ENT.DisableDuplicator = true
ENT.Purpose = "It is an implementation detail entity used to hook outputs from other entities and pass them to E2"

function ENT:AcceptInput(inputName, activator, caller, param)
    local output = string.match(inputName, "^HookOutput_([%w_]+)$")

    if output then
        hook.Run("stpM64_E2_OutputHook", activator, caller, output, param)
        return true
    end

    return false
end