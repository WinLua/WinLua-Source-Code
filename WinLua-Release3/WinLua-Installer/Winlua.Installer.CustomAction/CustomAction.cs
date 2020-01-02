using System;
using System.Collections.Generic;
using System.Text;
using Microsoft.Deployment.WindowsInstaller;
using System.Diagnostics;

namespace Winlua.Installer.CustomAction
{
    public class CustomActions
    {
        [CustomAction]
        public static ActionResult ConfigureLuaRocks(Session session)
        {
            session.Log("Begin CustomAction1");
            if(session.Features.Contains("LuaRocks"))
            {
                session.Log("Found LuaRocks");
                string luarocks = session.GetTargetPath("LUAROCKS_INSTALLLOCATION");                
                session.Log("LuaRocks installed in " + luarocks);
                string lua_exe = session.GetTargetPath("LUA_INSTALLLOCATION");
                session.Log("lua_exe installed in " + lua_exe);
                
                RunConfigScript(session, lua_exe, luarocks);

            }
            return ActionResult.Success;
        }

        private static bool RunConfigScript(Session session, string LuaPath, string LuaRocksPath)
        {
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
