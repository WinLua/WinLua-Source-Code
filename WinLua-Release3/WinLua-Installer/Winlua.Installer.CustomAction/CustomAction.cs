using System;
using System.Collections.Generic;
using System.Text;
using System.IO;
using Microsoft.Deployment.WindowsInstaller;
using System.Diagnostics;
using Neo.IronLua;

namespace Winlua.Installer.CustomAction
{
    public class CustomActions
    {
        public const string LUAROCKS_SYSCONFDIR = "LUAROCKS_SYSCONFDIR";
        public const string COMPILER_NAME_32 = "wlc32.exe";
        public const string COMPILER_NAME_64 = "wlc64.exe";

        [CustomAction]
        public static ActionResult ConfigureLuaRocks(Session session)
        {
            session.Log("***WinLua: Begin CustomAction1");

            Lua L = new Lua();
            var g = L.CreateEnvironment();
            dynamic d = g;

            d.luaRootPath = session.CustomActionData["LuaRootPath"];
            d.luaVersion = session.CustomActionData["LuaVersion"];
            session.Log(string.Format("WinLua: Lua version {0} is installed at {1} ", d.luaVersion, d.luaRootPath));

            if (!string.IsNullOrEmpty(session.CustomActionData["LuaRocksRootPath"]))
            {
                d.luaRocksRootPath = session.CustomActionData["LuaRocksRootPath"];
                session.Log("WinLua: LuaRocks installed in " + d.luaRocksRootPath);
            }
            else
            {
                session.Log("WinLua: LuaRocks not installed.");
            }
                            
            if (!string.IsNullOrEmpty(session.CustomActionData["ToolsPath"]))
            {
                session.Log("WinLua: WinLua Compiler Tools (WLC) have been installed.");
                d.toolsPath = session.CustomActionData["ToolsPath"];
                WriteConfigFile(session, g);
                session.Log("WinLua: Wrote config file for use with WLC");
            }
            else
            {
                session.Log("WinLua: WinLua Compiler Tools (WLC) were not installed");
                RunConfigScript(session, d.luaRootPath, d.luaRocksRootPath);
            }
            return ActionResult.Success;
        }
         
        /// <summary>
        /// If the user installs llvm-mingw, we write the config file ourselves.
        /// </summary>
        private static bool WriteConfigFile(Session session, LuaGlobal g)
        {
            ///TODO: extend this function to encapsulate the existing Luarocks 
            ///configuration script so we can work with any compiler.

            bool result = false;
            ///This is a first crack at creating the config file, 
            ///it's also a test of what I can do with NeoLua so 
            ///bear with me...
            session.Log("WinLua: Create Config File for LuaRocks with WLC.");
            dynamic d = g;
            //This is creating tables and table values in C# using dynamic
            d.rocks_trees = new LuaTable();
            d.rocks_trees[1] = new LuaTable();
            d.rocks_trees[1].name = "user";
            d.rocks_trees[1].root = "home..[[/luarocks]]";
            d.rocks_trees[2] = new LuaTable();
            d.rocks_trees[2].name = "system";
            g.DoChunk(@"luaRootPath = luaRootPath:gsub('\\','/').. luaVersion .. '/'", "c1");            
            d.rocks_trees[2].root = d.luaRootPath;

            //This is creating tables and values in Lua
            ///- Create the variables table and add LUA_LIBDIR and LUA_INCDIR.
            ///- Format the lua version and create the path for the new config file
            ///- Create the lua lib filename
            ///- Create the LuRocks config file path and name
            session.Log("WinLua: Running custom Lua chunk...");
            g.DoChunk(@"
            variables = {}
            lua_version_formatted = luaVersion:gsub('%.','')                        
            variables.LUA_LIBDIR = luaRootPath..'bin/'
            variables.LUA_INCDIR = luaRootPath..'include/'            
            variables.LUALIB = string.format('lua%s.lib', lua_version_formatted)
            luaRocksConfigPath = string.format('%sconfig-%s.lua', luaRocksRootPath, luaVersion)
            ", "c1");

            if (d.toolsPath != null)
            {
                session.Log("WinLua: Found tools path.");
                ///- Names where the mingw library sit
                d.x86_lib = "i686-w64-mingw32";
                d.x64_lib = "x86_64-w64-mingw32";
                //TODO: Hard coded Processor names
                d.variables.CC = "wlc32.exe";
                d.variables.LD = "wlc32.exe";

                d.external_deps_dirs = new LuaTable();
                
                //TODO: Remove hard code tools lib path (needs to be arch independant)
                d.external_deps_dirs[1] = d.toolsPath + d.x86_lib + "/";
                g.DoChunk(@"external_deps_dirs[1] = external_deps_dirs[1]:gsub('\\','/')", "c1");
                //I got lazy at the end...
                g.DoChunk(@"
                    external_deps_patterns = {
                        bin = { '?.exe', '?.bat' },
                        lib = { 'lib?.a', 'lib?.dll.a', '?.dll.a', '?.lib', 'lib?.lib'},
                        include = { '?.h' }
                    }", "c1");
            }
            else
            {
                session.Log("WinLua: Tools path not found.");
            }

            //Prepend the table names for formatting in the config file.
            string trees = "rocks_trees = " + LuaTable.ToLson(d.rocks_trees);
            string variables = "variables = " + LuaTable.ToLson(d.variables);
            string ex_deps_dirs = "";
            string ex_deps_patterns = "";
            string verbose = "verbose = false-- set to 'true' to enable verbose output";

            if (d.toolsPath != null)
            {
                session.Log("WinLua: Format external_* tables");
                ex_deps_dirs = "external_deps_dirs = " + LuaTable.ToLson(d.external_deps_dirs);
                ex_deps_patterns = "external_deps_patterns = " + LuaTable.ToLson(d.external_deps_patterns);
                
            }
                        
            //Write to file, append each table to the file (newline seperated). 
            //Note, the d.luaRocksConfigPath variable is created in a Lua chunk above.
            File.WriteAllText(d.luaRocksConfigPath, string.Format("{0}\r\n{1}\r\n{2}\r\n{3}\r\n{4}\r\n",
                trees, variables, ex_deps_dirs, ex_deps_patterns, verbose));

            session.Log(string.Format("WinLua: Created config file at {0}.", d.luaRocksRootPath));
            //TODO: Do this properly in the installer, not in the custom action. It's too opaque.
            //Set the LUAROCKS_SYSCONFDIR variable.
            Environment.SetEnvironmentVariable(LUAROCKS_SYSCONFDIR, d.luaRocksRootPath, EnvironmentVariableTarget.Machine);
            session.Log("WinLua: Set LUAROCKS_SYSCONFDIR. LuaRocks configuration complete.");
            return result;

        }

        [CustomAction]
        public static ActionResult RemoveWinLuaDir(Session session)
        {
            string path = session.CustomActionData["WinLuaPath"];
            session.Log("WinLua: Checking for folder remaining at {0}", path);
            if (Directory.Exists(path))
            {
                session.Log("WinLua: Removing everything leftover.");
                Directory.Delete(path, true);
            }
            Environment.SetEnvironmentVariable(LUAROCKS_SYSCONFDIR, null, EnvironmentVariableTarget.Machine);
            session.Log("***WinLua: Removed");
            return ActionResult.Success;
        }

        private static bool RunConfigScript(Session session, string LuaPath, string LuaRocksPath)
        {
            ///2020-02-01: RH - There is a bug in NeoLua 1.3.11 that incorrectly parses a table variable in 
            ///the create-config.lua script (the table element is called 'const' and NeoLua handles the 5.4 syntax).
            ///Therefore we still need to call our external lua for the time being.

            try
            {
                ProcessStartInfo startInfo = new ProcessStartInfo();
                ///How do we get the lua and luarocks installation paths? If I have that I can call
                ///the config file directly and pass the parameters myself!
                startInfo.FileName = LuaPath + "5.3\\bin\\lua.exe";
                startInfo.WorkingDirectory = LuaRocksPath + "share";
                session.Log("Running Lua at " + startInfo.FileName);
                session.Log("Working Directory" + startInfo.WorkingDirectory);
                startInfo.Arguments = string.Format("create-config.lua /LUA \"{0}\" /P \"{1}\" /CONFIG \"{2}\"",
                    LuaPath + "5.3", LuaRocksPath + "\\bin", LuaRocksPath);
                startInfo.Verb = "runas";
                session.Log("Arguments ARE: " + startInfo.Arguments);
                Process.Start(startInfo);
                session.Log("Process started, cross yer fingers");
                return true;
            }
            catch(Exception ex)
            {
                session.Log(ex.Message);
                return false;
            }
            
        }
        [CustomAction]
        public static ActionResult RemoveLuaRocksConfig(Session session)
        {            
            session.Log("***WinLua: Begin Removing Config File");

            string luaRootPath = session.CustomActionData["LuaRootPath"];
            string luaVersion = session.CustomActionData["LuaVersion"];
            session.Log(string.Format("WinLua: Lua version {0} is installed at {1} ", luaVersion, luaRootPath));
            string luaRocksRootPath = "";
            string toolsPath = "";
            string luaRocksConfigFile = "";
            //TODO: Test for user option to leave Config file in place
            if (!string.IsNullOrEmpty(session.CustomActionData["LuaRocksRootPath"]))
            {
                luaRocksRootPath = session.CustomActionData["LuaRocksRootPath"];
                session.Log("WinLua: LuaRocks installed in " + luaRocksRootPath);
                luaRocksConfigFile = string.Format("{0}config-{1}.lua", luaRocksRootPath, luaVersion.Replace(".", ""));
            }
            else
            {
                session.Log("WinLua: LuaRocks not installed.");
            }

            if (!string.IsNullOrEmpty(session.CustomActionData["ToolsPath"]))
            {
                session.Log("WinLua: WinLua Compiler Tools (WLC) have been installed.");
                toolsPath = session.CustomActionData["ToolsPath"];
                session.Log("WinLua: Wrote config file for use with WLC");
            }
            else
            {
                session.Log("WinLua: WinLua Compiler Tools (WLC) were not installed");
            }

            //build luarocks config file name/path

            if (File.Exists(luaRocksConfigFile))
            {
                session.Log("WinLua: Deleting LuaRocks Config file.");
                File.Delete(luaRocksConfigFile);
            }
            else
            {
                session.Log("WinLua: Could not find {0}.", luaRocksConfigFile);
            }
            Environment.SetEnvironmentVariable(LUAROCKS_SYSCONFDIR, null, EnvironmentVariableTarget.Machine);
            session.Log("***WinLua: Config File Removed");

            RemoveRockTree(session);
            return ActionResult.Success;
        }

        [CustomAction]
        public static ActionResult RemoveRockTree(Session session)
        {
            session.Log("***WinLua: Begin Removing RockTree");
            string luaRootPath = session.CustomActionData["LuaRootPath"];
            string luaVersion = session.CustomActionData["LuaVersion"];
            session.Log(string.Format("WinLua: Lua version {0} is installed at {1} ", luaVersion, luaRootPath));
            string luaRocksRootPath = "";
            string toolsPath = "";
            string rockTree = "";
            //TODO: Test for user option to leave Config file in place
            if (!string.IsNullOrEmpty(session.CustomActionData["LuaRocksRootPath"]))
            {
                luaRocksRootPath = session.CustomActionData["LuaRocksRootPath"];
                session.Log("WinLua: LuaRocks installed in " + luaRocksRootPath);
                rockTree = string.Format("{0}\\{1}/lib", luaRootPath, luaVersion);
            }
            else
            {
                session.Log("WinLua: LuaRocks not installed.");
            }

            if (!string.IsNullOrEmpty(session.CustomActionData["ToolsPath"]))
            {
                session.Log("WinLua: WinLua Compiler Tools (WLC) are present.");
                toolsPath = session.CustomActionData["ToolsPath"];
                session.Log("WinLua: Set Toolspath for removal");
            }
            else
            {
                session.Log("WinLua: WinLua Compiler Tools (WLC) were not installed");
            }

            //build luarocks config file name/path
            session.Log("WinLua: Checking for rocktree at {0}", rockTree);
            if (Directory.Exists(rockTree))
            {
                session.Log("WinLua: Removing Rocktree.");
                Directory.Delete(rockTree, true);
            }
            session.Log("***WinLua: Rocktree Removed");
            return ActionResult.Success;
        }
    }
}
