--Adapted by CunningFox (Original by Star)
--All rights reserved
return function(img_name, atlas)
	atlas = atlas or "images/inventoryimages.xml"
	local f = io.open(atlas, "r")
	
	if not f then
		print(string.format("Atlas Checker: ERROR! Can't read file %s!", atlas))
		return false
	end
	
	local content = f:read("*all")
	f:close()
	
	local i = 0
	repeat
		i = content:find('name="',i+6,true)
		if i ~= nil then
			local j = content:find('"',i+6,true)
			if j ~= nil then
				local name = content:sub(i+6,j-1)
				
				if name == img_name then
					return true
				end
			end
		end
	until i == nil
	
	return false
end
