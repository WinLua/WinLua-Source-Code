--[[
Powershell requires that the command string is in double quotes and everything inside that is single quotes. 
Sort of. I'll get the details and add then here.
--]]

local shells = {
"powershell",
"fish",
"sh",
"csh",
"tcsh",
"bash",
"cmd"
}

local powershell={
webrequest = "Invoke-WebRequest -Uri %s -OutFile %s",
decompress = '"Add-Type -assembly \'system.io.compression.filesystem\'; [io.compression.zipfile]::ExtractToDirectory(\'%s\',\'%s\')"',
find_install = '"ls -R install.bat"'
}

local posix={
webrequest=find_webrequest(),
decompress = find_decompress(),
find_install = find_install()
}

local oses = {
	WIN={
		shell=shells[1], 
		commands=powershell},
	FreeBSD={
		shell=shells[3], 
		commands=posix},
	Linux={
		shell=shells[3], 
		commands=posix},
	OSX={
		shell=shells[3], 
		commands=posix}
}

local function which(exec)
	return os.execute(string.format("which %s >> devnull",exec));
end

local function find_webrequest(exec, cmdstr)
	if exec and cmdstr then
		if which(exec) then 
			return cmdstr end
		end
	end
--didn't find requested	
	if which("wget") then 
		return "wget %s > %s"
	elseif which("curl") then
		return "curl %s -o %s"
	elseif which("fetch") then 
		return "fetch %s %s"
	end
	
	return nil
end

local function find_decompress()
	if which("tar") then 
		return "tar -xjfv %s -o %s"
	elseif which("unzip") then
		return "unzip %s -o %s"
	end
	
	return nil
end

local function find_install()
	return "make"
end

local function get_os()
	if package.config:sub(1,1) == "\\" then
		return "WIN"
	else
		if return_shell_output("uname -s", "(FreeBSD)") then 
			return "FreeBSD"
		elseif return_shell_output("uname -s", "(Linux)") then
			return "Linux"
		elseif return_shell_output("uname -s", "(OSX)") then
			return "OSX"
		end
		return "POSIX"
	end
end

local function get_arch(os_name)
if not os_name then return nil end 
	local ok = ""
	if "WIN" then
		ok = return_shell_output("powershell ls env:PROCESSOR_ARCHITECTURE")
	else
		ok = return_shell_output("uname -p")
	end	

	if ok = "amd64" then 
		return "x64"
	elseif ok = "x86_64" then
		return "x64"
	end
	return ok
end


local function return_shell_output(cmd, pattern, debug)
if not cmd then io.stderr:write("cmd to pass to a shell was blank") return nil end
if debug then print(string.format("cmd: %s, pattern: %s", cmd, pattern)) end

	local match = false
	local handle = io.popen(cmd)
	if not pattern then 
		match = handle:read("*a")
	elseif type(pattern) == "string" or type(pattern) == "function"then
		for v in handle:lines() do 
			if debug then print(v) end			
			match = string.match(v, match)
			if match then
				if debug then print(string.format("Found %s", match)) end
				break
			end
		end
	else
		io.stderr:write("Pattern was of wrong type for command " .. cmd)
	end
	handle:close()
	return match
end

local function new (webrequester, decompressor)
	return oses[get_os()]
end
