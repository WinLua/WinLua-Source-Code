
--~ Create the paths
local appdata = os.getenv('APPDATA')
local user_cpath_dir = appdata..'\\luarocks\\lib\\lua\\5.3\\'
local user_path_dir = appdata..'\\luarocks\\share\\lua\\5.3\\'

--~ Set the package.cpath
local set_cpath = function(debug_flag)
	local new_cpath = string.format("%s?.dll;%slib?.dll;%s", user_cpath_dir, user_cpath_dir, package.cpath)
	package.cpath = new_cpath
	if debug_flag then print(package.cpath) end
end

--~ Set the package lua path
local set_path = function(debug_flag)
	local user_path = user_path_dir..'?.lua;'
	user_path = user_path..user_path_dir..'?\\init.lua;'
	package.path = user_path..package.path
	if debug_flag then print(package.cpath) end
end


return function(debug_flag)
	set_cpath(debug_flag)
	set_path(debug_flag)
end

