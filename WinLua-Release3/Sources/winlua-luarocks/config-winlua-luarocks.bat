@echo on
REM Get the current LuaRocks dir
SET LR_DIR="%~dp0.."
REM Move to the share folder
cd "%LR_DIR%\share"
REM Run Lua in powershell. This won't work in CMD because it doesn't
REM resolve the path. grrr. Not sure if this will work...
powershell "lua get-path.lua"
REM Get the lua path. grrr. Stupid batch files
set /p LUA_DIR=<c:\temp\winlua-path.txt
REM Run the configurator.
lua.exe create-config.lua /LUA "%LUA_DIR%.." /P "%LR_DIR%\bin" /CONFIG "%LR_DIR%"
