-- this is all crap D:

///////////////////////////////////////////////
//		===BeamNetVars===				//
//	Custom Networked Vars Module			//
//	Based off Garry's Networked Vars Module		//
//	Modification by: TAD2020				//
///////////////////////////////////////////////
//	How to use:							//
//	Just like NetVars, ent:SetNetworkedBeam*		//
//	and ent:GetNetworkedBeam*				//
//	Key should be short or a small number.		//
//	These functions should only be used instead	//
//	standard NetVars when very large quanity		//
//	of rarly updated values need to be sent with	//
//	low importantance. Mainly this is used by		//
//	wire's client side beams and rapidly updating	//
//	overlay text.						//
//	Data is sent at a tick interval, if too much		//
//	is in the outgoing query, the delay between		//
//	sends is increased.					//
//	On player joins, all current data is queried to	//
//	to send to them in the lowest priority stack.		//
//	Low priority stack sends a few entities's		//
//	vars each tick.						//
///////////////////////////////////////////////

//RD header for multi distro-ablity
local ThisBeamNetVarsVersion = 0.71
if (BeamNetVars) and (BeamNetVars.Version) and (BeamNetVars.Version > ThisBeamNetVarsVersion) then
	Msg("======== A Newer Version of BeamNetVars Detected ========\n"..
		"======== This ver: "..ThisBeamNetVarsVersion.." || Detected ver: "..BeamNetVars.Version.." || Skipping\n")
	return
elseif (BeamNetVars) and (BeamNetVars.Version) and (BeamNetVars.Version == ThisBeamNetVarsVersion) then
	--Msg("======== The Same Version of BeamNetVars Detected || Skipping ========\n")
	return
elseif (BeamNetVars) and (BeamNetVars.Version) then
	Msg("======== Am Older Version of BeamNetVars Detected ========\n"..
		"======== This ver: "..ThisBeamNetVarsVersion.." || Detected ver: "..BeamNetVars.Version.." || Overriding\n")
end


BeamNetVars = {}
BeamNetVars.Version = ThisBeamNetVarsVersion

if (SERVER) then
	//we want this
	//sv_usermessage_maxsize = 1024
	game.ConsoleCommand( "sv_usermessage_maxsize 1024\n" )
end

local meta = FindMetaTable( "Entity" )

// Return if there's nothing to add on to
if (!meta) then return end

local Vector_Default 	= Vector(0,0,0)
local Angle_Default		= Angle(0,0,0)

local NetworkVars 			= {}

local NetworkFunction 	= {}
local DelayedUpdates 	= {}
local DelayedUpdatesNum = 0
local ExtraDelayedUpdates = {}

local NextCleanup		= CurTime()

if ( CLIENT ) then
	local function Dump()
		Msg("Networked Beam Vars...\n")
		PrintTable( NetworkVars )
	end
	concommand.Add( "networkbeamvars_dump", Dump )
end

local function AttemptToSwitchTables( Ent, EntIndex )
	if ( NetworkVars[ EntIndex ] == nil ) then return end
	// We have an old entindex based entry! Move it over!
	NetworkVars[ Ent ] = NetworkVars[ EntIndex ]
	NetworkVars[ EntIndex ] = nil
end

local function CleaupNetworkVars()
	if ( NextCleanup > CurTime() ) then return end
	NextCleanup	= CurTime() + 30
	for k, v in pairs( NetworkVars ) do
		if !isnumber( k ) and !isstring( k ) then
			if ( !k:IsValid() ) then
				NetworkVars[ k ] = nil
			end
		end
	end
end

local function GetNetworkTable( ent, name )
	if ( CLIENT ) then
		CleaupNetworkVars()
	end
	if ( !NetworkVars[ ent ] ) then
		NetworkVars[ ent ] = {}
		// This is the first time this entity has been created.
		// Check whether we previously had an entindex based table
		if ( CLIENT && !isnumber( ent ) && !isstring( ent ) ) then
			AttemptToSwitchTables( ent, ent:EntIndex() )
		end
	end
	NetworkVars[ ent ][ name ] = NetworkVars[ ent ][ name ] or {}
	return NetworkVars[ ent ][ name ]
end

local function SendNetworkUpdate( VarType, Index, Key, Value, Player )
	if(Player and not (Player:IsValid() and Player:IsPlayer())) then return end // Be sure, Player is not a NULL-Entity, or the server will crash!

	umsg.Start( "RcvEntityVarBeam_"..VarType, Player )
		umsg.Short( Index )
		umsg.String( Key )
		umsg[ NetworkFunction[VarType].SetFunction ]( Value )
	umsg.End()


end

local function AddDelayedNetworkUpdate( VarType, Ent, Key, Value )
	if (Wire_FastOverlayTextUpdate) then
		SendNetworkUpdate( VarType, Ent, Key, Value )
	elseif (Ent) and (VarType) then
		DelayedUpdates[Ent]					= DelayedUpdates[Ent] or {}
		DelayedUpdates[Ent][ VarType ]		= DelayedUpdates[Ent][ VarType ] or {}
		DelayedUpdates[Ent][ VarType ][Key]	= Value
		DelayedUpdatesNum					= DelayedUpdatesNum + 1

		if (ExtraDelayedUpdates[Ent])
		and (ExtraDelayedUpdates[Ent][VarType])
		and (ExtraDelayedUpdates[Ent][VarType][Key]) then
			ExtraDelayedUpdates[Ent][VarType][Key] = nil
		end
	end
end

local function AddExtraDelayedNetworkUpdate( VarType, Ent, Key, Value, Player )
	if (Wire_FastOverlayTextUpdate) then
		SendNetworkUpdate( VarType, Ent, Key, Value )
	elseif (Ent) and (VarType) and (Key) then
		ExtraDelayedUpdates[Ent]						= ExtraDelayedUpdates[Ent] or {}
		ExtraDelayedUpdates[Ent][VarType]				= ExtraDelayedUpdates[Ent][VarType] or {}
		ExtraDelayedUpdates[Ent][VarType][Key]			= ExtraDelayedUpdates[Ent][VarType][Key] or {}
		ExtraDelayedUpdates[Ent][VarType][Key].Value	= Value
		ExtraDelayedUpdates[Ent][VarType][Key].Player	= Player
		--ExtraDelayedUpdatesNum = ExtraDelayedUpdatesNum + 1
	end
end



//
// make all the ent.Get/SetNetworkedBeamVarCrap
//
local function AddNetworkFunctions( name, SetFunction, GetFunction, Default )

	NetworkFunction[ name ] = {}
	NetworkFunction[ name ].SetFunction = SetFunction
	NetworkFunction[ name ].GetFunction = GetFunction

	// SetNetworkedBlah
	meta[ "SetNetworkedBeam" .. name ] = function ( self, key, value, urgent )

		key = tostring(key)

		// The same - don't waste our time.
		if ( value == GetNetworkTable( self, name )[ key ] ) then return end

		// Clients can set this too, but they should only really be setting it
		// when they expect the exact same result coming over the wire (ie prediction)
		GetNetworkTable( self, name )[key] = value

		if ( SERVER ) then

			local Index = self:EntIndex()
			if (Index <= 0) then return end

			if ( urgent ) then
				SendNetworkUpdate( name, Index, key, value )
			else
				AddDelayedNetworkUpdate( name, Index, key, value )
			end

		end

	end

	meta[ "SetNWB" .. name ] = meta[ "SetNetworkedBeam" .. name ]

	// GetNetworkedBlah
	meta[ "GetNetworkedBeam" .. name ] = function ( self, key, default )

		key = tostring(key)

		local out = GetNetworkTable( self, name )[ key ]
		if ( out != nil ) then return out end
		if ( default == nil ) then return Default end
		//default = default or Default -- not a good idea for booleans :)

		return default

	end

	meta[ "GetNWB" .. name ] = meta[ "GetNetworkedBeam" .. name ]


	// SetGlobalBlah
	_G[ "SetGlobalBeam"..name ] = function ( key, value, urgent )

		key = tostring(key)

		if ( value == GetNetworkTable( "G", name )[key] ) then return end
		GetNetworkTable( "G", name )[key] = value

		if ( SERVER ) then
			if ( urgent ) then
				SendNetworkUpdate( name, -1, key, value )
			else
				AddDelayedNetworkUpdate( name, -1, key, value )
			end
		end

	end


	// GetGlobalBlah
	_G[ "GetGlobalBeam"..name ] = function ( key )

		key = tostring(key)

		local out = GetNetworkTable( "G", name )[key]
		if ( out != nil ) then return out end

		return Default

	end


	if ( SERVER ) then
		// Pool the name of the function.
		// Makes it send a number representing the string rather than the string itself.
		// Only do this with strings that you send quite a bit and always stay the same.
		umsg.PoolString( "RcvEntityBeamVar_"..name )
	end

	// Client Receive Function
	if ( CLIENT ) then

		local function RecvFunc( m )
			local EntIndex 	= m:ReadShort()
			local Key		= m:ReadString()
			local Value		= m[GetFunction]( m )

			local IndexKey
			if ( EntIndex <= 0 ) then
				IndexKey = "G"
			else
				IndexKey = Entity( EntIndex )
				// No entity yet - store using entindex
				if ( IndexKey == NULL ) then IndexKey = EntIndex end
			end
			GetNetworkTable( IndexKey, name )[Key] = Value
		end
		usermessage.Hook( "RcvEntityVarBeam_"..name, RecvFunc )

	end

end

AddNetworkFunctions( "Vector", 	"Vector", 	"ReadVector", 	Vector_Default )
AddNetworkFunctions( "Angle", 	"Angle", 	"ReadAngle", 	Angle_Default )
AddNetworkFunctions( "Float", 	"Float", 	"ReadFloat", 	0 )
AddNetworkFunctions( "Int", 	"Short", 	"ReadShort", 	0 )
AddNetworkFunctions( "Entity", 	"Entity", 	"ReadEntity", 	NULL )
AddNetworkFunctions( "Bool", 	"Bool", 	"ReadBool", 	false )
AddNetworkFunctions( "String", 	"String", 	"ReadString", 	"" )






//
// We want our networked vars to save don't we? Yeah - we do - stupid.
//
local function Save( save )
	// Remove baggage
	for k, v in pairs(NetworkVars) do
		if ( k == NULL ) then
			NetworkVars[k] = nil
		end
	end
	saverestore.WriteTable( NetworkVars, save )
end
local function Restore( restore )
	NetworkVars = saverestore.ReadTable( restore )
	//PrintTable(NetworkVars)
end
saverestore.AddSaveHook( "EntityNetworkedBeamVars", Save )
saverestore.AddRestoreHook( "EntityNetworkedBeamVars", Restore )

if (SERVER) then
//
// send the netvars queried in the stack
//
local NextBeamVarsDelayedSendTime = 0
local NormalOpMode = true
local function NetworkVarsSend()
	if (CurTime() >= NextBeamVarsDelayedSendTime) then

		if (NormalOpMode) and (DelayedUpdatesNum > 75) then
			--Msg("========BeamVars leaving NormalOpMode | "..DelayedUpdatesNum.."\n")
			NormalOpMode = false
		elseif (!NormalOpMode) and (DelayedUpdatesNum < 50)  then
			--Msg("========BeamVars returning NormalOpMode | "..DelayedUpdatesNum.."\n")
			NormalOpMode = true
		end


		if (DelayedUpdatesNum > 0) then
			for Index, a in pairs(DelayedUpdates) do
				for VarType, b in pairs(a) do
					for Key, Value in pairs(b) do
						SendNetworkUpdate( VarType, Index, Key, Value )
					end
				end
			end
			DelayedUpdatesNum = 0
			DelayedUpdates = {}
		end

		//we send one entity's ExtraDelayedUpdates each tick
		local i = 0
		for Index, a in pairs(ExtraDelayedUpdates) do
			for VarType, b in pairs(a) do
				for Key, data in pairs(b) do
					SendNetworkUpdate( VarType, Index, Key, data.Value, data.Player )
				end
			end
			ExtraDelayedUpdates[Index] = nil
			i = i + 1
			if (i >= 2) then
				break
			end
		end

		if (!NormalOpMode) then
			NextBeamVarsDelayedSendTime = CurTime() +  .25
		else
			NextBeamVarsDelayedSendTime = CurTime() +  .1
		end

	end
end
hook.Add("Think", "NetBeamLib_Think", NetworkVarsSend)


//
// Send a full update to player that have just joined the server
//
local function FullUpdateEntityNetworkVars( ply )
	--Msg("==sending netbeamvar var data to "..tostring(ply).."\n")
	--Msg("\n===Size: "..table.Count(NetworkVars).."\n")
	for Ent, EntTable in pairs(NetworkVars) do
		for Type, TypeTable in pairs(EntTable) do
			for Key, Value in pairs(TypeTable) do
				local Index = Ent
				if !isstring(Ent) then
					Index = Ent:EntIndex()
				end
				--SendNetworkUpdate( Type, Index , Key, Value, ply )
				AddExtraDelayedNetworkUpdate( Type, Index , Key, Value, ply )
			end
		end

	end
end
local function DelayedFullUpdateEntityNetworkVars( ply )
	--Msg("==starting timer for sending var data too "..tostring(ply).."\n")
	timer.Simple(4, function() FullUpdateEntityNetworkVars(ply) end )
end
hook.Add( "PlayerInitialSpawn", "FullUpdateEntityNetworkBeamVars", DelayedFullUpdateEntityNetworkVars )
concommand.Add( "networkbeamvars_SendAll", DelayedFullUpdateEntityNetworkVars )
concommand.Add( "networkbeamvars_SendAllNow", FullUpdateEntityNetworkVars )


//
// Listen out for dead entities so we can remove their vars
//
local function NetworkVarsCleanup( ent )
	NetworkVars[ ent ] = nil
end
hook.Add( "EntityRemoved", "NetworkBeamVarsCleanup", NetworkVarsCleanup )


end //end SERVER olny



--Msg("======== Beam NetVars Lib v"..BeamNetVars.Version.." Installed ========\n")
