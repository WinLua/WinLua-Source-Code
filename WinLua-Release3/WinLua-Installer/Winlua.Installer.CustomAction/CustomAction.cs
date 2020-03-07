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
                
                session.Log("WinLua: Found LuaRocks");

                d.luaRocksRootPath = session.CustomActionData["LuaRocksRootPath"];
                session.Log("WinLua: LuaRocks installed in " + d.luaRocksRootPath);

                d.luaRootPath = session.CustomActionData["LuaRootPath"];
                session.Log("WinLua: lua_exe installed in " + d.luaRootPath);
                
                if (!string.IsNullOrEmpty(session.CustomActionData["ToolsPath"]))
                {
                    session.Log("WinLua: Installed LLVM (aparently)");
                    d.toolsPath = session.CustomActionData["ToolsPath"];
                    WriteConfigFile(session, g);
                    session.Log("WinLua: wrote config file for llvm");
                }
                else
                {
                    session.Log("WinLua: didn't find llvm use luarocks");
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
            session.Log("WinLua: Begin Write");
            dynamic d = g;
            d.rocks_trees = new LuaTable();
            d.rocks_trees[1] = new LuaTable();
            d.rocks_trees[1].name = "user";
            d.rocks_trees[1].root = "home..[[/luarocks]]";
            d.rocks_trees[2] = new LuaTable();
            d.rocks_trees[2].name = "system";
            g.DoChunk(@"luaRootPath = luaRootPath:gsub('\\','/')", "c1");
            //TODO: Hard coded 5.3
            d.luaRootPath += "5.3/";
            d.rocks_trees[2].root = d.luaRootPath;

            d.variables = new LuaTable();
            
            d.variables.LUA_LIBDIR = d.luaRootPath + "bin";
            d.variables.LUA_INCDIR = d.luaRootPath + "include";
            
            //TODO: Remove hard code lib filename
            d.variables.LUALIB = "lua53.lib";
            g.DoChunk(@"
                for i,v in pairs(variables) do
                    if type(v) == 'string' then
                        variables[i] = v:gsub('\\','/')
                    end
                end", "c1");

            if (d.toolsPath != null)
            {
                d.x86_lib = "i686-w64-mingw32";
                d.x64_lib = "x86_64-w64-mingw32";
                session.Log("WinLua: Found Tools path");
                //TODO: Hard coded Processor names
                d.variables.CC = "wlc32.exe";
                d.variables.LD = "wlc32.exe";

                d.external_deps_dirs = new LuaTable();
                
                //TODO: Remove hard code tools lib path (needs to be arch independant)
                d.external_deps_dirs[1] = d.toolsPath + "\\" +  d.x86_lib;
                g.DoChunk(@"external_deps_dirs[1] = external_deps_dirs[1]:gsub('\\','/')", "c1");
                //I got lazy at the end...
                g.DoChunk(@"
                    external_deps_patterns = {
                        bin = { '?.exe', '?.bat' },
                        lib = { 'lib?.a', 'lib?.dll.a', '?.dll.a', '?.lib', 'lib?.lib'},
                        include = { '?.h' }
                    }", "c1");
            }

            //Prepend the table names for formatting in the config file.

            string trees = "rocks_trees = " + LuaTable.ToLson(d.rocks_trees);
            string variables = "variables = " + LuaTable.ToLson(d.variables);
            string ex_deps_dirs = "";
            string ex_deps_patterns = "";

            if (d.toolsPath != null)
            {
                session.Log("WinLua: Format external_*");
                ex_deps_dirs = "external_deps_dirs = " + LuaTable.ToLson(d.external_deps_dirs);
                ex_deps_patterns = "external_deps_patterns = " + LuaTable.ToLson(d.external_deps_patterns);
                
            }
            string verbose = "verbose = false-- set to 'true' to enable verbose output";

            //TODO: Remove the hard coded config file name!
            //Write to file, append each table to the file (newline seperated). 
            File.WriteAllText(d.luaRocksRootPath + "\\config-5.3.lua", string.Format("{0}\r\n{1}\r\n{2}\r\n{3}\r\n{4}\r\n",
                trees, variables, ex_deps_dirs, ex_deps_patterns, verbose));

            session.Log("Done!");
            //TODO: Do this properly in the installer, not in the custom action. It's too opaque.
            //Set the LUAROCKS_SYSCONFDIR variable.
            Environment.SetEnvironmentVariable(LUAROCKS_SYSCONFDIR, d.luaRocksRootPath, EnvironmentVariableTarget.Machine);            
            return result;

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
            var db = session.Database;
            Guid id = Guid.NewGuid();

            Environment.SetEnvironmentVariable(LUAROCKS_SYSCONFDIR, null, EnvironmentVariableTarget.Machine);
            session.Log("***WinLua: Config File Removed");
            return ActionResult.Success;
        }
    }
}
