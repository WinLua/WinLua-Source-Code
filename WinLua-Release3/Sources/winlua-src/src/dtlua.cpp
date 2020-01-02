#define LUA_USE_WINDOWS

#ifdef LUA_USE_WINDOWS
  #include <windows.h>
#endif

#include <sol.hpp>
#include <getopt-lua.hpp>
#include <iostream>

#define SLASH = "\\"

typedef char* psearch_t;
typedef void (*tmainL)(int, char**);

bool debug = false;

static int LoadLua(std::string shared_object, int argc, char **argv)
{
	int result = -1;
	HINSTANCE hLuaLib;
	tmainL pmainL;
	bool fFreeResult, fRunTimeLinkSuccess = false;
	// Get a handle to our DLL module created in the previous example. Make sure you already copied the mydllpro.lib and mydllpro.dll to the appropriate folders...
	hLuaLib = LoadLibrary(shared_object.c_str());

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
		printf("The LoadLibrary failed to load %s. Error: %d.\n", shared_object.c_str(), GetLastError());
	}
		// If unable to call the DLL function, use an alternative.
	if (!fRunTimeLinkSuccess)
	{
			printf("Dynamic linking to Lua failed. The message returned from C...\n");
	}

	result = fRunTimeLinkSuccess && fFreeResult;
	return result;
}

int main(int argc, char* argv[]) {
	sol::state lua;
	// open some common libraries
	lua.open_libraries(sol::lib::base, sol::lib::string);
	lua.script("args={}");
	for(int i = 0; i < argc; i++){
		lua["args"][i] = argv[i];
	}
	//will need to run protected and get an error return value?
	//get_opts is included in getopt-lua.hpp
	lua.script(get_opts);
	int lua_argc = lua["argc"];

	char **lua_argv;
	lua_argv = (char**) malloc( sizeof(char*) * (lua_argc + 1));

	sol::as_table_t<std::vector<std::string>> serialized_argv2 = lua["other"];
	// notice .source on next line
	int i = 0;
	for (std::string& str : serialized_argv2.source) {
		lua_argv[i] = (char*)malloc( sizeof(char*) * str.length());
		memcpy(lua_argv[i], str.c_str(), sizeof(char*) * str.length());
		i++;
	}
	lua_argv[lua_argc] = NULL;
	std::string so_path = lua["opts"]["so_path"];
	if(debug)
	{
		std::cout << "Shared object path: " << so_path << std::endl;
	}
	
	int retval = LoadLua(so_path, lua_argc, lua_argv);
	for(int i = 0; i < lua_argc; i++)
	{
		free(lua_argv[i]);
	}
	free(lua_argv);
	
	return retval;
};
