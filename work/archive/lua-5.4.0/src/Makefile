# Makefile for building Lua # See ../doc/readme.html for installation and customization instructions.

# == CHANGE THE SETTINGS BELOW TO SUIT YOUR ENVIRONMENT =======================

# Your platform. See PLATS for possible values.
PLAT= windows

#CC= cl.exe
CFLAGS= -O2 -DLUA_COMPAT_5_3 $(SYSCFLAGS) $(MYCFLAGS)
LDFLAGS= $(SYSLDFLAGS) $(MYLDFLAGS)
LIBS= -lm $(SYSLIBS) $(MYLIBS)

AR= ar rcu
RANLIB= ranlib
RM= del /F

SYSCFLAGS=
SYSLDFLAGS=
SYSLIBS=

MYCFLAGS=
MYLDFLAGS=
MYLIBS=
MYOBJS=

# == END OF USER SETTINGS -- NO NEED TO CHANGE ANYTHING BELOW THIS LINE =======

PLATS= windows #aix bsd c89 freebsd generic linux macosx mingw posix solaris

LUA_A=	liblua.lib
CORE_O=	lapi.obj lcode.obj lctype.obj ldebug.obj ldo.obj ldump.obj lfunc.obj lgc.obj llex.obj lmem.obj lobject.obj lopcodes.obj lparser.obj lstate.obj lstring.obj ltable.obj ltm.obj lundump.obj lvm.obj lzio.obj
LIB_O=	lauxlib.obj lbaselib.obj lcorolib.obj ldblib.obj liolib.obj lmathlib.obj loadlib.obj loslib.obj lstrlib.obj ltablib.obj lutf8lib.obj linit.obj
BASE_O= $(CORE_O) $(LIB_O) $(MYOBJS)

LUA_T=	lua.exe
LUA_O=	lua.obj
LUA_SO=	liblua.dll

LUAC_T=	luac.exe
LUAC_O=	luac.obj

ALL_O= $(BASE_O) $(LUA_O) $(LUAC_O)
#~ ALL_T= $(LUA_A) $(LUA_T) $(LUAC_T) $(LUA_SO)
ALL_T= $(LUA_T) $(LUAC_T) $(LUA_SO)
ALL_A= $(LUA_A)

# Targets start here.
default: $(PLAT)

all:	$(ALL_T)

obj:	$(ALL_O)

lib:	$(ALL_A)

$(LUA_SO):	$(CORE_O) $(LIB_O)
	@echo LUA_SO
	$(CC) $@ $(CFLAGS) $(LDFLAGS) $(MYLDFLAGS) -shared -Wl  -out:$?

$(LUA_A): $(BASE_O)
	echo LUA_A
	$(CC) $@ $(BASE_O) -out:$(LUA_A)
#	$(RANLIB) $@

$(LUA_T): $(LUA_O) $(LUA_A)
	echo LUA_T
	$(CC) $@ $(LDFLAGS) $(LUA_O) $(LUA_A) $(LIBS) -out:$(LUA_T)

$(LUAC_T): $(LUAC_O) $(LUA_A)
	$(CC) $@ $(LDFLAGS) $(LUAC_O) $(LUA_A) $(LIBS)

clean:
	$(RM) $(ALL_T) $(ALL_O)

depend:
	@$(CC) $(CFLAGS) -MM l*.c

echo:
	@echo "PLAT= $(PLAT)"
	@echo "CC= $(CC)"
	@echo "CFLAGS= $(CFLAGS)"
	@echo "LDFLAGS= $(SYSLDFLAGS)"
	@echo "LIBS= $(LIBS)"
	@echo "AR= $(AR)"
	@echo "RANLIB= $(RANLIB)"
	@echo "RM= $(RM)"

# Convenience targets for popular platforms
ALL= all

windows:
	$(MAKE) $(ALL) SYSCFLAGS="-DLUA_BUILD_AS_DLL" SYSLIBS="-Wl,-E"

none:
	@echo "Please do 'make PLATFORM' where PLATFORM is one of these:"
	@echo "   $(PLATS)"

aix:
	$(MAKE) $(ALL) CC="xlc" CFLAGS="-O2 -DLUA_USE_POSIX -DLUA_USE_DLOPEN" SYSLIBS="-ldl" SYSLDFLAGS="-brtl -bexpall"

bsd:
	$(MAKE) $(ALL) SYSCFLAGS="-DLUA_USE_POSIX -DLUA_USE_DLOPEN" SYSLIBS="-Wl,-E"

c89:
	$(MAKE) $(ALL) SYSCFLAGS="-DLUA_USE_C89" CC="gcc -std=c89"
	@echo ''
	@echo '*** C89 does not guarantee 64-bit integers for Lua.'
	@echo ''


freebsd:
	$(MAKE) $(ALL) SYSCFLAGS="-DLUA_USE_LINUX" SYSLIBS="-Wl,-E"

generic: $(ALL)

linux:	linux-noreadline

linux-noreadline:
	$(MAKE) $(ALL) SYSCFLAGS="-DLUA_USE_LINUX" SYSLIBS="-Wl,-E -ldl"

linux-readline:
	$(MAKE) $(ALL) SYSCFLAGS="-DLUA_USE_LINUX -DLUA_USE_READLINE" SYSLIBS="-Wl,-E -ldl -lreadline"

macosx:
	$(MAKE) $(ALL) SYSCFLAGS="-DLUA_USE_MACOSX -DLUA_USE_READLINE" SYSLIBS="-lreadline"

mingw:
	$(MAKE) "LUA_A=lua53.dll" "LUA_T=lua.exe" \
	"AR=$(CC) -shared -o" "RANLIB=strip --strip-unneeded" \
	"SYSCFLAGS=-DLUA_BUILD_AS_DLL" "SYSLIBS=" "SYSLDFLAGS=-s" lua.exe
	$(MAKE) "LUAC_T=luac.exe" luac.exe

posix:
	$(MAKE) $(ALL) SYSCFLAGS="-DLUA_USE_POSIX"

solaris:
	$(MAKE) $(ALL) SYSCFLAGS="-DLUA_USE_POSIX -DLUA_USE_DLOPEN -D_REENTRANT" SYSLIBS="-ldl"

# list targets that do not create files (but not all makes understand .PHONY)
.PHONY: all $(PLATS) default o a clean depend echo none

# DO NOT DELETE

lapi.obj: lapi.c lprefix.h lua.h luaconf.h lapi.h llimits.h lstate.h \
 lobject.h ltm.h lzio.h lmem.h ldebug.h ldo.h lfunc.h lgc.h lstring.h \
 ltable.h lundump.h lvm.h
lauxlib.obj: lauxlib.c lprefix.h lua.h luaconf.h lauxlib.h
lbaselib.obj: lbaselib.c lprefix.h lua.h luaconf.h lauxlib.h lualib.h
lcode.obj: lcode.c lprefix.h lua.h luaconf.h lcode.h llex.h lobject.h \
 llimits.h lzio.h lmem.h lopcodes.h lparser.h ldebug.h lstate.h ltm.h \
 ldo.h lgc.h lstring.h ltable.h lvm.h
lcorolib.obj: lcorolib.c lprefix.h lua.h luaconf.h lauxlib.h lualib.h
lctype.obj: lctype.c lprefix.h lctype.h lua.h luaconf.h llimits.h
ldblib.obj: ldblib.c lprefix.h lua.h luaconf.h lauxlib.h lualib.h
ldebug.obj: ldebug.c lprefix.h lua.h luaconf.h lapi.h llimits.h lstate.h \
 lobject.h ltm.h lzio.h lmem.h lcode.h llex.h lopcodes.h lparser.h \
 ldebug.h ldo.h lfunc.h lstring.h lgc.h ltable.h lvm.h
ldo.obj: ldo.c lprefix.h lua.h luaconf.h lapi.h llimits.h lstate.h \
 lobject.h ltm.h lzio.h lmem.h ldebug.h ldo.h lfunc.h lgc.h lopcodes.h \
 lparser.h lstring.h ltable.h lundump.h lvm.h
ldump.obj: ldump.c lprefix.h lua.h luaconf.h lobject.h llimits.h lstate.h \
 ltm.h lzio.h lmem.h lundump.h
lfunc.obj: lfunc.c lprefix.h lua.h luaconf.h lfunc.h lobject.h llimits.h \
 lgc.h lstate.h ltm.h lzio.h lmem.h
lgc.obj: lgc.c lprefix.h lua.h luaconf.h ldebug.h lstate.h lobject.h \
 llimits.h ltm.h lzio.h lmem.h ldo.h lfunc.h lgc.h lstring.h ltable.h
linit.obj: linit.c lprefix.h lua.h luaconf.h lualib.h lauxlib.h
liolib.obj: liolib.c lprefix.h lua.h luaconf.h lauxlib.h lualib.h
llex.obj: llex.c lprefix.h lua.h luaconf.h lctype.h llimits.h ldebug.h \
 lstate.h lobject.h ltm.h lzio.h lmem.h ldo.h lgc.h llex.h lparser.h \
 lstring.h ltable.h
lmathlib.obj: lmathlib.c lprefix.h lua.h luaconf.h lauxlib.h lualib.h
lmem.obj: lmem.c lprefix.h lua.h luaconf.h ldebug.h lstate.h lobject.h \
 llimits.h ltm.h lzio.h lmem.h ldo.h lgc.h
loadlib.obj: loadlib.c lprefix.h lua.h luaconf.h lauxlib.h lualib.h
lobject.obj: lobject.c lprefix.h lua.h luaconf.h lctype.h llimits.h \
 ldebug.h lstate.h lobject.h ltm.h lzio.h lmem.h ldo.h lstring.h lgc.h \
 lvm.h
lopcodes.obj: lopcodes.c lprefix.h lopcodes.h llimits.h lua.h luaconf.h
loslib.obj: loslib.c lprefix.h lua.h luaconf.h lauxlib.h lualib.h
lparser.obj: lparser.c lprefix.h lua.h luaconf.h lcode.h llex.h lobject.h \
 llimits.h lzio.h lmem.h lopcodes.h lparser.h ldebug.h lstate.h ltm.h \
 ldo.h lfunc.h lstring.h lgc.h ltable.h
lstate.obj: lstate.c lprefix.h lua.h luaconf.h lapi.h llimits.h lstate.h \
 lobject.h ltm.h lzio.h lmem.h ldebug.h ldo.h lfunc.h lgc.h llex.h \
 lstring.h ltable.h
lstring.obj: lstring.c lprefix.h lua.h luaconf.h ldebug.h lstate.h \
 lobject.h llimits.h ltm.h lzio.h lmem.h ldo.h lstring.h lgc.h
lstrlib.obj: lstrlib.c lprefix.h lua.h luaconf.h lauxlib.h lualib.h
ltable.obj: ltable.c lprefix.h lua.h luaconf.h ldebug.h lstate.h lobject.h \
 llimits.h ltm.h lzio.h lmem.h ldo.h lgc.h lstring.h ltable.h lvm.h
ltablib.obj: ltablib.c lprefix.h lua.h luaconf.h lauxlib.h lualib.h
ltm.obj: ltm.c lprefix.h lua.h luaconf.h ldebug.h lstate.h lobject.h \
 llimits.h ltm.h lzio.h lmem.h ldo.h lgc.h lstring.h ltable.h lvm.h
lua.obj: lua.c lprefix.h lua.h luaconf.h lauxlib.h lualib.h
luac.obj: luac.c lprefix.h lua.h luaconf.h lauxlib.h lobject.h llimits.h \
 lstate.h ltm.h lzio.h lmem.h lundump.h ldebug.h lopcodes.h
lundump.obj: lundump.c lprefix.h lua.h luaconf.h ldebug.h lstate.h \
 lobject.h llimits.h ltm.h lzio.h lmem.h ldo.h lfunc.h lstring.h lgc.h \
 lundump.h
lutf8lib.obj: lutf8lib.c lprefix.h lua.h luaconf.h lauxlib.h lualib.h
lvm.obj: lvm.c lprefix.h lua.h luaconf.h ldebug.h lstate.h lobject.h \
 llimits.h ltm.h lzio.h lmem.h ldo.h lfunc.h lgc.h lopcodes.h lstring.h \
 ltable.h lvm.h ljumptab.h
lzio.obj: lzio.c lprefix.h lua.h luaconf.h llimits.h lmem.h lstate.h \
 lobject.h ltm.h lzio.h

# (end of Makefile)
