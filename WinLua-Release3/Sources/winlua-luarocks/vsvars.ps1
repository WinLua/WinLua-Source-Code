function Set-DevEnvironment() {
    param ( [string]$version = $(throw "Need a VS version"))

	$vsPath = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\$version\*\Common7\Tools\VsDevCmd.bat"
	$ok = ls $vsPath
	if($ok){    
		. Import-Environment $ok
	} else {
		echo "Failed to find $vsPath"
    }
}

# This method will execute a batch file and then put the resulting 
# environment into the current context 
function Import-Environment() {
    param ( $file = $(throw "Need a CMD/BAT file to execute"),
            $args = "") 

    $tempFile = [IO.Path]::GetTempFileName()

    # Store the output of cmd.exe.  We also ask cmd.exe to output
    # the environment table after the batch file completes

    cmd /c " `"$file`" $args && set > `"$tempFile`" "

    ## Go through the environment variables in the temp file.
    ## For each of them, set the variable in our local environment.
    remove-item -path env:*
    Get-Content $tempFile | Foreach-Object {
        if($_ -match "^(.*?)=(.*)$") {
            $n = $matches[1]
            if ($n -eq "prompt") {
                # Ignore: Setting the prompt environment variable has no
                #         connection to the PowerShell prompt
            } elseif ($n -eq "title") {
                $host.ui.rawui.windowtitle = $matches[2];
                #~ echo $matches[2]
                set-item -path "env:$n" -value $matches[2];
            } else {
				#~ echo $matches[2]
                set-item -path "env:$n" -value $matches[2];
            }
        }
    }
    Remove-Item $tempFile
}

Set-DevEnvironment $args[1]
