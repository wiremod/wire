--------------------------------------------------------------------------------
--                    File extension by {iG} I_am_McLovin                     --
--------------------------------------------------------------------------------

if not datastream then require( "datastream" ) end

usermessage.Hook( "wire_expression2_fileload", function( um )
	local raw_filename = um:ReadString()
	local filename = "e2files/"..raw_filename
	if string.find(filename, "..", 1, true) then return end

	if file.Exists( filename ) and file.Size( filename ) <= 102400 then
		local filedata = file.Read( filename )
		datastream.StreamToServer( "wire_expression2_filedata", { filename = raw_filename, filedata = filedata } )
	end
end )

usermessage.Hook( "wire_expression2_filerequestlist", function( um )

	file.TFind( "data/e2files/*.txt", function( _, _, files )
		datastream.StreamToServer( "wire_expression2_filelist", files )
	end )

end )

datastream.Hook( "wire_expression2_filewrite", function( handler, id, encoded, decoded )
	local file_name = "e2files/"..decoded.name
	if string.find(file_name, "..", 1, true) then return end

	local old_file = ""

	if decoded.append then
		if file.Exists( file_name ) then
			old_file = file.Read( file_name )
		end
	end

	file.Write( file_name, old_file .. decoded.data )
end )
