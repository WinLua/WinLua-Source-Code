This Wix installer project uses a hand altered project file. In order to make the project 
portable across versions of Lua, the references to other projects have been altered from 
the values that Visual Studio inserts. 

If you modify or remove the references to the installer, you will need to open the WinLua 
Installer.wixproj in a text editor and alter the Include attribute of the ProjectReferences 
tag to use the $(SolutionDir) macro instead of the relative value taht is created by Visual Studio.

<ProjectReference Include="..\5.1\LuaFileSystem\LuaFileSystem.vcxproj">

becomes

<ProjectReference Include="$(SolutionDir)\LuaFileSystem\LuaFileSystem.vcxproj">