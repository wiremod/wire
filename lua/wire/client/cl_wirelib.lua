--[[----------------------------------------------------------
	lua/wire/client/cl_wirelib.lua
	----------------------------------------------------------
	Renders beams
--]]----------------------------------------------------------
local WIRE_SCROLL_SPEED = 	0.5
local WIRE_BLINKS_PER_SECOND = 	2
local Wire_DisableWireRender = 	0

list.Add( "WireMaterials", "cable/rope_icon" )
list.Add( "WireMaterials", "cable/cable2" )
list.Add( "WireMaterials", "cable/xbeam" )
list.Add( "WireMaterials", "cable/redlaser" )
list.Add( "WireMaterials", "cable/blue_elec" )
list.Add( "WireMaterials", "cable/physbeam" )
list.Add( "WireMaterials", "cable/hydra" )
list.Add( "WireMaterials", "arrowire/arrowire" )
list.Add( "WireMaterials", "arrowire/arrowire2" )

list.Add( "WireMaterials", "tripmine_laser" )
list.Add( "WireMaterials", "Models/effects/comball_tape" )

WireLib.Wire_GrayOutWires = false
WIRE_CLIENT_INSTALLED = 1

mats_cache = {
	["tripmine_laser"] = Material("tripmine_laser"),
	["Models/effects/comball_tape"] = Material("Models/effects/comball_tape")
}	 

BeamMat = Material("tripmine_laser")
BeamMatHR = Material("Models/effects/comball_tape")
local lastrender, scroll, shouldblink = 0, 0, false

--Precache everything we're going to use
local CurTime = CurTime 			--Yes, in lua we can do this

local function getmat( mat )
	if not mats_cache[ mat ] then mats_cache[ mat ] = Material(mat) end --Just not to create a material every frame
	return mats_cache[mat]
end

function Wire_Render(ent)
	if Wire_DisableWireRender ~= 0 then return end	--We shouldn't render anything
	
	local wires = ent.WirePaths
	if not wires then
		ent.WirePaths = {}
		net.Start("WireLib.Paths.RequestPaths")
			net.WriteEntity(ent)
		net.SendToServer()
		return
	end
	
	if not next(wires) then return end
	
	local t = CurTime()
	if lastrender ~= t then
		local w, f = math.modf(t*WIRE_BLINKS_PER_SECOND)
		shouldblink = f < 0.5
		scroll = t*WIRE_SCROLL_SPEED
		lastrender = t
	end

	local blink = shouldblink and ent:GetNWString("BlinkWire")
	--CREATING (Not assigning a value) local variables OUTSIDE of cycle a bit faster
	local start, color, nodes, len, h, s, v, tmpColor, endpos, node, node_ent
	for net_name, wiretbl in pairs(wires) do
	
		width = wiretbl.Width
		if width > 0 and blink ~= net_name then
			start = IsValid(ent) and ent:LocalToWorld(wiretbl.StartPos) or wiretbl.StartPos
			color = wiretbl.Color
			
			if WireLib.Wire_GrayOutWires then
				h, s, v = ColorToHSV(color)
				v = 0.175
				tmpColor = HSVToColor(h, s, v)
				color = Color(tmpColor.r, tmpColor.g, tmpColor.b, tmpColor.a) -- HSVToColor does not return a proper Color structure.
			end

			nodes = wiretbl.Path
			len = #nodes
			if len>0 then
				render.SetMaterial( getmat(wiretbl.Material) )	--Maybe every wire addon should precache it's materials on setup?
				render.StartBeam(len * 2 + 1)
				render.AddBeam(start, width, scroll, color)
				
				for j=1, len do
					node = nodes[j]
					node_ent = node.Entity
					if IsValid( node_ent ) then
						endpos = node_ent:LocalToWorld(node.Pos)
						scroll = scroll+(endpos-start):Length()/10
						render.AddBeam(endpos, width, scroll, color)
						render.AddBeam(endpos, width, scroll, color) -- A second beam in the same position ensures the line stays consistent and doesn't change width/become distorted.
						start = endpos
					end
				end
				
				render.EndBeam()
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
	local beam_length = beam_length or ent:GetBeamLength(beam_num)
	if beam_length == 0 then return end
	local pos = ent:GetPos()
	local trace = {}
	
	if ent.GetTarget and ( ent:GetTarget().X ~= 0 or ent:GetTarget().Y ~= 0 or ent:GetTarget().Z ~= 0 ) then
		trace.endpos = pos + ( ent:GetTarget() - pos ):GetNormalized()*beam_length
		if trace.endpos[1] ~= trace.endpos[1] then trace.endpos = pos+Vector(ent:GetBeamLength(), 0, 0) end
	elseif (ent.GetSkewX and ent.GetSkewY) then
		local x, y = ent:GetSkewX(beam_num), ent:GetSkewY(beam_num)
		if x ~= 0 or y ~= 0 then
			local skew = Vector(x, y, 1)
			skew = skew*(beam_length/skew:Length())
			local beam_x = ent:GetRight()*skew.x
			local beam_y = ent:GetForward()*skew.y
			local beam_z = ent:GetUp()*skew.z
			trace.endpos = pos + beam_x + beam_y + beam_z
		else
			trace.endpos = pos + ent:GetUp()*beam_length
		end
	else
		trace.endpos = pos + ent:GetUp()*beam_length
	end
	
	trace.start = pos
	trace.filter = { ent }
	if ent:GetNWBool("TraceWater") then trace.mask = MASK_ALL end
	trace = util.TraceLine(trace)
	--Update render bounds
	ent.ExtraRBoxPoints = ent.ExtraRBoxPoints or {}
	ent.ExtraRBoxPoints[beam_num] = ent:WorldToLocal(trace.HitPos)
	
	render.SetMaterial(BeamMat)
	render.DrawBeam(pos, trace.HitPos, 6, 0, 10, ent:GetColor())
	if hilight then	--This is intended behaivour
		render.SetMaterial(BeamMatHR)
		render.DrawBeam(pos, trace.HitPos, 6, 0, 10, Color(255,255,255,255))
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
		if oneframe then hook.Remove("HUDPaint","wire_hud_debug") end
		draw.DrawText(text,"Trebuchet24",10,200,Color(255,255,255,255),0)
	end)
end
