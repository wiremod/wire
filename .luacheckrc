-- This file will be read by Luacheck <https://github.com/mpeterv/luacheck>.
-- It's primarily to specify what globals are available across all files.

-- string values with integer keys mean read-only globals
stds.garrysmod = {
  "AddCSLuaFiles",
}

-- string keys mean read-write globals
stds.wiremod = {
  BeamNetVars = true,
  CPULib = true,
  FLIR = true,
  GPULib = true,
  E2Lib = true,
  E2Helper = true,
  HCOMP = true,
  WireLib = true,
}
