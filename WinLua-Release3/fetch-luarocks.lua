local lfs = require("lfs")

local sf = string.format
local debug_flag = false
local cmdhdr = "Executing: "
local shell = {
  name = "powershell",
  cmds={
    webrequest = "Invoke-WebRequest -Uri %s -OutFile %s",
    decompress = '"Add-Type -AssemblyName System.IO.Compression.FileSystem; [System.IO.Compression.ZipFile]::ExtractToDirectory(\'%s\',\'%s\')"',
    find_install = '"ls -R %s install.bat"'
  }
}

local function shell_exec(cmd)
  local exec = sf("%s %s", shell.name, cmd)
  if debug_flag then print(cmdhdr..cmd) end
  return os.execute(exec)
end

local function return_shell_output(cmd, pattern)
  if not cmd then io.stderr:write("cmd to pass to a shell was blank") return nil end
  if debug_flag then 
    local out = sf("%s %s, Pattern: %s",cmdhdr, cmd, pattern) 
    print(out)
  end

  cmd = string.format("%s %s",shell.name, cmd)

  local match = false
  local handle = io.popen(cmd)
  if not pattern then 
    match = handle:read("*a")
  elseif type(pattern) == "string" or type(pattern) == "function"then
    for v in handle:lines() do 
      if debug_flag then print(v) end			
      match = string.match(v, pattern)
      if match then
        if debug_flag then print(string.format("Found %s", match)) end
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

local function download_extract(uri, destination)
--Ensure directory exists
  --build and execute the web command
  --Check if file is already there
  --extract destination folder name
  --extract base folder
  local parse_path = "(.-)([^\\]-([^%.]+))$"
  local matches = table.pack(string.match(destination, parse_path))
  if not matches then print("NO MATCHING STRING") exit (1) end
  if not matches.n == 3 then print("MATCHING FAILED") exit(1) end 
  local base_dir = matches[1]
  local extract_dir = string.sub(matches[2], 1, string.len(matches[2])-4)

  --Check if file exists
  ok = file_exists(destination, debug_flag)
  if ok then
    print(sf("%s already exists.", destination));
  else
    --Download
    print("Downloading file...")
    local cmd = sf(shell.cmds.webrequest, uri, destination)
    local exec = sf("%s %s", shell.name, cmd)
    ok = return_shell_output(exec)
  end

  if ok then
    --build and execute the extract command
    print("Extracting...")
    ok = dir_exists(base_dir..extract_dir)
    if ok then 
      print("--delete the existing directory here.")
      shell_exec(sf("remove-item -recurse %s", base_dir..extract_dir))
    end
    cmd = sf(shell.cmds.decompress, destination, base_dir)
    --ok = return_shell_output(exec) -> This doesn't work? does two statements cause it to return early?
    ok = shell_exec(cmd, debug_flag)
  end

  if debug_flag then 
    local ok_str = "failed." 
    if ok then ok_str = "succeeded." end
    print(sf("Extraction process %s", ok_str))
  end
  
  return ok
end


local function run_install(source_path, install_dir, lua_version, lua_bin, quiet)  
  local lr_dir = "LuaRocks"
  local installer = "install.bat"
  local cmd = installer
  local t = { 
    Q = quiet,
    P = sf("%s %s", install_dir, lr_dir),
    LV = lua_version,
    LUA = lua_bin,  
    SELFCONTAINED = true
  }

  for i,v in pairs(t) do
    if type(v) == "string" then
      v = sf("%s",v)
    elseif type(v) == "boolean" then
      v = ""
    end
    cmd = sf("%s /%s %s", cmd, i,v)
  end

  exec = sf("cd %s; .\\%s",source_path, cmd)
  shell_exec(exec)
end

local function run(uri, dest_file, install_dir, lua_version, lua_bin,  run_debug)
  if run_debug then debug_flag = true end
  
  --strip extension from dest_file
  local extracted_dir = string.sub(dest_file, 1, -5)
  local quite = true
  print(sf("Checking for %s",extracted_dir))
  local pwd = lfs.currentdir()
  local ok = lfs.chdir(extracted_dir)

  if ok then --Check for local copy of the zip and download if not exists
    lfs.chdir(pwd)
    io.stderr:write(sf("Directory %s exists. Using local copy...", extracted_dir))
  else
    print("No local copy. Download and extract.")
    ok,err,errmsg = download_extract(uri, dest_file)
  end

  if ok then -- Search for the install.bat file
    local pattern = "Directory:[%s+](.+)"
    local exec = sf("%s %s", shell.name,  sf(shell.cmds.find_install, extracted_dir))
    ok = return_shell_output(exec, pattern)
  else
    print("Error during the extraction process.")
  end

  if ok then -- Run Luarocks\Install.bat
    ok = run_install (extracted_dir, install_dir, lua_version, lua_bin, quiet) 
  else
    print("Failed to find the installer.")
  end

  print (sf("The installer returned: %s", ok))
end

local link = "http://luarocks.github.io/luarocks/releases/luarocks-2.4.4-win32.zip"
local lua_bin = '"c:/Program Files(x86)/WinLua/Lua/5.3/"'
local install_dir = "C:\\Users\\russh\\Git\\BrokenGlass\\lua_scripts"
local name = "luarocks-2.4.4-win32"
local lua_version = "5.3"

run(link, "C:\\temp\\luarocks-2.4.4-win32.zip", install_dir, lua_version, lua_bin, true)
