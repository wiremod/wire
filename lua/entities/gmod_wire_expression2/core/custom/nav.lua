local MAP_HAS_NAV = navmesh.IsLoaded()
hook.Add("PlayerInitialSpawn","__e2_MAP_HAS_NAV",function()
	MAP_HAS_NAV = navmesh.IsLoaded()
	hook.Remove("PlayerInitialSpawn","__e2_MAP_HAS_NAV")
end )

local NULL_MESH = navmesh.GetNavAreaByID(0)
local NULL_VEC = Vector()
local NULL_TABLE = {}

local aStarLoopCheck = 0
local ASTAR_OP_MULTIPLIER = 10

local Clamp = math.Clamp
local floor = math.floor

--------------------

registerType("navmesh", "xnv", NULL_MESH,
	nil,
	nil,
	function(retval)
		if retval == nil then return end
		if IsValid(retval) then return end
		local _type = type(retval)
		if _type~="CNavArea" then error("Return value is neither nil nor a CNavArea, but a "..type(retval).."!",0) end
	end,
	function(v)
		return type(v)~="CNavArea"
	end
)

__e2setcost(5)

registerOperator("ass", "xnv", "xnv", function(self, args)
	local op1, op2, scope = args[2], args[3], args[4]
	local      rv2 = op2[1](self, op2)
	self.Scopes[scope][op1] = rv2
	self.Scopes[scope].vclk[op1] = true
	return rv2
end )

e2function number operator_is(navmesh nav)
	if IsValid(nav) then return 1 else return 0 end
end

e2function number operator==(navmesh lhs, navmesh rhs)
	if lhs == rhs then return 1 else return 0 end
end

e2function number operator!=(navmesh lhs, navmesh rhs)
	if lhs ~= rhs then return 1 else return 0 end
end

--------------------

E2Lib.RegisterExtension("nav", false, "Read navmesh data from the map if it has one","Experimental, may be unreasonably costly.")

--------------------

local function NavBounds(nav)
	if not IsValid(nav) then return NULL_TABLE end
	local t = NULL_TABLE
	local c = nav:GetCenter()
	local mx, my, mz, MX, MY, MZ = c.x, c.y, c.z, c.x, c.y, c.z
	for i=1,4 do
		t[i] = nav:GetCorner(i-1)
		mx = math.min(t[i].x, mx)
		my = math.min(t[i].y, my)
		mz = math.min(t[i].z, mz)
		MX = math.max(t[i].x, MX)
		MY = math.max(t[i].y, MY)
		MZ = math.max(t[i].z, MZ)
	end
	return { Vector(mx, my, mz), Vector(MX, MY, MZ) }
end

-------------------- TODO: refactor/rewrite Astar to remove more garrycode such as continue

function Astar(start, goal)
	if not IsValid(start) or not IsValid(goal) then return false end
	if start == goal then return true end
	
	start:ClearSearchLists()
	
	start:AddToOpenList()
	
	local cameFrom = NULL_TABLE
	
	aStarLoopCheck = 0
	local aStarIterator = 0
	
	start:SetCostSoFar(0)
	
	start:SetTotalCost(heuristic_cost_estimate(start, goal))
	start:UpdateOnOpenList()
	
	while not start:IsOpenListEmpty() do
		if aStarLoopCheck > 10 then return false end -- we looped too many times!! -- TODO: this never happens because nothing increases this value.
		
		aStarIterator = aStarIterator + 1
		
		local current = start:PopOpenList() -- Remove the area with lowest cost in the open list and return it
		if current == goal then
			self.prf = self.prf + aStarIterator * ASTAR_OP_MULTIPLIER
			return reconstruct_path(cameFrom, current)
		end
		
		current:AddToClosedList()
		
		for k, neighbor in pairs(current:GetAdjacentAreas()) do
			local newCostSoFar = current:GetCostSoFar() + heuristic_cost_estimate(current, neighbor)
			
			if neighbor:IsUnderwater() then -- Add your own area filters or whatever here
				continue
			end -- TODO: this basically completely excludes underwater areas from being in the path found, huh? should we make prefilters like we do with finds? afaik the standard functions only give IsUnderwater and IsBlocked
			
			if ( neighbor:IsOpen() or neighbor:IsClosed() ) and neighbor:GetCostSoFar() <= newCostSoFar then
				continue
			else
				neighbor:SetCostSoFar(newCostSoFar);
				neighbor:SetTotalCost(newCostSoFar + heuristic_cost_estimate(neighbor, goal))
				
				if neighbor:IsClosed() then
					neighbor:RemoveFromClosedList()
				end
				
				if neighbor:IsOpen() then
					-- This area is already on the open list, update its position in the list to keep costs sorted
					neighbor:UpdateOnOpenList()
				else
					neighbor:AddToOpenList()
				end
				
				cameFrom[neighbor:GetID()] = current:GetID()
			end
		end
	end
	self.prf = self.prf + aStarIterator * ASTAR_OP_MULTIPLIER
	return false
end

function heuristic_cost_estimate(start, goal)
	-- Perhaps play with some calculations on which corner is closest/farthest or whatever
	return start:GetCenter():Distance(goal:GetCenter())
end

-- using CNavAreas as table keys doesn't work, we use IDs
function reconstruct_path(cameFrom, current)
	local total_path = { current }
	current = current:GetID()
	while cameFrom[current] do
		current = cameFrom[current]
		table.insert(total_path, navmesh.GetNavAreaByID(current))
	end
	return total_path
end

-------------------- yep that was definitely stole straight from the wiki with no modifications

__e2setcost(20) --i don't actually know how to measure this, but judging by CPU usage it isn't too bad at all.
 -- hovers around 150uS usage with an example setPos() walker chip that is running on tick. ~8uS on a 500mS inverval.

e2function navmesh navmesh()
	if not MAP_HAS_NAV then return NULL_MESH end -- needs to return null mesh for other funcs to work
	local pos = self.entity:GetPos() --just in case.
	return navmesh.GetNavArea(pos,30) -- 30 = about eyelevel height when crouching
end -- don't set higher, it likes to pick navmeshes that are underground if you do. alternatively, allow user to specify?

e2function navmesh navmesh(vector pos)
	if not MAP_HAS_NAV then return NULL_MESH end
	local nav = navmesh.GetNavArea(pos,30)
end

e2function navmesh navmesh(vector pos,number checkDistance) -- actually yeah let's do exactly that.
	if not MAP_HAS_NAV then return NULL_MESH end
	local nav = navmesh.GetNavArea(pos,checkDistance)
end

e2function navmesh navmesh(number id)
	if not MAP_HAS_NAV then return NULL_MESH end
	local nav = navmesh.GetNavAreaByID(id)
end

e2function number navmesh:navID()
	if not IsValid(this) then return 0 end
	return this:GetID()
end

e2function vector navmesh:navCenter()
	if not IsValid(this) then return NULL_VEC end
	return this:GetCenter()
end

e2function vector navmesh:navCorner(number corner)
	if not IsValid(this) then return NULL_VEC end
	local clampnum = Clamp(floor(corner),1,4)
	return this:GetCorner(clampnum-1) -- arrays start with 1
end --NE NW SW SE.

e2function array navmesh:navGetCorners()
	if not IsValid(this) then return NULL_TABLE end
	local t = NULL_TABLE
	for i=1,4 do
		t[i] = this:GetCorner(i-1)
	end
	return t
end

e2function vector navmesh:navSize()
	local nb = NavBounds(this)
	local sub = nb[2]:Sub(nb[1])
	return nb[2] -- apparently Sub directly subtracts the value in the table. :thinking:
end

e2function array navmesh:navBBox()
	return NavBounds(this)
end

e2function vector navmesh:navRandom()
	if not IsValid(this) then return NULL_VEC end
	return this:GetRandomPoint()
end

e2function vector navmesh:navClosestPoint(vector vector)
	if not IsValid(this) then return NULL_VEC end
	return this:GetClosestPointOnArea(vector)
end

e2function number navmesh:navContains(vector testPoint)
	if IsValid(this) and this:Contains(testPoint) then return 1
	else return 0 end --should we return the testpoint vector instead of a number? -- no
end

e2function number navmesh:navIsConnected(navmesh nav)
	if not IsValid(this) then return 0 end
	local c = this:IsConnected(navmesh) --first, check if we're connected in the first place
	if c then
		local a = NULL_TABLE -- init an empty table we'll use to slave from
		local side = 5 --returns "side 5" (vertical connections, should probably never be returned)
		for i=0,3 -- for each side
			a = this:GetAdjacentAreasAtSide(i) -- get all areas connected on that side
			for k,v in pairs(a) do -- then loop through that table of areas and check if we hit our --wait
				if v == nav then side = i+1 end -- can't i just use table:exists? --oh wow turns out that's a default function in lua, never knew that.
			end
		return side end -- returns which side specifically this navmesh is connected at
	else return 0 end -- probably not necessary, but it's convenient when its needed
end

e2function array navmesh:navConnectedMeshes()
	if not IsValid(this) then return NULL_TABLE end
	return this:GetAdjacentAreas()
end

e2function array navmesh:navConnectedMeshesOnSide(number side)
	if not IsValid(this) then return NULL_TABLE end
	local clampNum = Clamp(floor(side),1,4)
	return this:GetAdjacentAreasAtSide(clampNum-1)
end

e2function array navmesh:navIncomingMeshes()
	if not IsValid(this) then return NULL_TABLE end
	return this:GetIncomingConnections()
end

e2function array navmesh:navIncomingMeshesOnSide(number side)
	if not IsValid(this) then return NULL_TABLE end
	local clampNum = Clamp(floor(side), 1, 4)
	return this:GetIncomingConnectionsAtSide(clampNum-1)
end

e2function array navFindPath(vector start, vector goal)
	if not MAP_HAS_NAV then return NULL_TABLE end
	local s = navmesh.GetNearestNavArea(start)
	local g = navmesh.GetNearestNavArea(goal)
	local r = Astar(s, g)
	if r == true then return { g } elseif not r then return NULL_TABLE
	else return r end
end

e2function array navFindPath(navmesh start, vector goal)
	if not MAP_HAS_NAV then return NULL_TABLE end
	local g = navmesh.GetNearestNavArea(goal)
	local r = Astar(start,g)
	if r == true then return { g } elseif not r then return NULL_TABLE
	else return r end
end

e2function array navFindPath(navmesh start, navmesh goal)
	if not MAP_HAS_NAV then return NULL_TABLE end
	local r = Astar(start, goal) --already checks validity
	if r == true then return { goal } elseif not r then return NULL_TABLE
	else return r end
end

e2function array navmesh:navHidingSpots()
	if not IsValid(this) then return NULL_TABLE end
	return this:GetHidingSpots()
end

e2function array navmesh:navExposedSpots()
	if not IsValid(this) then return NULL_TABLE end
	return this:GetExposedSpots()
end -- kind of tempted to do a distance-sorted find-all-hiding- spots sort of deal. nah.

e2function navmesh navNearestMesh(vector vector, number checkLOS)
	if not MAP_HAS_NAV then return NULL_MESH end
	local check = false
	if checkLOS ~= 0 then check = true end
	return navmesh.GetNearestNavArea(vector, nil, nil, check)
end

--[[ -- way too strong. crashed my client with printTable(AllNavs). don't use.
e2function array navmeshes()
	if not MAP_HAS_NAV then return NULL_TABLE end
	return navmesh.GetAllNavAreas()
end
]]--

e2function array navmeshes()
	if not MAP_HAS_NAV then return NULL_TABLE end
	return navmesh.Find(self.entity:GetPos(), 5000, 50, 50)
end

e2function array navmeshes(vector origin)
	if not MAP_HAS_NAV then return NULL_TABLE end
	return navmesh.Find(origin, 10000, 50, 50)
end

e2function array navmeshes(vector origin, number radius)
	if not MAP_HAS_NAV then return NULL_TABLE end
	local c = math.min(radius, 10000) -- 59 units is the max height a bot will try to jump up. Src: Valve developer wiki
	return navmesh.Find(origin, c, 50, 50) -- Auto generated navmeshes are known to have impossible jumps on slopes. Src: gm_construct_flatgrass_v6-2
end

e2function array navmeshes(vector origin, number radius, number dropHeight, number jumpHeight)
	if not MAP_HAS_NAV then return NULL_TABLE end
	local c = math.min(radius, 10000)
	return navmesh.Find(origin, c, dropheight, jumpheight)
end

e2function array navmeshes(vector origin, number dropHeight, number jumpHeight)
	if not MAP_HAS_NAV then return NULL_TABLE end
	return navmesh.Find(origin, 10000, dropHeight, jumpHeight)
end
