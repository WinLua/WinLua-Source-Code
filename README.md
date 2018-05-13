# WinLua VisualStudio

Visual Studio 2017 Project and WIX Installers for the WinLua and Distribution

This repository contains the build solution files for WinLua. The Visual Studio directory contains the files for WinLua Release 1. That is, Lua 5.1 and Lua 5.3 including installers. Release 2 contains a new branch of code that has a modified interpreter (lua.exe) that loads Lua 5.4 by default, or lua 5.1 if the -51 flag is specified. Release 2 also contains an ISWix project files for building an installer for WinLua R2, LibreSSL and JamPlus. *WinLua R2 works, the installers don't.*

## Lua in Release2
Currently our version of lua in the Release2 branch is divergent from the standard Lua and the changes are *unmarked*. I am working to bring clarity to this.

## Executables
If you are looking for the latest version of Lua to run on Windows 10, please see our [bin repository](https://github.com/WinLua/bin)

## Licenses
The WinLua project supports non-copyleft software. Lua, LuaFileSystem, WinLua, and Sol2 are all MIT Licensed. LibreSSL is technically BSD Two Clause licensed. The following is the comment from the LibreSSL license:
  
  The OpenSSL toolkit stays under a dual license, i.e. both the conditions of
  the OpenSSL License and the original SSLeay license apply to the toolkit.
  See below for the actual license texts. Actually both licenses are BSD-style
  Open Source licenses. In case of any license issues related to OpenSSL
  please contact openssl-core@openssl.org.
