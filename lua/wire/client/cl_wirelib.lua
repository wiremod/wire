--[[----------------------------------------------------------
	lua/wire/client/cl_wirelib.lua
	----------------------------------------------------------
	Renders beams
--]]----------------------------------------------------------
local WIRE_SCROLL_SPEED = 	0.5
local WIRE_BLINKS_PER_SECOND = 	2
local Wire_DisableWireRender = 	0

WIRE_CLIENT_INSTALLED = 1



BeamMat = Material("tripmine_laser")
BeamMatHR = Material("Models/effects/comball_tape")

local scroll, scroll_offset, shouldblink = 0, 0, false

--Precache everything we're going to use
local CurTime              = CurTime
local render_SetMaterial   = render.SetMaterial
local render_StartBeam     = render.StartBeam
local render_AddBeam       = render.AddBeam
local render_EndBeam       = render.EndBeam
local render_DrawBeam      = render.DrawBeam
local EntityMeta           = FindMetaTable("Entity")
local IsValid              = EntityMeta.IsValid
local ent_LocalToWorld     = EntityMeta.LocalToWorld
local Vector               = Vector

hook.Add("Think", "Wire.WireScroll", function()
	scroll_offset = CurTime() * WIRE_SCROLL_SPEED
end )

timer.Create("Wire.WireBlink", 1 / WIRE_BLINKS_PER_SECOND, 0, function() -- there's no reason this needs to be in the render hook, no?
	shouldblink = not shouldblink
end)

local nodeTransformer = WireLib.GetComputeIfEntityTransformDirty(function(ent)
	return setmetatable({}, {__index = function(t, k)
		local transformed = ent_LocalToWorld(ent, k)
		t[k] = transformed
		return transformed
	end})
end)

hook.Add("EntityRemoved", "WireLib_Node_Cache_Cleanup", function(ent)
	nodeTransformer[ent] = nil
end)

local mats_cache = {} -- nothing else uses this, it doesn't need to be global
local function getmat( mat )
	if not mats_cache[ mat ] then mats_cache[ mat ] = Material(mat) end --Just not to create a material every frame
	return mats_cache[ mat ]
end

function Wire_Render(ent)
	if Wire_DisableWireRender ~= 0 then return end	--We shouldn't render anything
	if not IsValid(ent) then return end

	local wires = ent.WirePaths
	if not wires then
		ent.WirePaths = {}
		net.Start("WireLib.Paths.RequestPaths")
			net.WriteEntity(ent)
		net.SendToServer()
		return
	end

	if not next(wires) then return end

	local blink = shouldblink and ent:GetNWString("BlinkWire")
	--CREATING (Not assigning a value) local variables OUTSIDE of cycle a bit faster
	local start, color, nodes, len, endpos, node, node_ent, last_node_ent, vector_cache
	for net_name, wiretbl in pairs(wires) do

		width = wiretbl.Width

		if width > 0 and blink ~= net_name then
			last_node_ent = ent
			vector_cache = nodeTransformer(ent)
			start = vector_cache[wiretbl.StartPos]
			color = wiretbl.Color
			nodes = wiretbl.Path
			scroll = scroll_offset
			len = #nodes
			if len > 0 then
				render_SetMaterial( getmat(wiretbl.Material) )	--Maybe every wire addon should precache it's materials on setup?
				render_StartBeam(len * 2 + 1)
				render_AddBeam(start, width, scroll, color)

				for j=1, len do
					node = nodes[j]
					node_ent = node.Entity
					if IsValid( node_ent ) then
						if node_ent ~= last_node_ent then
							last_node_ent = node_ent
							vector_cache = nodeTransformer(node_ent)
						end
						endpos = vector_cache[node.Pos]
						scroll = scroll + endpos:Distance(start) / 10
						render_AddBeam(endpos, width, scroll, color)
						render_AddBeam(endpos, width, scroll, color) -- A second beam in the same position ensures the line stays consistent and doesn't change width/become distorted.
						start = endpos
					end
				end

				render_EndBeam()
			end
		end
	end
end


local function Wire_GetWireRenderBounds(ent)
	if not IsValid(ent) then return end

	local bbmin, bbmax = ent:OBBMins(), ent:OBBMaxs()

	if ent.WirePaths then
		local nodes, len, node_ent, nodepos
		for net_name, wiretbl in pairs(ent.WirePaths) do
			nodes = wiretbl.Path
			len = #nodes
			for j=1, len do
				node_ent = nodes[j].Entity
				nodepos = nodes[j].Pos
				if (node_ent:IsValid()) then
					nodepos = ent:WorldToLocal(node_ent:LocalToWorld(nodepos))

					if nodepos.x < bbmin.x then bbmin.x = nodepos.x end
					if nodepos.y < bbmin.y then bbmin.y = nodepos.y end
					if nodepos.z < bbmin.z then bbmin.z = nodepos.z end
					if nodepos.x > bbmax.x then bbmax.x = nodepos.x end
					if nodepos.y > bbmax.y then bbmax.y = nodepos.y end
					if nodepos.z > bbmax.z then bbmax.z = nodepos.z end
				end
			end
		end
	end

	if ent.ExtraRBoxPoints then
		for _,point in pairs( ent.ExtraRBoxPoints ) do
			if point.x < bbmin.x then bbmin.x = point.x end
			if point.y < bbmin.y then bbmin.y = point.y end
			if point.z < bbmin.z then bbmin.z = point.z end
			if point.x > bbmax.x then bbmax.x = point.x end
			if point.y > bbmax.y then bbmax.y = point.y end
			if point.z > bbmax.z then bbmax.z = point.z end
		end
	end
	return bbmin, bbmax
end


function Wire_UpdateRenderBounds(ent)
	local bbmin, bbmax = Wire_GetWireRenderBounds(ent)
	ent:SetRenderBounds(bbmin, bbmax)
end

local function WireDisableRender(pl, cmd, args)
	if args[1] then
		Wire_DisableWireRender = tonumber(args[1])
	end
	Msg("\nWire DisableWireRender/WireRenderMode = "..tostring(Wire_DisableWireRender).."\n")
end

concommand.Add( "cl_Wire_DisableWireRender", WireDisableRender )
concommand.Add( "cl_Wire_SetWireRenderMode", WireDisableRender )


function Wire_DrawTracerBeam( ent, beam_num, hilight, beam_length )
	local entsTbl = EntityMeta.GetTable( ent )
	local beam_length = beam_length or entsTbl.GetBeamLength(ent, beam_num)
	if beam_length == 0 then return end
	local pos = EntityMeta.GetPos(ent)
	local trace = {}
	local target = entsTbl.GetTarget and entsTbl.GetTarget(ent) or nil

	if target and ( target.X ~= 0 or target.Y ~= 0 or target.Z ~= 0 ) then
		trace.endpos = pos + ( target - pos ):GetNormalized()*beam_length
		if trace.endpos[1] ~= trace.endpos[1] then trace.endpos = pos+Vector(entsTbl.GetBeamLength(ent), 0, 0) end
	elseif (entsTbl.GetSkewX and entsTbl.GetSkewY) then
		local x, y = entsTbl.GetSkewX(ent, beam_num), entsTbl.GetSkewY(ent, beam_num)
		if x ~= 0 or y ~= 0 then
			local skew = Vector(x, y, 1)
			skew = skew*(beam_length/skew:Length())
			local beam_x = EntityMeta.GetRight(ent)*skew.x
			local beam_y = EntityMeta.GetForward(ent)*skew.y
			local beam_z = EntityMeta.GetUp(ent)*skew.z
			trace.endpos = pos + beam_x + beam_y + beam_z
		else
			trace.endpos = pos + EntityMeta.GetUp(ent)*beam_length
		end
	else
		trace.endpos = pos + EntityMeta.GetUp(ent)*beam_length
	end

	trace.start = pos
	trace.filter = { ent }
	if ent:GetNWBool("TraceWater") then trace.mask = MASK_ALL end
	trace = util.TraceLine(trace)
	--Update render bounds
	ent.ExtraRBoxPoints = ent.ExtraRBoxPoints or {}
	ent.ExtraRBoxPoints[beam_num] = EntityMeta.WorldToLocal(ent, trace.HitPos)

	render_SetMaterial(BeamMat)
	render_DrawBeam(pos, trace.HitPos, 6, 0, 10, EntityMeta.GetColor(ent))
	if hilight then	--This is intended behaivour
		render_SetMaterial(BeamMatHR)
		render_DrawBeam(pos, trace.HitPos, 6, 0, 10, Color(255,255,255,255))
	end
end

hook.Add("InitPostEntity", "language_strings", function()
	for class, tbl in pairs(scripted_ents.GetList()) do
		if tbl.t.PrintName and tbl.t.PrintName ~= "" then
			language.Add( class, tbl.t.PrintName )
		end
	end
end)

if not CanRunConsoleCommand then
	function CanRunConsoleCommand() return false end
	hook.Add("Initialize", "CanRunConsoleCommand", function()
		function CanRunConsoleCommand() return true end
	end)
end

function Derma_StringRequestNoBlur(...)
	local panel = Derma_StringRequest(...)
	panel:SetBackgroundBlur(false)
	return panel
end

function Derma_QueryNoBlur(...)
	local panel = Derma_Query(...)
	panel:SetBackgroundBlur(false)
	return panel
end

function WireLib.hud_debug(text, oneframe)
	hook.Add("HUDPaint","wire_hud_debug",function()
		if oneframe then hook.Remove("HUDPaint", "wire_hud_debug") end
		draw.DrawText(text, "Trebuchet24", 10, ScrH() / 5, color_white, 0)
	end)
end

local old_renderhalos = WireLib.__old_renderhalos or hook.GetTable().PostDrawEffects.RenderHalos
WireLib.__old_renderhalos = old_renderhalos
if old_renderhalos ~= nil then
	hook.Add("PostDrawEffects","RenderHalos", function()
		if hook.Run("ShouldDrawHalos") == false then return end

		old_renderhalos()
	end)
else
	ErrorNoHalt("Wiremod RenderHalos detour failed (RenderHalos hook not found)!")
end

-- Notify --

local severity2word = {
	[2] = "warning",
	[3] = "error"
}

local notify_antispam = 0 -- Used to avoid spamming sounds to the player

--- Sends a colored message to the player's chat.
--- When used serverside, setting the player as nil will only inform the server.
--- When used clientside, the first argument is ignored and only the local player is informed.
---@param ply Player | Player[]?
---@param msg string
---@param severity WireLib.NotifySeverity?
---@param chatprint boolean?
---@param color Color?
local function notify(ply, msg, severity, chatprint, color)
	if not severity then severity = 1 end
	if chatprint == nil then chatprint = severity < 2 end

	if chatprint then
		chat.AddText(unpack(WireLib.NotifyBuilder(msg, severity, color)))
		chat.PlaySound()
	else
		MsgC(unpack(WireLib.NotifyBuilder(msg, severity, color)))
		local time = CurTime()
		if severity > 1 and notify_antispam < time then
			notify_antispam = time + 1
			notification.AddLegacy(string.format("Wiremod %s! Check your console for details", severity2word[severity]), NOTIFY_ERROR, 5)
			surface.PlaySound(severity == 3 and "vo/k_lab/kl_fiddlesticks.wav" or "buttons/button22.wav")
		end
	end
end
WireLib.Notify = notify


WireLib.Net.Trivial.Receive("notify", function()
	local severity = net.ReadUInt(4)
	local color = net.ReadBool() and net.ReadColor(false) or nil
	local msg = util.Decompress(net.ReadData(net.ReadUInt(11)))
	notify(nil, msg, severity, net.ReadBool(), color)
end)