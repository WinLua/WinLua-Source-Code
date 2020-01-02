char * get_opts =  R"V0G0N(
--START LUA
local sep = '\\'
local so_ext = '.dll'

opts = {}

default_version = "5.3"
default_file_name = "lua53"..so_ext


opts.bits = 32

other = {}
argc = 0

local function check_version(version)
	--strip the dash and see if we can make a number
	-- if the number is between 51 and 54 (inclusive) then return it
	-- if the version is alread set, return an error
	local ver = tonumber(version:sub(2))
	local msg = nil
	if ver then
		if ver < 51 or ver > 54 then
			msg = ver.." is not a valid version"
			ver = nil
		end
	end 
	if opts.version then
		msg = "Cannot set "..ver.." Already set to"..opts.version
		ver = nil
	end
	return ver, msg
end

local function build_options(args)
	local param = -1

	for i,v in pairs(args) do
		
		local ver = v:match("-5%d")
		local subdir
		local err = nil
		if i == 0 then
			other[0] = v
		elseif ver then
			ver, err = check_version(ver)
			if ver then 
				opts.version = ver / 10
				opts.file_name = string.format("lua%d%s", ver, so_ext)
				opts.so_path = opts.version..sep..opts.file_name
			else
				opts.err = err
			end
		elseif v == "-x64" or v == "-X64" then
			opts.bits = 64
		elseif v == "-f" or v == "--file" then
			opts.config_file = args[i+1]
			param = i
		elseif param > -1 then
			param = -1
		else
			other[#other + 1] = v
		end
	end
	
	if not opts.version then 
		opts.version = default_version
		opts.file_name = default_file_name
		opts.so_path = default_version..sep..default_file_name
	end
--~ Can't use #other because the item order is not contiguous (e.g 1,2,0)
	for _ in pairs(other) do
		argc = argc+1
	end
	if opts.err then return nil, opts.err else return true end
end
if arg then args = arg end
build_options(args)
if arg then 
	for i,v in pairs(opts) do print(i,v) end
end
-- END LUA
)V0G0N";