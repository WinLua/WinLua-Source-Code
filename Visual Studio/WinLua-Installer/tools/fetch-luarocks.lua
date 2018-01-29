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
    P = sf("%s %s", I.install_dir, I.lr_dir),
    LV = I.lua_version,
    LUA = I.lua_bin,  
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
    applog(sf("%s state:",p.INSTALL_NAME))
    for i,v in pairs(p) do
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

local function init(url,temp_dir, install_dir, bin_dir, version, set_debug)
  debug_flag = set_debug
  p = {}
  p.run_path = script_path()
  p.log_name = "lri.log"
  p.log_full_path = sf("%s\\%s",p.run_path,p.log_name)
  outfile = io.open(p.log_full_path,"w")
  assert(outfile, sf("Logger was unable to start. Path: %s",p.log_path));
  
  if not url then 
    applog("Error: You must provide a download uri for the Luarocks Win32 zip file.")
    applog("\t--> See http://luarocks.github.io/luarocks/releases/ for files")
    print("Early exit. Check logs.")
    os.exit(1)
  end
  
  if not temp_dir or not version then 
    applog("Error: You must provide a temporary download directory (that you have permission to) and a lua version")
    print("Early exit, check logs.")
    os.exit(1)
  end
  
  p.url = url
  p.link_parsed = parse_url(p.url)
  p.INSTALL_NAME = string.sub(p.link_parsed[2],1,-5) --"luarocks-2.4.3-win32"
  -- get script path and strip off tools dir
  p.base_path = string.sub(script_path(),1,(string.len("\\tools\\")*-1))
  p.lua_bin = bin_dir -- sf("%s\\bin", p.base_path)
  p.install_dir = install_dir --sf("%s", p.base_path)
  p.temp_dir = temp_dir
  p.temp_file = sf("%s\\%s",p.temp_dir,p.link_parsed[2])
  p.extracted_dir = sf("%s\\%s",p.temp_dir,p.INSTALL_NAME)
  p.lua_version = version
  p.debug = set_debug
  p.lr_dir = "LuaRocks"
  p.installer = "install.bat"
  
  return p
end 
local link = "http://luarocks.github.io/luarocks/releases/luarocks-2.4.3-win32.zip"
local temp = "C:\\Temp"
local lua_bin = ("C:\\Program Files (x86)\\WinLua\\Lua\\5.3" or arg[-1])
local install_dir = (nil or "C:\\Temp")
local ver = "5.3"
--Link, temp, install, bin, version, debug
--local result = pcall(run, init(arg[1],arg[2],arg[3], arg[4], arg[5], arg[6]))
local result = pcall(run, init(link, temp, install_dir, lua_bin, ver, true))
