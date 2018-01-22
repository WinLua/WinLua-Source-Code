local lfs = require("lfs")

local uri = "http://luarocks.github.io/luarocks/releases/luarocks-2.4.3-win32.zip"
local archive = "C:\\temp\\luarock-2.4.3.zip"
local destination = "C:\\temp\\luarocks-2.4.3\\"

local webrequest = "Invoke-WebRequest -Uri "..uri.." -OutFile "..archive
local decompress = '"Add-Type -assembly \'system.io.compression.filesystem\'; [io.compression.zipfile]::ExtractToDirectory(\'' .. archive .. '\',\'' ..destination..'\')"'
local cmdhdr = "Executing: "

local pwd = lfs.currentdir()
local ok = lfs.chdir(destination)

if ok then
	lfs.chdir(pwd)
	io.stderr:write(string.format("Directory %s exists. Using local copu...",destination))
	--~ return 1
else

	local cmd = 'powershell '..webrequest
	print(cmdhdr..cmd)
	ok = os.execute(cmd)
	if(ok) then
		local cmd = 'powershell '..decompress
		print(cmdhdr..cmd)
		ok = os.execute(cmd)
	end

	if ok then print ("success!") else io.stderr:write("didn't work") return 1 end
end
local findBat = 'powershell "ls -R install.bat"'
local match = false
local handle = io.popen(findBat)
--~ local result = handle:read("*a")
for v in handle:lines() do 
	--This says find "Directory<any-space" and then capture everything 
	--following that.
	--%s in matching pattern is whitespace, period is anything.
	--~ match = string.match(v, "Directory:[%s+](.+)[\rn|\n]")
	match = string.match(v, "Directory:[%s+](.+)")
	if match then
		print(string.format("Found %s", match))
		break
	end
end
handle:close()
--~ print(result)
if match then ok = true else ok = false end

print (string.format("Is okay? %s", ok))
