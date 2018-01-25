local lfs = require("lfs")
local msgs = require("messages")
local cmds_mod = require("commands")

local name = "luarocks-2.4.3-win32"
local ext = ".zip"
local uri = "http://luarocks.github.io/luarocks/releases/"..filename..ext
local dest_dir = "C:\\temp\\"
local destination = dest_dir..filename..ext
 
local cmds = cmds_mod.new()

--~ local webrequest = "Invoke-WebRequest -Uri "..uri.." -OutFile "..archive
--~ local decompress = '"Add-Type -assembly \'system.io.compression.filesystem\'; [io.compression.zipfile]::ExtractToDirectory(\'' .. archive .. '\',\'' ..destination..'\')"'
local cmdhdr = "Executing: "

local pwd = lfs.currentdir()
local ok = lfs.chdir(destination)

if ok then
	lfs.chdir(pwd)
	io.stderr:write(string.format("Directory %s exists. Using local copy...",destination))
	--~ return 1
else
	--build and execute the web command
	local cmd = string.format(cmd.webrequest,uri,destination)
	local exec = string.format("%s %s", cmds.shell, cmd)
	print(cmdhdr..exec)
	ok = os.execute(exec)
	if(ok) then
		--build and execute the extract command
		cmd = string.format(cmd.webrequest,uri,destination)
		exec = string.format("%s %s", cmds.shell, cmd)
		print(cmdhdr..exec)
		ok = os.execute(exec)
	end

	if ok then print ("success!") else io.stderr:write("didn't work") return 1 end
end

local pattern = "Directory:[%s+](.+)"
local match = cmds.return_shell_output(cmd.find_install, pattern, false)

if match then ok = true else ok = false end

print (string.format("Is okay? %s", ok))
