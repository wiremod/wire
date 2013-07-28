EGP = {}

--------------------------------------------------------
-- Include all other files
--------------------------------------------------------

function EGP:Initialize()
	local Folder = "entities/gmod_wire_egp/lib/egplib/"
	local entries = file.Find( Folder .. "*.lua", "LUA")
	for _, entry in ipairs( entries ) do
		if (SERVER) then
			AddCSLuaFile( Folder .. entry )
		end
		include( Folder .. entry )
	end
end

EGP:Initialize()

local EGP = EGP

EGP.ConVars = {}
EGP.ConVars.MaxObjects = CreateConVar( "wire_egp_max_objects", 300, { FCVAR_NOTIFY, FCVAR_SERVER_CAN_EXECUTE, FCVAR_ARCHIVE } )
EGP.ConVars.MaxPerSec = CreateConVar( "wire_egp_max_bytes_per_sec", 10000, { FCVAR_NOTIFY, FCVAR_SERVER_CAN_EXECUTE, FCVAR_ARCHIVE }  ) -- Keep between 2500-40000

EGP.ConVars.MaxVertices = CreateConVar( "wire_egp_max_poly_vertices", 1024, { FCVAR_NOTIFY, FCVAR_SERVER_CAN_EXECUTE, FCVAR_ARCHIVE } )

EGP.ConVars.AllowEmitter = CreateConVar( "wire_egp_allow_emitter", 1, { FCVAR_NOTIFY, FCVAR_SERVER_CAN_EXECUTE, FCVAR_ARCHIVE  }  )
EGP.ConVars.AllowHUD = CreateConVar( "wire_egp_allow_hud", 1, { FCVAR_NOTIFY, FCVAR_SERVER_CAN_EXECUTE, FCVAR_ARCHIVE  }  )
EGP.ConVars.AllowScreen = CreateConVar( "wire_egp_allow_screen", 1, { FCVAR_NOTIFY, FCVAR_SERVER_CAN_EXECUTE, FCVAR_ARCHIVE  }  )
