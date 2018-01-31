--[[
Fetch-luarocks - Download and run the Luarocks installer. 
--]]

local lfs = require("lfs")
local outfile = true
local sf = string.format
local cmdhdr = "Executing: "
local debug_flag = false

local shell = {
  name = "powershell",
  cmds={
    webrequest = "Invoke-WebRequest -Uri %s -OutFile %s",
    decompress = '"Add-Type -AssemblyName System.IO.Compression.FileSystem; [System.IO.Compression.ZipFile]::ExtractToDirectory(\'%s\',\'%s\')"',
    find_install = '"ls -R %s install.bat"'
  }
}

local function script_path()
   local str = debug.getinfo(2, "S").source:sub(2)
   -- protects against debugging in ZeroBrane
   str = str:gsub("/","\\")
   if debug_flag then print(str) end
   return str:match("(.*[/\\])")
end

local function applog(str)
    outfile:write(sf("%s\r", str))
end

local function shell_exec(cmd)
  local exec = sf("%s %s", shell.name, cmd)
  if debug_flag then applog(cmdhdr..cmd) end
  return os.execute(exec)
end

local function return_shell_output(cmd, pattern)
  if not cmd then io.stderr:write("cmd to pass to a shell was blank") return nil end
  if debug_flag then 
    local out = sf("%s %s, Pattern: %s",cmdhdr, cmd, pattern) 
    applog(out)
  end
  
  cmd = string.format("%s %s",shell.name, cmd)
  local match = false
  local handle = io.popen(cmd)
  if not pattern then 
    match = handle:read("*a")
  elseif type(pattern) == "string" or type(pattern) == "function"then
    for v in handle:lines() do 
      if debug_flag then applog(v) end			
      match = string.match(v, pattern)
      if match then
        if debug_flag then applog(string.format("Found %s", match)) end
        break
      end
    end
  else
    io.stderr:write("Pattern was of wrong type for command " .. cmd)
  end
  handle:close()
  return match
end

local function return_shell_output2(cmd, pattern)
  if not cmd then io.stderr:write("cmd to pass to a shell was blank") return nil end
  if debug_flag then 
    local out = sf("%s %s, Pattern: %s",cmdhdr, cmd, pattern) 
    applog(out)
  end
  
  --~ cmd = string.format("%s %s",shell.name, cmd)
  local match = false
  local handle = io.popen(cmd)
  if not pattern then 
    match = handle:read("*a")
  elseif type(pattern) == "string" or type(pattern) == "function"then
    for v in handle:lines() do 
      if debug_flag then applog(v) end			
      match = string.match(v, pattern)
      if match then
        if debug_flag then applog(string.format("Found %s", match)) end
        break
      end
    end
  else
    io.stderr:write("Pattern was of wrong type for command " .. cmd)
  end
  handle:close()
  return match
end

--Debug removed so we can call this before our logger is set up
local function resolve_path(str, no_debug)	
	if no_debug then debug_flag = false	end	
	local val =  return_shell_output(sf("(resolve-path %s).Path", str), "(.+)")	
	if no_debug then debug_flag = true end
	return val
end

--Debug removed so we can call this before our logger is set up
local function get_lua_version(lua_exe, no_debug)
	if no_debug then debug_flag = false	end
	local cnt = 0
	--~ lua_exe = lua_exe:gsub("\\", "\\\\")
	lua_exe, cnt = lua_exe:gsub("Program Files (x86)","'Program Files (x86)'")
	if cnt == 0 then 
		lua_exe, cnt = lua_exe:gsub('Program Files','"Program Files"')
	end
	--~ local cmd = sf('%s -e "print(_VERSION:match(\'(%%d.%%d)\'))"', lua_exe)
	local cmd = sf('%s -e "print(_VERSION:match(\'(%%d.%%d)\'))"', lua_exe)
	print(cmd)
	local val = return_shell_output2(cmd, "(.+)")
	print(val)
	if no_debug then debug_flag = true end
	return val
end

local function dir_exists(dir)
  local exec = sf("[System.IO.Directory]::Exists('%s')", dir)
  return return_shell_output(exec ,"(True)")
end

local function file_exists(file)
  local exec = sf("[System.IO.File]::Exists('%s')", file)
  return return_shell_output(exec, "(True)")
end

local function parse_url(url)
  local capture = "(.-)([^/]-([^%.]+))$"
  if debug_flag then applog(sf("%s pattern: %s",url, capture)) end
  local matches = table.pack(string.match(url, capture))
  if not matches then applog(sf("Not a path: %s",url)) exit (1) end
  if not matches.n == 3 then applog(sf("Matching failed %s \r\n\tpattern: %s",url, capture)) os.exit(1) end 
  return matches
end


local function parse_path(path)
  local capture = "(.-)([^\\]-([^%.]+))$"
  if debug_flag then applog(sf("%s pattern: %s",path, capture)) end
  local matches = table.pack(string.match(path, capture))
  if not matches then applog(sf("Not a path: %s",path)) exit (1) end
  if not matches.n == 3 then applog(sf("Matching failed %s \r\n\tpattern: %s",path, capture)) os.exit(1) end 
  return matches
end

local function remove_temp_items(I)
	--This is where we would remove the temp files.
	return false
end

local function download_extract(I)
--Ensure directory exists
  --build and execute the web command
  --Check if file is already there
  --extract destination folder name
  --extract base folder
  local ok = file_exists(I.temp_file)
  if ok then
    applog(sf("%s already exists.", I.temp_file));
  else
    --Download
    applog("Downloading file...")
    local cmd = sf(shell.cmds.webrequest, I.url, I.temp_file)
    local exec = sf("%s %s", shell.name, cmd)
    ok = return_shell_output(exec)
  end

  if ok then
    --build and execute the extract command
    applog("Extracting...")
    ok = dir_exists(I.extracted_dir)
    if ok then 
      applog("--delete the existing directory here.")
      ok = shell_exec(sf("remove-item -recurse %s", I.extracted_dir))
      if not ok then 
        applog(sf("Error: Failed to delete original directory. Running with what we've got..."))
        return true
      end
    end
    cmd = sf(shell.cmds.decompress, I.temp_file, I.temp_dir.."\\")
    --ok = return_shell_output(exec) -> This doesn't work? does two statements cause it to return early?
    ok = shell_exec(cmd, debug_flag)
  end

  if debug_flag then 
    local ok_str = "failed." 
    if ok then ok_str = "succeeded." end
    applog(sf("Extraction process %s", ok_str))
  end
  
  return ok
end


local function run_install(I)  
  local cmd = I.installer
  local t = { 
    Q = I.quiet,
    P = I.install_dir,
    LV = I.lua_version,
    LUA = I.lua_dir,  
    SELFCONTAINED = true
  }

  for i,v in pairs(t) do
    if type(v) == "string" then
      v = sf("'%s'",v)
    elseif type(v) == "boolean" then
      v = ""
    end
    cmd = sf("%s /%s %s", cmd, i,v)
  end

  exec = sf("cd %s; .\\%s",I.extracted_dir, cmd)
  shell_exec(exec)
end



local function run(I)
  applog(sf("LuaRocks %s for  WinLua. %s", I.INSTALL_NAME, os.date("%Y-%b-%d %I:%M:%S %p")))
  
    if debug_flag then
    applog(sf("%s state:",I.INSTALL_NAME))
    for i,v in pairs(I) do
      applog(sf("\t%s->\t%s",i,v))
    end
  end
 
  --strip extension from dest_file
--  local extracted_dir = string.sub(dest_file, 1, -5)
--  local quite = true
  applog(sf("Checking for %s",I.extracted_dir))
  local pwd = lfs.currentdir()
  
  local ok = lfs.chdir(I.extracted_dir)

  if ok then --Check for local copy of the zip and download if not exists
    lfs.chdir(pwd)
    applog(sf("Directory %s exists. Using local copy...", I.extracted_dir))
  else
    applog("No local copy. Download and extract.")
    ok,err,errmsg = download_extract(I)
  end

  if ok then -- Search for the install.bat file
    local pattern = "Directory:[%s+](.+)"
    local exec = sf("%s %s", shell.name,  sf(shell.cmds.find_install, I.extracted_dir))
    ok = return_shell_output(exec, pattern)
  else
    applog("Error: Error during the extraction process.")
  end

  if ok then -- Run Luarocks\Install.bat
    ok = run_install (I) 
  else
    applog("Error: Failed to find the installer.")
  end

  applog (sf("The installer returned: %s", ok))
  outfile:close()
end

local function init(params, set_debug)
  debug_flag = set_debug
  params.installer = "install.bat"
  params.log_name = "lri.log"
  params.log_full_path = sf("%s\\%s", params.temp_dir,params.log_name)
  outfile = io.open(params.log_full_path, "w")
  assert(outfile, sf("Logger was unable to start. Path: %s", params.log_full_path));
  
  if not params.url then 
    applog("Error: You must provide a download uri for the Luarocks Win32 zip file.")
    applog("\t--> See http://luarocks.github.io/luarocks/releases/ for files")
    print("Early exit. Check logs.")
    os.exit(1)
  end
  
  --~ if not temp_dir or not version then 
    --~ applog("Error: You must provide a temporary download directory (that you have permission to) and a lua version")
    --~ print("Early exit, check logs.")
    --~ os.exit(1)
  --~ end

  params.link_parsed = parse_url(params.url)
  params.INSTALL_NAME = string.sub(params.link_parsed[2],1,-5) --"luarocks-2.4.3-win32"
  -- get script path and strip off tools dir
  --~ p.base_path = string.sub(script_path(),1,(string.len("\\tools\\")*-1))

  params.temp_file = sf("%s\\%s", params.temp_dir, params.link_parsed[2])
  params.extracted_dir = sf("%s\\%s", params.temp_dir, params.INSTALL_NAME)
 
  return params
end 

local p ={}
--Link, temp, install, bin, version, debug
if arg[1] == "-h" or arg[1] == "--help" then
	print("url, temp_dir, install_dir, lua_base_dir, version, debug")
	os.exit()
elseif arg[1] == "-u" or arg[1] == "--unattended" then
	p.url = "http://luarocks.github.io/luarocks/releases/luarocks-2.4.3-win32.zip"
	p.temp_dir = resolve_path('$env:localappdata', true) -- or "C:\\Temp"
	p.install_dir = string.sub(script_path(),1,(string.len("\\tools\\")*-1)).."LuaRocks"
	p.lua_dir = string.sub(arg[-1],1,(string.len("\\bin\\lua.exe")*-1))
	p.lua_version = get_lua_version(arg[-1],true)
else
	p.url = arg[1]
	p.temp_dir = resolve_path(arg[2], true) -- or "C:\\Temp"
	p.install_dir = resolve_path(arg[3], true)
	p.lua_dir = string.sub(arg[-1],1,(string.len("\\lua.exe")*-1))
	p.lau_version = get_lua_version(arg[-1],true)
end

local result = pcall(run, init(p, true))

print(sf("Is okay? %s", result))
