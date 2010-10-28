local Obj = EGP:NewObject( "BoxOutline" )
Obj.size = 1
Obj.angle = 0
Obj.Draw = function( self )
	if (self.a>0 and self.w > 0 and self.h > 0) then
		surface.SetDrawColor( self.r, self.g, self.b, self.a )
		local s = self.size/2
		if (self.angle == 0) then -- this is less demanding, so I'm using angle = 0 as a special case
			local vec1 = { x = self.x - self.w / 2			, y = self.y - self.h / 2			}
			local vec2 = { x = self.x - self.w / 2 + self.w	, y = self.y - self.h / 2 			}
			local vec3 = { x = self.x - self.w / 2 + self.w	, y = self.y - self.h / 2 + self.h 	}
			local vec4 = { x = self.x - self.w / 2			, y = self.y - self.h / 2 + self.h 	}
			EGP:DrawLine( vec1.x		, vec1.y + s	, vec2.x		, vec2.y + s, self.size )
			EGP:DrawLine( vec2.x - s	, vec2.y		, vec3.x - s	, vec3.y	, self.size )
			EGP:DrawLine( vec3.x		, vec3.y - s	, vec4.x		, vec4.y - s, self.size )
			EGP:DrawLine( vec4.x + s	, vec4.y		, vec1.x + s	, vec1.y	, self.size )
		else
			local centerx, centery = self.x, self.y

			local ofsx, ofsy = -self.w / 2	, -self.h / 2
			local  vec1,_ = LocalToWorld(Vector(ofsx,ofsy + s,0),Angle(0,0,0),Vector(centerx,centery,0),Angle(0,-self.angle,0))
			local _vec4,_ = LocalToWorld(Vector(ofsx + s,ofsy,0),Angle(0,0,0),Vector(centerx,centery,0),Angle(0,-self.angle,0))

			local ofsx, ofsy = self.w / 2	, -self.h / 2
			local _vec1,_ = LocalToWorld(Vector(ofsx,ofsy + s,0),Angle(0,0,0),Vector(centerx,centery,0),Angle(0,-self.angle,0))
			local  vec2,_ = LocalToWorld(Vector(ofsx - s,ofsy,0),Angle(0,0,0),Vector(centerx,centery,0),Angle(0,-self.angle,0))

			local ofsx, ofsy = self.w / 2	, self.h / 2
			local _vec2,_ = LocalToWorld(Vector(ofsx - s,ofsy,0),Angle(0,0,0),Vector(centerx,centery,0),Angle(0,-self.angle,0))
			local  vec3,_ = LocalToWorld(Vector(ofsx,ofsy - s,0),Angle(0,0,0),Vector(centerx,centery,0),Angle(0,-self.angle,0))

			local ofsx, ofsy = -self.w / 2	, self.h / 2
			local _vec3,_ = LocalToWorld(Vector(ofsx,ofsy - s,0),Angle(0,0,0),Vector(centerx,centery,0),Angle(0,-self.angle,0))
			local  vec4,_ = LocalToWorld(Vector(ofsx + s,ofsy,0),Angle(0,0,0),Vector(centerx,centery,0),Angle(0,-self.angle,0))

			EGP:DrawLine( vec1.x, vec1.y, _vec1.x, _vec1.y, self.size )
			EGP:DrawLine( vec2.x, vec2.y, _vec2.x, _vec2.y, self.size )
			EGP:DrawLine( vec3.x, vec3.y, _vec3.x, _vec3.y, self.size )
			EGP:DrawLine( vec4.x, vec4.y, _vec4.x, _vec4.y, self.size )
		end
	end
end
Obj.Transmit = function( self )
	EGP.umsg.Short( self.size )
	EGP.umsg.Short( self.angle )
	self.BaseClass.Transmit( self )
end
Obj.Receive = function( self, um )
	local tbl = {}
	tbl.size = um:ReadShort()
	tbl.angle = um:ReadShort()
	table.Merge( tbl, self.BaseClass.Receive( self, um ) )
	return tbl
end
Obj.DataStreamInfo = function( self )
	local tbl = {}
	tbl.size = self.size
	tbl.angle = self.angle
	table.Merge( tbl, self.BaseClass.DataStreamInfo( self ) )
	return tbl
end
