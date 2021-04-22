if SERVER then
	--[[
		Keep in mind that GMod can only write .txt files and github requires other file types, such as .md
		I recommend using any kind of mass-renamer to rename the text files after using this command.
		Here's a small php script that does the job

		$files = glob("*.txt");

		foreach( $files as $idx => $file ) {
			$newname = str_replace(".txt",".md",$file);
			echo $idx . "=>" . $newname . "<br>";
			rename($file,$newname);
		}
	]]

	-- place any extensions which you have installed that are not part of wiremod
	-- (and can't be disabled using the extension manager because the developers didn't implement that)
	-- in this list, to make the docs generator skip them
	local exclude = {
		--["custom/light"] = true -- example
	}


	-- various patterns
	local p_typename = "[a-z][a-z0-9]*"
	local p_typeid = "[a-z][a-z0-9]?[a-z0-9]?[a-z0-9]?[a-z0-9]?"
	local p_argname = "[a-zA-Z][a-zA-Z0-9]*"
	local p_funcname = "[a-z][a-zA-Z0-9_]*"

	local typeimages = {
		a = 	'![Angle](Type-Angle.png "Angle")',
		e = 	'![Entity](Type-Entity.png "Entity")',
		b = 	'![Bone](Type-Bone.png "Bone")',
		xwl = 	'![WireLink](Type-WireLink.png "WireLink")',
		c = 	'![ComplexNumber](Type-ComplexNumber.png "ComplexNumber")',
		r = 	'![Array](Type-Array.png "Array")',
		xrd = 	'![RangerData](Type-RangerData.png "RangerData")',
		s = 	'![String](Type-String.png "String")',
		v = 	'![Vector](Type-Vector.png "Vector")',
		xv2 = 	'![Vector2](Type-Vector2.png "Vector2")',
		xv4 = 	'![Vector4](Type-Vector4.png "Vector4")',
		m = 	'![Matrix](Type-Matrix.png "Matrix")',
		xm2 = 	'![Matrix4](Type-Matrix2.png "Matrix2")',
		xm4 = 	'![Matrix4](Type-Matrix4.png "Matrix4")',
		t = 	'![Table](Type-Table.png "Table")',
		q = 	'![Quaternion](Type-Quaternion.png "Quaternion")',
		n = 	'![Number](Type-Number.png "Number")'
	}

	local wireextras = {
		["custom/camera"] = true,
		["custom/ftrace"] = true,
		["custom/holoanim"] = true,
		["custom/light"] = true,
		["custom/stcontrol"] = true,
		["custom/tracesystem"] = true,
	}

	local function e2doc()
		local files = {}
		E2Helper = {Descriptions = {}}
		language = {Add = function() end}
		include( "wire/client/e2descriptions.lua" )
		include( "entities/gmod_wire_expression2/core/custom/cl_prop.lua" )
		include( "entities/gmod_wire_expression2/core/custom/cl_constraintcore.lua" )
		include( "entities/gmod_wire_expression2/core/custom/cl_tracesystem.lua" )
		include( "entities/gmod_wire_expression2/core/custom/cl_stcontrol.lua" )
		include( "entities/gmod_wire_expression2/core/custom/cl_ftrace.lua" )
		language = nil

		local function upperFirst(str)
			return string.upper(string.sub(str,1,1)) .. string.lower(string.sub(str,2))
		end

		local function getTypeImage(typeid)
			if typeid == "..." then return "..." end
			if typeid == nil or typeid == "" then return "" end
			if typeimages[typeid] then return typeimages[typeid] end
			if wire_expression_types2[typeid] then
				return upperFirst(wire_expression_types2[typeid][1])
			end

			return typeid
		end

		timer.Simple(0.2,function() -- there's a timer in e2descriptions which we need to wait for
			local descriptions = E2Helper.Descriptions

			for signature, funcdata in pairs( wire_expression2_funcs ) do
				local retval = funcdata[2]
				local func = funcdata[3]
				local cost = funcdata[4] or 0
				local argnames = funcdata.argnames or {}

				if string.sub(signature,1,3) == "op:" then continue end

				-- get file path
				local info = debug.getinfo( func )
				local filepath = string.match(info.short_src,"/gmod_wire_expression2/core/(.+)")
				filepath = string.gsub(filepath,".lua","")
				if exclude[filepath] then continue end

				if not files[filepath] then files[filepath] = {} end

				retval = getTypeImage(retval)
				if retval == nil then print(funcdata[1],"'"..funcdata[2].."'") end
				local description = descriptions[signature] or ""

				-- parse function signature, split function name from argument typeids
				local funcname, params = string.match(signature,"^("..p_funcname..")%((.*)%)$")
				local parsed_params = {}

				local this, other
				if params ~= nil and params ~= "" then
					-- check if this function has 'this:funcname('
					if string.find(params,":",1,true) ~= nil then
						this, other = string.match(params,"^("..p_typeid.."):(.*)$")
						params = other
						this = getTypeImage(this)
					end

					if params ~= nil and params ~= "" then
						-- parse params and add argument name to each
						local pos = 1
						repeat
							local s = string.sub(params,pos,pos)
							if s == "x" then
								s = string.sub(params,pos,pos+2)
								pos = pos + 2
							elseif s == "." then
								s = "..."
								pos = pos + 2
							end
							pos = pos + 1

							local idx = #parsed_params+1
							local argname = argnames[idx] or ""
							if argname ~= "" then argname = " " .. upperFirst(argname) end
							parsed_params[idx] = getTypeImage(s) .. argname
						until pos>#params
					end
				end

				parsed_params = table.concat(parsed_params,", ")
				if this ~= nil and this ~= "" then
					funcname = string.format("%s:%s(%s)",this,funcname,parsed_params)
				else
					funcname = string.format("%s(%s)",funcname,parsed_params)
				end

				-- generate display (table), not used for now because it's not great for longer function names
				--local str = string.format("| %s | %s | %s | %s |",funcname,retval,cost,description)

				-- generate display
				local str = ""
				if retval ~= "" then
					str = string.format("### %s = %s\n\n%s (%s ops)",retval,funcname,description,cost)
				else
					str = string.format("### %s\n\n%s (%s ops)",funcname,description,cost)
				end

				-- sort into the correct "file" category
				files[filepath][ #files[filepath]+1 ] = {
					str = str,
					sortparam = info.linedefined
				}
			end

			-- build navigation
			local nav = {}
			for filepath, data in pairs( files ) do
				local is_wire_extras = ""
				if wireextras[filepath] then is_wire_extras = " (Wire Extras)" end

				local filename = string.gsub(filepath,"custom/","custom-")
				filename = "e2-docs-" .. filename

				nav[#nav+1] = {
					str = string.format("* [%s](%s)%s",filepath,filename,is_wire_extras),
					sortparam = filepath,
					iscustom = string.sub(filepath,1,7) == "custom/"
				}
			end

			-- sort navigation
			table.sort(nav,function(a,b)
				if a.iscustom and not b.iscustom then return false end
				if not a.iscustom and b.iscustom then return true end

				return a.sortparam < b.sortparam
			end)

			local function collapseTable(t)
				-- clear all other values and leave only strings
				for k,v in pairs(t) do t[k] = v.str end
			end

			collapseTable(nav)
			nav = "# Table of Contents\n\n"..table.concat(nav,"\n")
			file.Write("e2doc/e2-docs-toc.txt",nav)
			print("writing file: ","e2doc/e2-docs-toc.txt")

			for filepath, data in pairs( files ) do
				-- github table header, not used for now because it's not great for longer function names
				--local tableheader = "| Function | Returns | Cost | Description |\n| --- | --- | --- | --- |\n"

				-- sort by position in file which defined it
				table.sort(data,function(a,b)
					return a.sortparam < b.sortparam
				end)

				collapseTable(data)
				data = string.format("[[Jump to table of contents|#table-of-contents]]\n\n# %s\n\n%s\n",upperFirst(filepath),table.concat(data,"\n\n"))

				filepath = string.gsub(filepath,"custom/","custom-")
				local filename = "e2doc/e2-docs-" .. filepath .. ".txt"
				print("writing file: ",filename)
				file.Write(filename, data )
			end

			E2Helper = nil -- this value is no longer needed serverside
		end)
	end

	concommand.Add("e2doc",
		function(player, command, args)
			if not file.IsDir("e2doc", "DATA") then file.CreateDir("e2doc") end
			--if not file.IsDir("e2doc/custom", "DATA") then file.CreateDir("e2doc/custom") end

			e2doc()
		end
	)
end
