function ENT:WireError(sM)
  local tI = debug.getinfo(2)
  local sM = tostring(sM or "")
  local sN = tI and tI.name or "Incognito"
  local sO = tostring(self).."."..sN..sM
  self:Print(sO); ErrorNoHalt(sO.."\n"); self:Remove()
end

local function wireUnpackPortInfo(tP)
  if(not WireLib) then return nil end
  local sN, sT, sD = tP[1], tP[2], tP[3]
  sN = ((sN ~= nil) and string.Trim(tostring(sN)) or nil)
  sT = ((sT ~= nil) and string.Trim(tostring(sT)) or "NORMAL")
  sD = ((sD ~= nil) and string.Trim(tostring(sD)) or nil)
  return sN, sT, sD
end

local function wireSetupPorts(oE, sF, tI, bL)
  if(not WireLib) then return oE end
  local iD, tN, tT, tD = 1, {}, {}, {}
  while(tI[iD]) do local sN, sT, sD = wireUnpackPortInfo(tI[iD])
    if(not sN) then oE:WireError("("..sF..")["..iD.."]: Name missing"); return oE end
    if(not sT) then oE:WireError("("..sF..")["..iD.."]: Type missing"); return oE end
    if(not WireLib.DT[sT]) then oE:WireError("("..sF..")["..iD.."]: Type invalid ["..sT.."]"); return oE end
    tN[iD], tT[iD], tD[iD] = sN, sT, sD; iD = (iD + 1) -- Call the provider
  end
  if(bL) then
    for iD = 1, #tN do -- Port name and type is mandatory
      local bS, sE = pcall(WireLib[sF], oE, tN[iD], tT[iD], tD[iD])
      if(not bS) then oE:WireError("("..sF..")["..iD.."]: Error: "..sE); return oE end
    end -- The wire method can process only one port description at a time
  else -- The wiremod method can process multiple ports in one call
    local bS, sE = pcall(WireLib[sF], oE, tN, tT, tD)
    if(not bS) then oE:WireError("("..sF..")["..iD.."]: Error: "..sE); return oE end
  end
  return oE -- Coding effective API. Must always return reference to self
end

function ENT:WireIndex(sK, sN)
  if(not WireLib) then return nil end
  if(sN == nil) then self:WireError("("..sK.."): Name invalid"); return nil end
  local tP, sP = self[sK], tostring(sN); tP = (tP and tP[sP] or nil)
  if(tP == nil) then self:WireError("("..sK..")("..sP.."): Port missing"); return tP, sP end
  return tP, sP -- Returns the dedicated indexed wire I/O port and name
end

function ENT:WireDisconnect(sN)
  if(not WireLib) then return nil end; local tP, sP = self:WireIndex("Outputs", sN)
  if(tP == nil) then self:WireError("("..sP.."): Output missing"); return self end
  WireLib.DisconnectOutput(self, sN); return self -- Disconnects the output
end

function ENT:WireIsConnected(sN)
  if(not WireLib) then return nil end; local tP, sP = self:WireIndex("Inputs", sN)
  if(tP == nil) then self:WireError("("..sP.."): Input missing"); return nil end
  return IsValid(tP.Src) -- When the input exists and connected returns true
end

function ENT:WireRead(sN, bC)
  if(not WireLib) then return nil end; local tP, sP = self:WireIndex("Inputs", sN)
  if(tP == nil) then self:WireError("("..sP.."): Input missing"); return nil end
  if(bC) then return (IsValid(tP.Src) and tP.Value or nil) end; return tP.Value
end

function ENT:WireWrite(sN, vD, bC)
  if(not WireLib) then return self end; local tP, sP = self:WireIndex("Outputs", sN)
  if(tP == nil) then self:WireError("("..sP.."): Output missing"); return self end
  if(bC) then
    local sD = tP.Type; if(sD == nil) then
      self:WireError("("..sP.."): Type missing"); return self end
    local tD = WireLib.DT[sD]; if(tD == nil) then
      self:WireError("("..sP..")("..sD.."): Type undefined"); return self end
    local sT, sZ = type(vD), type(tD.Zero); if(sT ~= sZ) then
      self:WireError("("..sP..")("..sT.."~"..sZ.."): Type mismatch"); return self end
  end
  WireLib.TriggerOutput(self, sP, vD); return self
end

function ENT:WireCreateInputs(...)
  if(not WireLib) then return self end
  return wireSetupPorts(self, "CreateSpecialInputs", {...})
end

function ENT:WireCreateOutputs(...)
  if(not WireLib) then return self end
  return wireSetupPorts(self, "CreateSpecialOutputs", {...})
end

function ENT:WireAdjustInputs(...)
  if(not WireLib) then return self end
  return wireSetupPorts(self, "AdjustSpecialInputs", {...})
end

function ENT:WireAdjustOutputs(...)
  if(not WireLib) then return self end
  return wireSetupPorts(self, "AdjustSpecialOutputs", {...})
end

function ENT:WireRetypeInputs(...)
  if(not WireLib) then return self end
  return wireSetupPorts("RetypeInputs", {...}, true)
end

function ENT:WireRetypeOutputs(...)
  if(not WireLib) then return self end
  return wireSetupPorts("RetypeOutputs", {...}, true)
end
