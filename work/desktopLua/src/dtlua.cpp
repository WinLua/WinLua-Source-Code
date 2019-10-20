#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <iostream>

#include "lua.h"
#include "lualib.h"
#include "lauxlib.h"
//~ #include "lua51.h"

#include "util.h"

#ifdef LUA_USE_WINDOWS
  #include <windows.h>
#endif

#include "sol.hpp"

#define FIVE_ONE "-51"
#define FIVE_TWO "-51"
#define FIVE_THREE "-51"
#define FIVE_FOUR "-51"
#define SIXTY_FOUR_BIT "-x64"

static const char* LUA54 = "5.4\\lua54.dll";
static const char* LUA53 = "5.3\\lua53.dll";
static const char* LUA52 = "5.2\\lua52.dll";
static const char* LUA51 = "5.1\\lua51.dll";

bool debug = false;

typedef char* psearch_t;

typedef void (*tmainL)(int, char**);

typedef struct conf_t {
  psearch_t p_path; //package.path
  psearch_t p_cpath; //package.cpath
  bool p_use_51;
} conf_t;

struct Options {
   int lua_version;
   bool x64;
}options;
 
static int LoadLua(const char* file, int argc, char **argv)
{
  HINSTANCE hLuaLib;
  tmainL pmainL;
  bool fFreeResult, fRunTimeLinkSuccess = false;
  // Get a handle to our DLL module created in the previous example. Make sure you already copied the mydllpro.lib and mydllpro.dll to the appropriate folders...
  hLuaLib = LoadLibrary(file);

  // If the handle is valid, try to get the function address.
  if (hLuaLib != NULL)
  {
    pmainL = (tmainL) GetProcAddress(hLuaLib, "mainL");
   
    // If the function address is valid, call the function.
    if (pmainL != NULL)
    {
      if(debug) printf("The function address is valid: %p\n\n", pmainL);

      fRunTimeLinkSuccess = true;
      // Pass some text, mydll() will display it on the standard output...
      (pmainL) (argc, argv);
    }
    else
    {
      printf("\nThe function address is NOT valid, error: %d.\n", GetLastError());
    }
    // Free up the DLL module.
    fFreeResult = FreeLibrary(hLuaLib);

    //Failed to free the handle
    if (fFreeResult == 0)
    {
      printf("FreeLibrary() is not OK, error: %d.\n", GetLastError());
    }
  }
  else
  {
    printf("The LoadLibrary failed to load %s. Error: %d.\n", file, GetLastError());
  }
  // If unable to call the DLL function, use an alternative.
  if (!fRunTimeLinkSuccess)
  {
    printf("Dynamic linking to Lua failed. The message returned from C...\n");
  }
  return 0;
}

static int finconf(char* path){
  
}

static int rem(int index, int newsize, char **args){
  int i = index;
  for (i; i < newsize; ++i)
    args[i] = args[i + 1];
  return i;
}

static bool find51opt (int argc, char **argv) {
  int newlen = argc;
  int i = 1;
  int done = 0;
  
for(i; i <=argc-1; i++){
    if (argv[i][0] != '-')  /* not an option? */
        return newlen;
    if(strncmp(FIVE_ONE, argv[i], 3)==0)
    {
		printf("%s", "Got here!");
      //options.lua51 = true;//not currently used
      newlen = rem(i, newlen, argv);
	  return newlen;
    }
  }
  return argc;
}

int main (int argc, char **argv) {
  int status = 1;
  int optlen = 0;
  char filename[256];
  int script;
  
  strncpy(filename, LUA54, sizeof(filename));
  std::cout << "=== opening a state ===" << std::endl;
  sol::state lua;
  // open some common libraries
  lua.open_libraries(sol::lib::base, sol::lib::package);
  lua.script("print('bark bark bark!')");

  std::cout << "That's all for our demonstration" << std::endl;
  //find51opt(argc, argv);
  /*if (options.lua51)
  {
	  printf("landed on go.");
	  strncpy(filename, LUA51, sizeof(filename));
  }

  LoadLua(filename, argc, argv);
  */
  return (status) ? EXIT_FAILURE : EXIT_SUCCESS;
}
