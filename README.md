# WinLua VisualStudio

Visual Studio 2017 Project and WIX Installers for the WinLua and Distribution

This is a VS 2017 Solution for building WinLua and the installers. The installers also package JamPlus and LibreSSL, though they are not currently part of the build system.

## Lua
Currently our version of lua is divergent from the standard Lua and the changes are marked. I am working to bring clarity to this. To build our Lua Interpreter with 5.1 and 5.current, Lua 5.4, Lua 5.1.5 and LuaFileSystem for both projects, open the Lua 5.4.sln file and build. To build the installers, open the WinLua-Installer.sln file and build. 

## Executables
If you are looking for the latest version of Lua to run on Windows 10, please see our [bin repository](https://github.com/WinLua/bin)

## Licenses
The WinLua project supports non-copyleft software. Lua, LuaFileSystem, WinLua, and Sol2 are all MIT Licensed. LibreSSL is technically BSD Two Clause licensed. The following is the comment from the LibreSSL license:
  
  The OpenSSL toolkit stays under a dual license, i.e. both the conditions of
  the OpenSSL License and the original SSLeay license apply to the toolkit.
  See below for the actual license texts. Actually both licenses are BSD-style
  Open Source licenses. In case of any license issues related to OpenSSL
  please contact openssl-core@openssl.org.
