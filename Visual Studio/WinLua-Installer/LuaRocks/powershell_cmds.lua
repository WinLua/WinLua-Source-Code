--[[
Powershell requires that the command string is in double quotes and everything inside that is single quotes. 
Sort of. I'll get the details and add then here.
--]]
powershell={
webrequest = "Invoke-WebRequest -Uri %s -OutFile %s",
decompress = '"Add-Type -assembly \'system.io.compression.filesystem\'; [io.compression.zipfile]::ExtractToDirectory(\'%s\',\'%s\')"'
find_install_bat = '"ls -R install.bat"'
}
