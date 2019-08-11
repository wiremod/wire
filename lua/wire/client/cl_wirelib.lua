local WIRE_SCROLL_SPEED = 0.5
local WIRE_BLINKS_PER_SECOND = 2
local CurPathEnt = {}
local Wire_DisableWireRender = 0
WireLib.Wire_GrayOutWires = false

WIRE_CLIENT_INSTALLED = 1

--Msg("loading materials\n")
list.Add( "WireMaterials", "cable/rope_icon" )
list.Add( "WireMaterials", "cable/cable2" )
list.Add( "WireMaterials", "cable/xbeam" )
list.Add( "WireMaterials", "cable/redlaser" )
list.Add( "WireMaterials", "cable/blue_elec" )
list.Add( "WireMaterials", "cable/physbeam" )
list.Add( "WireMaterials", "cable/hydra" )
--new wire materials by Acegikmo
list.Add( "WireMaterials", "arrowire/arrowire" )
list.Add( "WireMaterials", "arrowire/arrowire2" )

local mats = {
	["tripmine_laser"] = Material("tripmine_laser"),
	["Models/effects/comball_tape"] = Material("Models/effects/comball_tape")
}
for _,mat in pairs(list.Get( "WireMaterials" )) do
	--Msg("loading material: ",mat,"\n")
	mats[mat] = Material(mat)
end
local function getmat( mat )
	if mats[mat] == nil then
		mats[mat] = Material(mat)
	end
	return mats[mat]
end
local beam_mat = mats["tripmine_laser"]
local beamhi_mat = mats["Models/effects/comball_tape"]

local lastrender, scroll, shouldblink = 0, 0, false
function Wire_Render(ent)
	if (Wire_DisableWireRender == 0) then
		local wires = ent.WirePaths
		if wires then
			if next(wires) then
				local t = CurTime()
				if lastrender ~= t then
					local w, f = math.modf(t*WIRE_BLINKS_PER_SECOND)
					shouldblink = f < 0.5
					scroll = t*WIRE_SCROLL_SPEED
					lastrender = t
				end

				local blink = shouldblink and ent:GetNWString("BlinkWire")

				for net_name, wiretbl in pairs(wires) do
					local width = wiretbl.Width
					if width > 0 and blink ~= net_name then
						local start = wiretbl.StartPos
						if IsValid(ent) then start = ent:LocalToWorld(start) end
						local color = wiretbl.Color
						if WireLib.Wire_GrayOutWires then
							local h, s, v = ColorToHSV(color)
							v = 0.175
							local tmpColor = HSVToColor(h, s, v)
							color = Color(tmpColor.r, tmpColor.g, tmpColor.b, tmpColor.a) -- HSVToColor does not return a proper Color structure.
						end

						local nodes = wiretbl.Path
						local len = #nodes
						if len>0 then
							render.SetMaterial(getmat(wiretbl.Material))
							render.StartBeam(len * 2 + 1)
							render.AddBeam(start, width, scroll, color)

							for j=1, len do
								local node = nodes[j]
								local node_ent = node.Entity
								if IsValid(node_ent) then
									local endpos = node_ent:LocalToWorld(node.Pos)

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
		else
			ent.WirePaths = {}
			net.Start("WireLib.Paths.RequestPaths")
				net.WriteEntity(ent)
			net.SendToServer()
		end
	end
end


local function Wire_GetWireRenderBounds(ent)
	if not IsValid(ent) then return end

	local bbmin = ent:OBBMins()
	local bbmax = ent:OBBMaxs()

	if ent.WirePaths then
		for net_name, wiretbl in pairs(ent.WirePaths) do
			local nodes = wiretbl.Path
			local len = #nodes
			for j=1, len do
				local node_ent = nodes[j].Entity
				local nodepos = nodes[j].Pos
				if (node_ent:IsValid()) then
					nodepos = ent:WorldToLocal(node_ent:LocalToWorld(nodepos))

					if (nodepos.x < bbmin.x) then bbmin.x = nodepos.x end
					if (nodepos.y < bbmin.y) then bbmin.y = nodepos.y end
					if (nodepos.z < bbmin.z) then bbmin.z = nodepos.z end
					if (nodepos.x > bbmax.x) then bbmax.x = nodepos.x end
					if (nodepos.y > bbmax.y) then bbmax.y = nodepos.y end
					if (nodepos.z > bbmax.z) then bbmax.z = nodepos.z end
				end
			end
		end
	end

	if (ent.ExtraRBoxPoints) then
		for _,point_l in pairs( ent.ExtraRBoxPoints ) do
			local point = point_l
			if (point.x < bbmin.x) then bbmin.x = point.x end
			if (point.y < bbmin.y) then bbmin.y = point.y end
			if (point.z < bbmin.z) then bbmin.z = point.z end
			if (point.x > bbmax.x) then bbmax.x = point.x end
			if (point.y > bbmax.y) then bbmax.y = point.y end
			if (point.z > bbmax.z) then bbmax.z = point.z end
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
	if (beam_length > 0) then

		local x, y = 0, 0
		if (ent.GetSkewX and ent.GetSkewY) then
			x, y = ent:GetSkewX(beam_num), ent:GetSkewY(beam_num)
		end

		local start, ang = ent:GetPos(), ent:GetAngles()

		if (ent.ls != start or ent.la != ang or ent.ll != beam_length or ent.lx != x or ent.ly != y) then
			ent.ls, ent.la = start, ang

			if (ent.ll != beam_length or ent.lx != x or ent.ly != y) then
				ent.ll, ent.lx, ent.ly = beam_length, x, y

				if (x == 0 and y == 0) then
					ent.endpos = start + (ent:GetUp() * beam_length)
				else
					local skew = Vector(x, y, 1)
					skew = skew*(beam_length/skew:Length())
					local beam_x = ent:GetRight()*skew.x
					local beam_y = ent:GetForward()*skew.y
					local beam_z = ent:GetUp()*skew.z
					ent.endpos = start + beam_x + beam_y + beam_z
				end
				ent.ExtraRBoxPoints = ent.ExtraRBoxPoints or {}
				ent.ExtraRBoxPoints[beam_num] = ent:WorldToLocal(ent.endpos)
			else
				ent.endpos = ent:LocalToWorld(ent.ExtraRBoxPoints[beam_num])
			end
		end

		local trace = {}
		trace.start = start
		trace.endpos = ent.endpos
		trace.filter = { ent }
		if ent:GetNWBool("TraceWater") then trace.mask = MASK_ALL end
		trace = util.TraceLine(trace)

		render.SetMaterial(beam_mat)
		render.DrawBeam(start, trace.HitPos, 6, 0, 10, ent:GetColor())
		if (hilight) then
			render.SetMaterial(beamhi_mat)
			render.DrawBeam(start, trace.HitPos, 6, 0, 10, Color(255,255,255,255))
		end
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
	local f = math.max

	function math.max(...)
		local ret = f(...)

		for i = 1,20 do
			local name, value = debug.getlocal(2, i)
			if name == "Window" then
				value:SetBackgroundBlur( false )
				break
			end
		end

		return ret
	end
	local ok, ret = xpcall(Derma_StringRequest, debug.traceback, ...)
	math.max = f

	if not ok then error(ret, 0) end
	return ret
end

function WireLib.hud_debug(text, oneframe)
	hook.Add("HUDPaint","wire_hud_debug",function()
		if oneframe then hook.Remove("HUDPaint","wire_hud_debug") end
		draw.DrawText(text,"Trebuchet24",10,200,Color(255,255,255,255),0)
	end)
end