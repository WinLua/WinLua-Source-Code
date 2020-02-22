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
        /// This function manually creates the LuaRocks config file
        /// </summary>
        private static bool WriteConfigFile(Session session, LuaGlobal g)
        {
            bool result = false;
            ///Maybe we should re-write this as a script
            ///so it can be inbedded into a separate tool as well?
            session.Log("WinLua: Begin Write");
            dynamic d = g;
            d.rocks_trees = new LuaTable();
            d.rocks_trees[1] = new LuaTable();
            d.rocks_trees[1].name = "user";
            d.rocks_trees[1].root = "home..[[/luarocks]]";
            d.rocks_trees[2] = new LuaTable();
            d.rocks_trees[2].name = "system";
            d.rocks_trees[2].root = d.luaRootPath;

            d.variables = new LuaTable();
            
            d.variables.LUA_LIBDIR = d.luaRootPath + "/bin";
            d.variables.LUA_INCDIR = d.luaRootPath + "/include";
            d.variables.LUALIB = "lua53.lib";

            if(d.toolsPath != null)
            {
                session.Log("WinLua: Found Tools path");
                d.variables.CC = "i686-w64-mingw32-clang.exe";
                d.variables.LD = "i686-w64-mingw32-clang.exe";

                d.external_deps_dirs = new LuaTable();
                d.external_deps_dirs[1] = d.toolsPath;

                //I got lazy at the end...
                g.DoChunk(@"external_deps_patterns = {
                bin = { '?.exe', '?.bat' },
                lib = { 'lib?.a', 'lib?.dll.a', '?.dll.a', '?.lib', 'lib?.lib'},
                include = { '?.h' }
                }"
                    , "c1");
            }

            ///2020-02-01: RH - NeoLua LuaTable.ToLson doesn't 
            ///output the name of the table so I need to tack it on the front. Because the LuaRocks
            ///config file contains a loose set of tables I have to:
            ///1) prepend the table names and
            ///2) format the individual tables in the file. 
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
            //Ugly format string just appends each table on a new line.
            File.WriteAllText(d.luaRocksRootPath + "/config-5.3.lua", string.Format("{0}\r\n{1}\r\n{2}\r\n{3}\r\n{4}\r\n",
                trees, variables, ex_deps_dirs, ex_deps_patterns, verbose));

            session.Log("Done!");
            //TODO: SETX to set the LUAROCKS_SYSCONFDIR variable.
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
    }
}
