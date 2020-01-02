To build the installer requires: 
	- VS 2017
	- WIX 3.X, WIX WiX Toolset Visual Studio 2017 Extension. https://wixtoolset.org/releases/


Build Steps(ish)

Lua
	- I'm currently building this in my original VS 2017 files in Winlua-Release1 and copying the files over. Don't you judge me! I can't get the RC files to work in JamPlus. See https://github.com/WinLua/WinLua-VisualStudio

LuaRocks
	- All-in-one exe downloaded and extraced from  http://luarocks.github.io/luarocks/releases/

Libressl- 
	- Open powershell. Run source/winlua-luarocks/vsvars.ps1 (I've added it to my profile script)
	- Pull from git 
	- Find latest git tag and checkout. Save the tag name!
	- Drop to a linux command line and run autogen.sh. It will not build without this step! 
		Note: I'm currenlty using Msys2 but a WSL instance would work fine, though you may have to retreive autotools. I imagine it would look like this: 1)install Debian from Windows Store, 2) `apt install build-essential`  OR `apt install autotools-dev` 3) cd /mnt/c/<path-to-yer-git-repo> 4) ./autogen.sh
	- Run cmake-init-libressl.ps1
	- Run these commands, where X.X.X is the libressl version. e.g. 3.0.2
		cd .\Sources\libressl\build-X.X.X\
		msbuild ALL_BUILD.vcxproj
		cd ..\build-X.X.X-x64\
		msbuild ALL_BUILD.vcxproj
	- Run copy-libressl.ps1


