# WinLua VisualStudio

Visual Studio 2017 Project and WIX Installers for the WinLua and Distribution

TLDR; You can build Lua from any of the Release 1 projects. Mostly everything else is broken.

This repository contains the build solution files for WinLua. The Visual Studio directory contains the files for WinLua Release 1. That is, Lua 5.1, 5.3 and 5.4 (rc1) including installers. Release 2 is a trainwreck, don't go there (I'm gutting it for useful parts until Release 3 is complete). Release 3 has working code, but some sub repositories were poorly imported and are broken, so the sources can't be built. the Visual Studio WIX projects work, so I'm importing binaries built elsewhere. I'll fix this as soon as I get a good Release 3 complete.

## Licenses
The WinLua project supports non-copyleft software. 

Lua, LuaFileSystem, WinLua, Sol2, LLVM-Mingw and Mingw Windows System Libraries are all MIT Licensed. LLVM is Apache License v2.0 with LLVM Exceptions. LibreSSL is technically BSD Two Clause licensed. The following is the comment from the LibreSSL license:
  
  The OpenSSL toolkit stays under a dual license, i.e. both the conditions of
  the OpenSSL License and the original SSLeay license apply to the toolkit.
  See below for the actual license texts. Actually both licenses are BSD-style
  Open Source licenses. In case of any license issues related to OpenSSL
  please contact openssl-core@openssl.org.
