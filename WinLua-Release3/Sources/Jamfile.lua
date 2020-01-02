local project_name = 'winlua'
BINARY_OR_TEXT_COMMAND_LINE = 'text'
--~ ospath = require 'ospath'
--~ filefind = require 'filefind'
local BIN = '../Deploy/x86/WinLua/'
local so_ext = '.dll'
local static_ext = '.lib'

--~ Unzip something. Josh has build in tarball features?
local function call7Zip()
	
end
--~ Run the bash script in msys2
--~ the script runs autogen and then uses cmake to create the 
--~ VS project. The cmake step could alternatively be done in 
--~ cmd or ps, but it seemed to fit with this toolchain
local function initLibreSSL(bits)
	if not bits then bits = 32 end
	local file = "../libressl-autogen.sh"
	local bash = "C:\\msys64\\usr\\bin\\bash"
	local dir = "build-vs2017"
	local arch = ""
	if bits == 64 then 
		dir = dir.."-64"
		arch = "Win64"
	end
	local cmd = bash.." "..file.." "..dir.." 'Visual Studio 15 2017' "..arch
	os.execute(cmd)
	 --~ C:\msys64\usr\bin\bash -lc "cd git/WinLua-Mk3/Sources/libressl && ./autogen.sh"
	--~ //chdir to libressl
	--~ check for dir build-vs2017
	--~ if not dir then mkdir 
	--~ chdir build-vs2017
	--~ cmake -DBUILD_SHARED_LIBS=ON -G"Visual Studio 15 2017" ..
	--~ run vs-shell.ps1 --> Will need ot include msbuild libressl to preserve environment
end

--~ Copy the libre files to the output directory
local function copyLibreSSL(dest)
	jam['C.ActiveTarget']("copy-libressl")
	jam['CopyFile']( nil, dest.."\\libressl.exe", "C:\\Users\\russh\\git\\WinLua-Mk3\\Sources\\libressl\\build-2.9.0\\apps\\openssl\\Debug\\openssl.exe")
	--~ jam['CopyFile']( nil, dest.."\\crypto-44.dll", "C:\\Users\\russh\\git\\WinLua-Mk3\\Sources\\libressl\\build-vs2017\\crypto\\Debug\\crypto-44.dll")
	--~ jam['CopyFile']( nil, dest.."\\ssl-46.dll", "C:\\Users\\russh\\git\\WinLua-Mk3\\Sources\\libressl\\build-vs2017\\ssl\\Debug\\ssl-46.dll")
	--~ jam['CopyFile']( nil, dest.."\\tls-18.dll", "C:\\Users\\russh\\git\\WinLua-Mk3\\Sources\\libressl\\build-vs2017\\tls\\Debug\\tls-18.dll")
	jam['Depends']("all","libressl")
	--~ jam['CopyFile']( libressl, dest.."libressl.exe", "C:\\Users\\russh\\git\\WinLua-Mk3\\Sources\\libressl\\build-vs2017\\apps\\openssl\\Debug\\openssl.exe")
--~ "C:\\Users\\russh\\git\\WinLua-Mk3\\Sources\\libressl\\build-vs2017\\apps\\openssl\\Debug\\openssl.exe"
--~ "C:\Users\russh\git\WinLua-Mk3\Sources\libressl\build-vs2017\crypto\Debug\crypto-44.dll"
--~ "C:\Users\russh\git\WinLua-Mk3\Sources\libressl\build-vs2017\ssl\Debug\ssl-46.dll"
--~ "C:\Users\russh\git\WinLua-Mk3\Sources\libressl\build-vs2017\tls\Debug\tls-18.dll"
--~ copy openssl.exe, crypto.dll, tls.dll, ssl.dll...?
end

--~ Do the libressl build. This should be a jam action or target?
local function buildLibreSSL(dest)
	--~ initLibreSSL()
	--~ os.execute("powershell ../vs-shell.ps1 C:\\Users\\russh\\git\\WinLua-Mk3\\Sources\\libressl\\build-vs2017 libressl.sln")
	--~ os.execute("powershell vs-shell.ps1 ")
	copyLibreSSL(BIN.."\\libressl")
end


local function buildInstaller()
--~ /need to set the evnironment and run msbuild on the installer
end

--~ Write a lua file to a string variable in an hpp file.
--~ var_name - name of the C variable refrencing the script
--~ filename - output file name
--~ src_file - lua file to encode
local function genHppFile(var_name, filename, src_file)
	local hpp = io.open(filename, 'w')
	hpp:write(string.format('char * %s =  R"V0G0N(\r\n', var_name))
	local file = io.open(src_file, "r")

	for l in file:lines() do
		hpp:write(l..'\n')
	end
	file:close()
	hpp:write(')V0G0N";')
	hpp:close()
	print('hpp file written.')
end

local function downloadLuaRocks(uri,dest)

end

--~ Copy the binary luarocks to our installer directory
local function copyLuaRocks(dest)

end

--~ Create and return a table with Lua version and naming information. 
local function makeVersion(version)
    if not version then 
        return nil,'Need a version number' 
    end
    
    --~ so = lua51, lua52 etc. so_target = lua51-shared...
    local so = string.format('lua%s', version:gsub('%.',''))
    if so:len() > 5 then
		so = so:sub(1,5)
	end
	local so_full = string.format('lua%s%s', version:gsub('%.',''), so_ext)
    local path = string.format('lua-%s/src',version)
    local lua_build = {
        version = version,
        --~ sourcepath = path,
        source_path = jam_expand('@(' .. path .. ':T)')[1],
        so_target = so..'-shared',
        static_target = so..'-static',
        shared_object = so,
        static_object = so,
        shared_object_full = so_full,
        outpath = BIN
    }
    return lua_build
end

local function buildLFS(build)

	local target_name = 'lfs-'..build.shared_object
	local path = 'luafilesystem/src'
	--~ local lfs_path = jam_expand('@(' .. path .. ':T)')[1]
	jam['C.ActiveTarget'](target_name)
	jam['C.Defines'](nil, '_WIN32')
	jam['C.OutputPath'](nil, build.outpath)
	jam['C.OutputName'](nil, 'lfs')
	jam['C.IncludeDirectories'] (nil, build.source_path)
	jam['C.LinkLibraries']( nil, build.so_target)
	jam['C.Library'](nil, {path..'/*@=**.c@=**.h'}, 'shared')
	jam['Depends']('all', target_name)
end

local function buildLua(version_table, winlua)
	local shared_outpath
	local static_outpath
	jam.CopyFile('C:/temp/itworked.txt','C:/temp/conf.lcf')
	for i,v in pairs(version_table) do
		local build = makeVersion(v)
		if winlua then
			build.source_path = 'winlua-src/' .. build.source_path
			shared_outpath = build.outpath ..build.version:sub(1,3)
			static_outpath = build.outpath ..build.version:sub(1,3)
		else
			shared_outpath = build.outpath .. '/bin'
			static_outpath = build.outpath .. '/static'
		end
		--Target for intermediary files
		jam['C.ActiveTarget'](build.so_target)
		jam['C.OutputPath']( nil, shared_outpath)
		jam['C.OutputName']( nil, build.shared_object)
		jam['C.Defines']( nil, 'LUA_BUILD_AS_DLL')
		jam['C.IncludeDirectories']( nil, build.source_path)
		if winlua then
			jam['C.Library']( nil, {build.source_path..'/*@=**.c@=**.h'}, 'shared')
		else
			 jam['C.Library']( nil, {build.source_path..'/*@=**.c@=**.h@-**/lua.c@-**/luac.c'}, 'shared')
		end
		
		--~ --Static Library: Target for intermediary files
		jam['C.ActiveTarget']( build.static_target)
		jam['C.OutputPath']( nil, static_outpath)
		jam['C.OutputName']( nil, build.static_object)
		jam['C.IncludeDirectories']( nil, build.source_path)
		--lua.c is patched and needs to be included with the other files
		jam['C.Library']( nil, {build.source_path..'/*@=**.c@=**.h@-**/lua.c@-**/luac.c'}, 'static')
		jam['Depends']('all', build.static_target)
		
		--Target for Shared Object
		jam['C.ActiveTarget']( build.shared_object)
		jam['C.OutputPath'](nil,  shared_outpath)
		--Why no target for the executable?
			jam['Depends']('all', build.so_target)
		build.outpath = shared_outpath
		buildLFS(build)
	end
end

local function buildDTLua()
	local hpp = "winlua-src\\src\\getopt-lua.hpp"
	local getopt = "getopt.lua"
	--~ NOTE: This runs regardless of the target because it's outside
	--~ the jam execution
	genHppFile('get_opts', hpp, getopt)

	--~ hard coded for now. pretend this was returned from buildLua
	link_libs = {'lua53-shared'}
	buildLua({'5.1.5','5.2.4','5.3.5','5.4'}, true)
	jam['C.ActiveTarget']( project_name)
	jam['C.OutputPath'](nil, BIN)
	jam['C.OutputName'](nil, project_name)
	jam['C.IncludeDirectories'](nil, {'lua-5.3.5/src','src/'})
	jam['C.LinkLibraries'](nil, link_libs)
	jam['C.Application'](nil, 'src/dtlua.cpp')
	jam['Depends']('all', project_name)
end

local function buildStandardLua()
	BIN = '../Deploy/x86/Lua'
	link_libs = {'lua53-shared'}
	buildLua({'5.3.5'})
	jam['C.ActiveTarget']( 'lua')
	jam['C.OutputPath'](nil, BIN .. '/bin')
	jam['C.OutputName'](nil, 'lua')
	jam['C.IncludeDirectories'](nil, {'lua-5.3.5/src'})
	jam['C.LinkLibraries'](nil, link_libs)
	jam['C.PrecompiledHeader'](nil, {'stdafx' , 'resources/resource.rc','resources/stdafx.h'})
	jam['C.MFC'](nil, {'link', 'shared'})
	jam['C.Rc'](nil, 'resources/resource.rc')
	--~ jam['C.Application'](nil, {'lua-5.3.5/src/luac.c', 'C.Rc', 'resources/resource.rc'})
	jam['C.Application'](nil, {'resources/stdafx.cpp','lua-5.3.5/src/lua.c'})

	
	jam['C.ActiveTarget']( 'luac')
	jam['C.OutputPath'](nil, BIN .. '/bin')
	jam['C.OutputName'](nil, 'luac')
	jam['C.IncludeDirectories'](nil, {'lua-5.3.5/src'})
	jam['C.LinkLibraries'](nil, 'lua53-static' , 'static')
	--~ jam['C.Define'](nil, '_AFX_NO_OLE_SUPPORT')
	jam['C.PrecompiledHeader'](nil, 'stdafx', 'resources/stdafx.h')
	jam['C.MFC'](nil, {'link', 'shared'})
	jam['C.Rc'](nil, 'resources/resource.rc')
	--~ jam['C.Application'](nil, {'lua-5.3.5/src/luac.c', 'C.Rc', 'resources/resource.rc'})
	jam['C.Application'](nil, {'resources/stdafx.cpp','lua-5.3.5/src/luac.c'})
end
--~ buildDTLua()
buildStandardLua()
--~ This runs every time regardless of the target. I assume then it needs
--~ to be added to the jam manefest (?) and executed that way as a target? 
--~ Or is an action more appropriate?
--~ buildLibreSSL()
--~ copyLibreSSL('C:\\temp\\')
--~ copyLuaRocks()
--~ NOTE: buildInstaller needs to be controlled by jamplus to ensure all targets are finished 
--~ before creating the installer
--~ buildInstaller()
