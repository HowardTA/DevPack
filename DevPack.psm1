#########################################################################################
#
# DevPack - Visual Studio / Git Developer Tool Pack
#
#########################################################################################
#
# Version		Rev	Authored By			Description of Work
# -------------	---	-------------------	--------------------------------------------------------------------
# 1.15.1529		0	Todd Howard			Created
#
[string]$Version = "1.15.1529.0"  ### <Major Release Number>.<Number of Features>.<Build Week>.<Revision>
[string[]]$Features = @(
	"AutoSync",    "DevPack",       "Clipboard",  "Cron",    "Git",   "History",  "IE",
	"InFiles",     "Milliseconds",  "P4Merge",    "Prompt",  "Repo",  "Shelf",
	"Tail",        "Time",          "WebResponse"
)
#########################################################################################

#region Git Integration

#########################################################################################
# Show-Git
#########################################################################################
# .ExternalHelp DevPack.Help.xml
function Show-Git
{
    [CmdletBinding()]
    param
	(
		[switch]$ShowStatus = $true,
		[switch]$LastCommit = $false
	)

	if ($ShowStatus)
	{
		Write-Verbose ("{0}:Show-Git:: Running 'git status'..." -f $ExecutionContext.SessionState.Module)
		git status
	}

	if ($LastCommit)
	{
		Write-Verbose ("{0}:Show-Git:: Running 'git log -1'..." -f $ExecutionContext.SessionState.Module)
		git log -1
	}
}


#########################################################################################
# Add-Git
#########################################################################################
# .ExternalHelp DevPack.Help.xml
function Add-Git
{
    [CmdletBinding()]
    param
    (
		[string]$FilePath = ".",
		[switch]$FromClipboard
	)

	if (-not $FromClipboard)
	{
		Write-Verbose ("{0}:Add-Git:: Running 'git add {1} -A'..." -f $ExecutionContext.SessionState.Module, $FilePath)
		git add $FilePath -A
	}
	else
	{
		Get-Clipboard -ToArray | % {
			Write-Verbose ("{0}:Add-Git:: Running 'git add {1} -A'..." -f $ExecutionContext.SessionState.Module, $_)
			git add $_ -A
		}
	}
	git status
}


#########################################################################################
# Remove-Git
#########################################################################################
# .ExternalHelp DevPack.Help.xml
function Remove-Git
{
    [CmdletBinding()]
    param
    (
		[string]$FilePath = ".",
		[switch]$FromClipboard
	)

	if (-not $FromClipboard)
	{
		Write-Verbose ("{0}:Remove-Git:: Running 'git rm {1}'..." -f $ExecutionContext.SessionState.Module, $FilePath)
		git rm "$($FilePath)"
	}
	else
	{
		Get-Clipboard -ToArray | % {
			Write-Verbose ("{0}:Remove-Git:: Running 'git rm {1}'..." -f $ExecutionContext.SessionState.Module, $_)
			git rm "$($_)"
		}
	}
	git status
}


#########################################################################################
# Submit-Git
#########################################################################################
# .ExternalHelp DevPack.Help.xml
function Submit-Git
{
	[CmdletBinding()]
    param
    (
	)

	Write-Verbose ("{0}:Submit-Git:: Running 'git log -1'..." -f $ExecutionContext.SessionState.Module)
	git log -1

	Write-Verbose ("{0}:Submit-Git:: Running 'git commit'..." -f $ExecutionContext.SessionState.Module)
	git commit
}


#########################################################################################
# Request-Git
#########################################################################################
# .ExternalHelp DevPack.Help.xml
function Request-Git
{
    [CmdletBinding()]
    param
    (
	)

	Write-Verbose ("{0}:Request-Git:: Running 'git pull --rebase'..." -f $ExecutionContext.SessionState.Module)
	git pull --rebase
}


#########################################################################################
# Push-Git
#########################################################################################
# .ExternalHelp DevPack.Help.xml
function Push-Git
{
    [CmdletBinding()]
    param
	(
		[switch]$Confirm
	)

	$oStagedFiles = git diff --stat --cached "origin/$($DevPackConfig.RepoName)"
	if ($oStagedFiles -ne $null)
	{
		if ($Confirm)
		{
			$oStagedFiles
			Write-Host
			if (-not (Get-Response -Prompt ("{0}:Push-Git:: Ready to push the above files. Continue?(y/n):" -f $ExecutionContext.SessionState.Module) -Default "y"))
			{
				break
			}
		}

		Write-Verbose ("{0}:Push-Git:: Running 'git push'..." -f $ExecutionContext.SessionState.Module)
		git push
	}
	else
	{
		Write-Host ("{0}:Push-Git:: Nothing to push." -f $ExecutionContext.SessionState.Module) -ForegroundColor Green
	}


}


#########################################################################################
# Compare-Git
#########################################################################################
# .ExternalHelp DevPack.Help.xml
function Compare-Git { git diff }


#########################################################################################
# Undo-Git
#########################################################################################
# .ExternalHelp DevPack.Help.xml
function Undo-Git
{
    [CmdletBinding()]
    param
    (
		[string]$FilePath = ".",
		[switch]$FromClipboard
	)

	if (-not $FromClipboard)
	{
		if ($FilePath.Length -eq 0)
		{
			Write-Warning ("{0}:Undo-Git: Missing -FilePath or -FromClipboard parameter.  No action taken." -f $ExecutionContext.SessionState.Module)
			Break
		}

		Write-Verbose ("{0}:Undo-Git:: Running 'git checkout {1}'..." -f $ExecutionContext.SessionState.Module, $FilePath)
		git checkout $FilePath
	}
	else
	{
		Get-Clipboard -ToArray | % {
			Write-Verbose ("{0}:Undo-Git:: Running 'git checkout {1}'..." -f $ExecutionContext.SessionState.Module, $_)
			git checkout $_
		}
	}
	git status
}


#########################################################################################
# Merge-Git
#########################################################################################
# .ExternalHelp DevPack.Help.xml
function Merge-Git   { git mergetool }


#########################################################################################
# Resolve-Git
#########################################################################################
# .ExternalHelp DevPack.Help.xml
function Resolve-Git { git rebase --continue }


#########################################################################################
# Open-P4Merge - Open 3-way merge utility P4Merge with 'git mergetool' files
#########################################################################################
# .ExternalHelp DevPack.Help.xml
function Open-P4Merge
{
    [CmdletBinding()]
    param
    (
        [switch]$Setup,

        [string]$Base,
        [string]$Local,
        [string]$Remote,
        [string]$Merge,

        [string]$Root = $DevPackConfig.RepoRoot
    )

    function FixPath([string]$Path)
    {
		if ($Path[1] -eq ':' -or $Path.Length -eq 0) { return $Path }
        return "$($Root)\$(($Path -Replace '/', '\').TrimStart('.\'))"
    }

    if (!(Test-Path $Root))
    {
        Write-Warning ("{0}:Open-P4Merge:: The root folder is not set properly in Open-P4Merge.  Update the default in your .ps1 file." -f $ExecutionContext.SessionState.Module)
        Write-Host "Press Enter to continue: " -NoNewLine
        $dummy = Read-Host
        Break
    }

    if ($Setup)
    {
        Write-Host "1. Press Start, type 'powershell' " -ForegroundColor Green
        Write-Host "2. Right-click on 'Windows Powershell (x86)' and choose 'Run as Administrator'" -ForegroundColor Green
        Write-Host "3. At the PS> prompt, enter the command: " -NoNewLine -ForegroundColor Green
        Write-Host "Set-ExecutionPolicy -ExecutionPolicy Bypass"
        Write-Host "4. Open a GitBash window." -ForegroundColor Green
        Write-Host "5. Paste the following 4 lines into the GitBash window:" -ForegroundColor Green -NoNewline
		Write-Host "(already copied into your clipboard)" -ForegroundColor Red
        $sCommands = @"
git config --global merge.tool p4merge
git config --global mergetool.p4merge.cmd 'start powershell -command "Open-P4Merge \"`$BASE\" \"`$LOCAL\" \"`$REMOTE\" \"`$MERGED\""'
git config --global diff.tool p4merge
git config --global difftool.p4merge.cmd 'start powershell -command "Open-P4Merge \"`$BASE\" \"`$LOCAL\" \"`$REMOTE\" \"`$MERGED\""'
"@
		$sCommands
		$sCommands | clip
        Write-Host "6. Thats it.  Now typing 'mergetool' will invoke P4Merge with all the files hooked up properly." -ForegroundColor Green
    }
    else
    {
        [string]$sCmd = "cmd /c P4MERGE.EXE ""$(FixPath $Base)"" ""$(FixPath $Local)"" ""$(FixPath $Remote)"" ""$(FixPath $Merge)"""

        Write-Host
        Write-Host ("{0}:Open-P4Merge:: Executing Command: {1}" -f $ExecutionContext.SessionState.Module, $sCmd) -ForegroundColor Green
        Write-Host

        Invoke-Expression $sCmd
    }
}


#########################################################################################
# Push-Shelf
#########################################################################################
# .ExternalHelp DevPack.Help.xml
function Push-Shelf
{
    [CmdletBinding()]
    param
    (
		[string]$FilePath = ".",
		[switch]$FromClipboard
	)

	if ($FromClipboard)
	{
		$oFiles = Get-Clipboard -ToArray
	}
	else
	{
		$oFiles = git status | % { if (([char]($_[0])).Equals(([char]9)) -and $_ -notmatch "deleted:") { $_.Replace("modified:","").Replace("new file:","").Trim() } }
	}

	if ($oFiles.Count -eq 0)
	{
		Write-Warning ("{0}:Push-Shelf:: No files to shelve." -f $ExecutionContext.SessionState.Module)
		break
	}

	Write-Host ("{0}:Push-Shelf:: Below files will be shelved:" -f $ExecutionContext.SessionState.Module) -ForegroundColor Green
	Write-Host
	$oFiles | % { "        $($_)" }
	Write-Host

	if (-not $ShelfName) { $ShelfName = $(Write-Host ("{0}:Push-Shelf:: Enter shelf name: " -f $ExecutionContext.SessionState.Module) -NoNewline -ForegroundColor Green; Read-Host) }
	if (-not $ShelfName) { Write-Host ("{0}:Push-Shelf:: No action taken." -f $ExecutionContext.SessionState.Module) -ForegroundColor Yellow; break }

	[string]$sShelfDir = "~\shelf\$($ShelfName)"

	[void](mkdir $sShelfDir -ErrorAction SilentlyContinue)

	Write-Host "Push-Shelf:: Copying files to shelf..." -ForegroundColor Yellow
	$oFiles | % {
		$_ | Out-File -Append "$($sShelfDir)\FileList.txt"
		Copy-Item -Path "$($DevPackConfig.RepoRoot)\$($_)" -Destination "$($sShelfDir)" -Verbose
	}

	$oFiles | % {
		Write-Host ("{0}:Push-Shelf:: Reverting {1}..." -f $ExecutionContext.SessionState.Module, $_) -ForegroundColor Yellow

		try
		{
			Write-Verbose ("{0}:Push-Shelf:: Running 'git checkout {1}'..." -f $ExecutionContext.SessionState.Module, $_)
			git checkout $_
		}
		catch
		{
			Write-Host ("{0}:Push-Shelf:: {1} was not in the repository to restore." -f $ExecutionContext.SessionState.Module, $_) -ForegroundColor Yellow
		}
	}

	explorer $sShelfDir.Replace("~", $ENV:Home)
}


#########################################################################################
# Open-Shelf
#########################################################################################
# .ExternalHelp DevPack.Help.xml
function Open-Shelf([string]$ShelfName)
{
	if (-not $ShelfName) { $ShelfName = $(Write-Host ("{0}:Open-Shelf:: Enter shelf name (Leave blank to open root folder): " -f $ExecutionContext.SessionState.Module) -NoNewline -ForegroundColor Green; Read-Host) }
	explorer "$($ENV:Home)\shelf\$($ShelfName)"
}


#########################################################################################
# Pop-Shelf
#########################################################################################
# .ExternalHelp DevPack.Help.xml
function Pop-Shelf
{
    [CmdletBinding()]
	param
	(
		[Parameter(Mandatory=$true, ValueFromPipeline=$false)]
		[string]$ShelfName = $(Write-Host ("{0}:Pop-Shelf:: Enter shelf name: " -f $ExecutionContext.SessionState.Module) -NoNewline -ForegroundColor Green; Read-Host)
	)

	if (-not $ShelfName) { Write-Host ("{0}:Pop-Shelf:: No action taken."-f $ExecutionContext.SessionState.Module) -ForegroundColor Yellow; break }

	[string]$sShelfDir = "~\shelf\$($ShelfName)"

	Get-Content "$($sShelfDir)\FileList.txt" | % {
		Copy-Item -Path "$($sShelfDir)\$([IO.Path]::GetFileName($_))" -Destination "$($DevPackConfig.RepoRoot)\$($_)" -Verbose
	}
}

#endregion

#region Visual Studio Helper (AutoSync)

#########################################################################################
# Start-AutoSync - Automatically push static content to local IIS instance
#########################################################################################
# .ExternalHelp DevPack.Help.xml
function Start-AutoSync
{
    [CmdletBinding()]
    param
    (
        $Folder = $DevPackConfig.RepoRoot,
        $Filter = "*.*"
    )

    $global:_AutoSyncTimeStamp = (Get-Date)
    $global:_AutoSyncFolder = $Folder

    ### Ensure only one AutoSync is running
    Stop-AutoSync -Quiet

    ### Create new log file
    Write-Output ("{0}:Start-AutoSync:: Started @ {1}" -f $ExecutionContext.SessionState.Module, (Get-Date)) | Out-File $DevPackConfig.AutoSyncLog

    ### Prepare file watcher object
    $oFSWatcher = New-Object IO.FileSystemWatcher $Folder, $Filter -Property @{ IncludeSubdirectories = $true; NotifyFilter = [IO.NotifyFilters]::FileName, [IO.NotifyFilters]::LastWrite, [IO.NotifyFilters]::LastAccess, [IO.NotifyFilters]::Security}

    ### Start background file watcher named "FileChanged"
	Write-Host ("{0}:Start-AutoWatch:: Launching background file watcher..." -f $ExecutionContext.SessionState.Module) -ForegroundColor Green
    Register-ObjectEvent -InputObject $oFSWatcher -EventName Renamed -SourceIdentifier FileChanged -Action `
    {
        $sName = $Event.SourceEventArgs.Name
        $oChangeType = $Event.SourceEventArgs.ChangeType
        $oTimeStamp = $Event.TimeGenerated

        ### Gaurd against the OS doing multiple triggers, since the 'Sync' Time Elapsed is usually sub-second
        if (($oTimeStamp - $global:_AutoSyncTimeStamp).TotalSeconds -gt 2)
        {
            ### Only act on file changes (doing a compile causes folder changes)
            if (Test-Path $sName -PathType Leaf)
            {
                ### Ensure it is a file we care about
                [string]$sExt = [IO.Path]::GetExtension($sName)
                if (!($sExt -match "(^.cs$)|(^.suo$)|(^.csproj$)|(^.user$)|(^.cache$)|(^.psm1$)|(^.ps1$)"))
                {
                    ### Display action header in log
                    Write-Output ("=" * 80) | Out-File -Append $DevPackConfig.AutoSyncLog
                    Write-Output ("{0}:Start-AutoSync:FileChanged:: The file '{1}' was {2} at {3}" -f $ExecutionContext.SessionState.Module, $sName, $oChangeType, $oTimeStamp) | Out-File -Append $DevPackConfig.AutoSyncLog

                    ### Perform Sync (and log results)
                    Set-Location $global:_AutoSyncFolder
                    .\v41site-staticcopy-formspublic.ps1 | Out-File -Append $DevPackConfig.AutoSyncLog
                }
            }
        }

        $global:_AutoSyncTimeStamp = $oTimeStamp
    }
}


#########################################################################################
# Stop-AutoSync - Removes background Start-AutoSync job
#########################################################################################
# .ExternalHelp DevPack.Help.xml
function Stop-AutoSync
{
    [CmdletBinding()]
    param
	(
		[switch]$Quiet
	)

	if (!$Quiet) { Write-Host ("{0}:Stop-AutoWatch:: Halting background file watcher..." -f $ExecutionContext.SessionState.Module) -ForegroundColor Green }
    Unregister-Event FileChanged -ErrorAction SilentlyContinue
    Remove-Job FileChanged -ErrorAction SilentlyContinue
}


#########################################################################################
# Watch-AutoSync - Opens auto sync's log in its own window
#########################################################################################
# .ExternalHelp DevPack.Help.xml
function Watch-AutoSync
{
    [CmdletBinding()]
    param ()

    if (Test-Path $DevPackConfig.AutoSyncLog)
    {
        Write-Verbose ("{0}:Watch-AutoSync:: Opening log file..." -f $ExecutionContext.SessionState.Module)
        Watch-Tail -Popup -FileSpec $DevPackConfig.AutoSyncLog
    }
    else
    {
        Write-Warning ("{0}:Watch-AutoSync:: AutoSync does not seem to be running." -f $ExecutionContext.SessionState.Module)
    }
}

#endregion

#region Generic PowerShell Helpers

#########################################################################################
# Set-Verbose
#########################################################################################
# .ExternalHelp DevPack.Help.xml
function Set-Verbose
{
	param
	(
		[switch]$Off = $false
	)

	if ($Off)
	{
        Write-Host ("{0}:Set-Verbose:: Verbose output is now off." -f $ExecutionContext.SessionState.Module) -ForegroundColor Green
		$global:VerbosePreference = "SilentlyContinue"
	}
	else
	{
        Write-Host ("{0}:Set-Verbose:: Verbose output is now on." -f $ExecutionContext.SessionState.Module) -ForegroundColor Green
		$global:VerbosePreference = "Continue"
	}
}


#########################################################################################
# Show-ScriptBlock
#########################################################################################
# .ExternalHelp DevPack.Help.xml
function Show-ScriptBlock
{
	param
	(
		[Parameter(Mandatory=$true, ValueFromPipeline=$false)]
		[string]$Command
	)

	Get-Command $Command | Select-Object -ExpandProperty ScriptBlock
}


#########################################################################################
# Import-Assembly
#########################################################################################
# .ExternalHelp DevPack.Help.xml
function Import-Assembly
{
	[CmdletBinding()]
	param
	(
		[string]$FilePath,
		[switch]$Quiet
	)

	try
	{
		$oBytes = [IO.File]::ReadAllBytes($FilePath)
		$oResults = [System.Reflection.Assembly]::Load($oBytes);

		if (!$Quiet)
		{
			[System.Reflection.AssemblyName]::GetAssemblyName($FilePath) | Select-Object Name, Version, @{ Name="Framework"; Expression={ $oResults.ImageRuntimeVersion } }
		}
	}
	catch
	{
		throw ("{0}:Import-Assembly:: ERROR: {1} {2} {3}" -f $ExecutionContext.SessionState.Module, $_, $_.InvocationInfo.ScriptStackTrace, $_.InvocationInfo.PositionMessage)
	}
}

#########################################################################################
# Watch-Tail - A tool to monitor live log files
#########################################################################################
# .ExternalHelp DevPack.Help.xml
function Watch-Tail
{
    [CmdletBinding()]
    param
    (
        [Parameter(ValueFromPipeline=$true)]
        [object]$InputObject,
        [string]$filespec = $null,
        [int]$num_bytes = -1,
        [int]$num_lines = -1,
        [int]$sleep = 1,
        [switch]$popup,
        [switch]$quiet,
        [switch]$help,
        [switch]$setup
    )

    begin
    {
        if ($setup)
        {
            [string]$sRegFile = "{0}WatchTail-AddContextMenuItems.reg" -f [IO.Path]::GetTempPath()
            Write-Output @"
Windows Registry Editor Version 5.00
[HKEY_CLASSES_ROOT\SystemFileAssociations\.log]
[HKEY_CLASSES_ROOT\SystemFileAssociations\.log\shell]
[HKEY_CLASSES_ROOT\SystemFileAssociations\.log\shell\MonitorLog]
@="Monitor Lo&g"
[HKEY_CLASSES_ROOT\SystemFileAssociations\.log\shell\MonitorLog\Command]
@="cmd /c start powershell.exe -NoProfile -Command \"`$Host.UI.RawUI.WindowTitle = 'Monitor Log: %1 (ESC/F2/F5/SPC)'; Import-Module '$($DevPackConfig.RepoRoot)\DevPack.psm1'; Clear-Host; Watch-Tail -Filespec:'%1' -num_lines:40 -sleep:3;\""
[HKEY_CLASSES_ROOT\SystemFileAssociations\.txt]
[HKEY_CLASSES_ROOT\SystemFileAssociations\.txt\shell]
[HKEY_CLASSES_ROOT\SystemFileAssociations\.txt\shell\MonitorTxt]
@="Monitor T&xt"
[HKEY_CLASSES_ROOT\SystemFileAssociations\.txt\shell\MonitorTxt\Command]
@="cmd /c start powershell.exe -NoProfile -Command \"`$Host.UI.RawUI.WindowTitle = 'Monitor Txt: %1 (ESC/F2/F5/SPC)'; Import-Module '$($DevPackConfig.RepoRoot)\DevPack.psm1'; Clear-Host; Watch-Tail -Filespec:'%1' -num_lines:40 -sleep:3;\""
"@ | Out-file $sRegFile
            regedt32 $sRegFile
            break
        }

        if ($help)
        {
            Write-Host ("{0}:Watch-Tail:: Usage: Watch-Tail -filespec <string> -num_bytes <int> -num_lines <int> -sleep <int> -quiet"  -f $ExecutionContext.SessionState.Module) -ForegroundColor Green
            Break
        }

        ### if no bytes or lines specified, default to 10 lines
        if ($num_bytes -eq -1 -and $num_lines -eq -1)
        {
            $num_lines = 10
        }

        if ( ($filespec -eq "" -or $filespec -eq $null) -and $InputObject -ne $null ) { $filespec = $InputObject }
    }

    process
    {
        if ($popup)
        {
            if ($_ -ne $null) { $filespec = $_ }
            [string]$sShortName = $filespec
            if ($sShortName.Length -gt 75)
            {
                $sShortName = ("{0}...{1}" -f $sShortName.Substring(0,10), $sShortName.Substring($sShortName.Length - 60))
            }
            Write-Host ("{0}:Watch-Tail:: Opening {1} in a popup..." -f $ExecutionContext.SessionState.Module, $sShortName) -ForegroundColor Green
            cmd /c start powershell.exe -NoProfile -Command "[console]::Title = 'Monitor Log: $sShortName (ESC,F2,F5,SPC)'; [console]::BackgroundColor='White'; [console]::ForegroundColor='Black'; Clear-Host; Import-Module .\DevPack.psm1; Clear-Host; Watch-Tail -Filespec:'$filespec' -num_lines:40 -sleep:$sleep;"
        }
    }

    end
    {
        if (-not $popup)
        {

            if ($filespec -eq "")
            {
                if ($InputObject -ne $null -and -not $popup)
                {
                    Write-Warning ("{0}:Watch-Tail:: Use -popup to view multiple files." -f $ExecutionContext.SessionState.Module)
                }
                else
                {
                    Write-Warning ("{0}:Watch-Tail:: No file specifications specified." -f $ExecutionContext.SessionState.Module)
                }
                Break
            }


            $file = @(Get-ChildItem $filespec);
            if ($file.Count -eq 1)
            {
                # Optionally output file names when multiple files given
                if ( ($files.Length -gt 1) -and !$quiet ) { Write-Host "==> $($file.Name) <==" }

                if ($num_lines -ne -1)
                {
                    $prev_len = 0
                    while ($true)
                    {
                        # For line number option, get content as an array of lines
                        # and print out the last "n" of them.
                        $lines = Get-Content $file -ErrorAction:SilentlyContinue
                        if ($lines -ne $null)
                        {
                            if ($prev_len -ne 0) { $num_lines = $lines.Length - $prev_len }

                            $start_line = $lines.Length - $num_lines

                            # Ensure that we don't go past the beginning of the input
                            if ($start_line -le 0) { $start_line = 0 }

                            if ($lines.GetType().Name.Equals("String"))
                            {
                                if ($prev_len -eq 0)
                                {
                                    $lines
                                }
                                $prev_len = 1
                            }
                            else
                            {
                                for ($i = $start_line; $i -lt $lines.Length; $i++)
                                {
                                    $lines[$i]
                                }
                                $prev_len = $lines.Length
                            }
                        }

                        Start-Sleep $sleep

                        if ([console]::KeyAvailable)
                        {
                            $sInput = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
                            ### SPACE
                            if ($sInput.VirtualKeyCode -eq 32)    { Write-Host " $([char]8)" -NoNewLine }
                            ### ESC
                            if ($sInput.VirtualKeyCode -eq 27)    { Exit }
                            ### F2
                            if ($sInput.VirtualKeyCode -eq 113)    { Start notepad.exe $file.FullName; Break }
                            ### F5
                            if ($sInput.VirtualKeyCode -eq 116) { Clear-Host; $num_lines = $prev_len; $prev_len = 0 }
                        }
                    }
                }
                elseif ($num_bytes -ne -1)
                {
                    # for num bytes option, get the content as a single string
                    # and substring the last "n" bytes.
                    [string]$content = Get-Content $file -delim [char]0

                    if ( ($content.Length - $num_bytes) -lt 0 ) { $num_bytes = $content.Length }
                    $content.SubString($content.Length - $num_bytes)
                }
            }
            else
            {
                Write-Warning ("{0}:Watch-Tail:: Cannot tail more than one file. Count = {1}" -f $ExecutionContext.SessionState.Module, $file.Count)
            }
        }
    }
}


#########################################################################################
# Watch-Output
#########################################################################################
# .ExternalHelp DevPack.Help.xml
function Watch-Output
{
	param
	(
		[scriptblock]$Script,
		[int]$Interval = 1
	)

	$oOrigOutput = & $Script
	$oOrigOutput

	$oOutput = $oOrigOutput
	while ($oOutput -eq $oOrigOutput)
	{
		Sleep -Seconds $Interval

		$oOutput = & $Script
	}

	$oOutput
}


#########################################################################################
# Wait-Countdown
#########################################################################################
# .ExternalHelp DevPack.Help.xml
function Wait-Countdown
{
	param
	(
		[Alias("Seconds")]
		[object]$TimeSpan = "10s",

		[Alias("NoInt")]
		[switch]$NoInterrupt,

		[switch]$Silent
	)

	### Convert TimeSpan into Seconds
	[int]$iSeconds = $(if ($TimeSpan -is [string]) { (ConvertTo-Milliseconds -Value $TimeSpan -Quiet) / 1000 } else { ([timespan]$TimeSpan).TotalSeconds } )
	if ($iSeconds -eq 0) { $iSeconds = (ConvertTo-Milliseconds "$($TimeSpan)s") / 1000 }

	### Ensure keyboard buffer is clear
	$Host.UI.RawUI.FlushInputBuffer()

	if (-not $Silent)
	{
		$sMsg = "Waiting {1} before continuing..."
		if (-not $NoInterrupt) { $sMsg = "Waiting {1} (Any key to continue):"}

		Write-Host ("{0}:Wait-Countdown:: $($sMsg)"-f $ExecutionContext.SessionState.Module, (ConvertFrom-Milliseconds -IncludeSeconds (1000*$iSeconds))) -NoNewLine -ForegroundColor Green
	}

	while ($iSeconds -ge 0)
	{
		### Interrupt on any key
		if (-not $NoInterrupt -and [console]::KeyAvailable) { break }

		Start-Sleep -Seconds 1
		if (-not $Silent)
		{
			[string]$sColor = $(if ($iSeconds -le 10) { if ($iSeconds -le 5) { "Red" } else { "Yellow" } } else { "Green" })
			Write-Host ("$([char]13){0}:Wait-Countdown:: $($sMsg) "-f $ExecutionContext.SessionState.Module, (ConvertFrom-Milliseconds -IncludeSeconds (1000*$iSeconds))) -NoNewLine -ForegroundColor $sColor
		}
		$iSeconds--
	}

	if (-not $Silent)
	{
		### Clear current line on console
		Write-Host "$([char]13)$(' ' * ($Host.UI.RawUI.WindowSize).Width)"
	}
}


#########################################################################################
# ConvertFrom-Milliseconds
#########################################################################################
# .ExternalHelp DevPack.Help.xml
function ConvertFrom-Milliseconds
{
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory=$true, ValueFromPipeline=$false)]
		[int64]$Value,
		[switch]$IncludeSeconds,
		[switch]$IncludeMilliseconds,
		[switch]$Compact,
		###[switch]$StandardFormat,
		[switch]$Quiet
	)

	### Check if this is a negative value
	[bool]$bIsNegative = $Value -lt 0

	### Convert integer in Milliseconds into a TimeSpan object (10000 ticks per millisecond)
	[timespan]$oTimeValue = New-Object Timespan -ArgumentList ([Math]::Abs($Value) * 10000)

	### Build time value
	[string]$sTimeValue = $(if ($bIsNegative) { @( "-" ) } else { $null })
	if ($oTimeValue.Days -gt 0) { $sTimeValue += "{0}d " -f $oTimeValue.Days }
	if ($oTimeValue.Hours -gt 0) { $sTimeValue += "{0}h " -f $oTimeValue.Hours }
	if ($oTimeValue.Minutes -gt 0) { $sTimeValue += "{0}m " -f $oTimeValue.Minutes }
	if ($IncludeSeconds -and $oTimeValue.Seconds -gt 0) { $sTimeValue += "{0}s " -f $oTimeValue.Seconds }
	if ($IncludeMilliseconds -and $oTimeValue.Milliseconds -gt 0) { $sTimeValue += "{0}i" -f $oTimeValue.Milliseconds }

	if ($sTimeValue.Length -eq 0)
	{
		$sTimeValue = "0m"
		if ($IncludeSeconds) { $sTimeValue = "0s" }
		if ($IncludeMilliseconds) { $sTimeValue = "0i" }
		return ($sTimeValue)
	}
	else
	{
		if ($Compact)
		{
			return (($sTimeValue -Join "") -Replace " ", "").Trim()
		}
		else
		{
		    return ($sTimeValue -Join "").Trim()
		}
	}
}


#########################################################################################
# ConvertTo-Milliseconds
#########################################################################################
# .ExternalHelp DevPack.Help.xml
function ConvertTo-Milliseconds
{
	[CmdletBinding()]
	param
	(
		[Parameter(Mandatory=$true, ValueFromPipeline=$false)]
		[string]$Value,
		[switch]$Quiet
	)

	### Convert known single UOMs to thier equivalent
	if ($Value -eq "HOUR") { $Value = "1h" }
	if ($Value -eq "DAY") { $Value = "1d" }
	if ($Value -eq "WEEK") { $Value = "1w" }
	if ($Value -eq "MONTH") { $Value = "1m" }
	if ($Value -eq "QUARTER") { $Value = "1q" }
	if ($Value -eq "YEAR") { $Value = "1y" }

    [Int64]$iResult = 0

	if ($Value.Trim().Length -gt 0)
	{
		[string]$sTimeValues = $Value.Replace("d","d ").Replace("i","i ").Replace("s","s ").Replace("m","m ").Replace("h","h ").Replace("d","d ").Replace("w","w ").Replace("o","o ").Replace("q","q ").Replace("y","y ") -Replace "  "," "

		ForEach ( $sValue in ($sTimeValues.Split(" ")) )
		{
			if ($sValue.Length -gt 0)
			{
				[string]$sTimeType = $sValue.Substring($sValue.Length - 1, 1)
				[string]$sTimeValue = $sValue.Substring(0, $sValue.Length - 1)
				[int64]$iTimeValue = [System.Int32]::Parse($sTimeValue)

				switch ($sTimeType)
				{
					"i" { $iResult += $iTimeValue * 1 } ## MilliSecond
					"s" { $iResult += $iTimeValue * 1000 } ## Second
					"m" { $iResult += $iTimeValue * 1000 * 60 } ## Minute
					"h" { $iResult += $iTimeValue * 1000 * 60 * 60 } ## Hour
					"d" { $iResult += $iTimeValue * 1000 * 60 * 60 * 24 } ## Day
					"w" { $iResult += $iTimeValue * 1000 * 60 * 60 * 24 * 7 } ## Week
					"o" { $iResult += $iTimeValue * 1000 * 60 * 60 * 24 * 7 * (52 / 12) } ## Month
					"q" { $iResult += $iTimeValue * 1000 * 60 * 60 * 24 * 7 * (52 / 12) * 3 } ## Quarter
					"y" { $iResult += $iTimeValue * 1000 * 60 * 60 * 24 * 7 * (52 / 12) * 12 } ## Year
					default { if (-not $Quiet) { Write-Warning "Invalid time measurement specified.  Valid units-of-measure are: i s m h d w o q y" } }
				}
			}
		}
	}

    return ($iResult)
}


#########################################################################################
# ConvertFrom-TokenizedString
#########################################################################################
<#
.SYNOPSIS
    Replace keywords in a string.
.DESCRIPTION
    Converts a string with tokenized keywords into a literal string by specifying -TokenizedString and providing a hashtable either in the pipeline or the -InputObject.

    By default, tokens are to begin with @! and end with !@.  For example, the string "\\localhost\@!CDDRIVE!@$\" would translate to "\\localhost\D$\" with the following hashtable passed in:

        Name       Value
        ---------  ---------
        CDDRIVE    D
.INPUTS
    Values from the hashtable piped in are used to replace tokens in the -TokenizedString value.
.OUTPUTS
    The resulting string is the -TokenizedString with all tokens found in the keys of the hashtable piped in.
.EXAMPLE
@{ DataCenter="$($oDataCenters.DataCenter[0])" } | ConvertFrom-TokenizedString "Environment:PMMC and DataCenter:@!DataCenter!@"
Environment:PMMC and DataCenter:DB3

.EXAMPLE
ConvertFrom-TokenizedString -TokenizedString:"\\BLUWCSFSSC01\E$\DEPOT-BLU\JupiterLogs\@!DataCenter!@\@!DataCenter!@@!CType!@" -InputObject:(Select-SM -Full | Select -First 1)
\\BLUWCSFSSC01\E$\DEPOT-BLU\JupiterLogs\SN2\SN2SSU

.EXAMPLE
$oTokens = "" | Select CDDRIVE; $oTokens.CDDRIVE = "D"
C:\PS>$oTokens | ConvertFrom-TokenizedString -TokenizedString:"\\localhost\@!CDDRIVE!@$\"
\\localhost\D$\

.EXAMPLE
@{ CDDRIVE = "D" } | ConvertFrom-TokenizedString "\\localhost\@!CDDRIVE!@$\"
\\localhost\D$\
#>

function ConvertFrom-TokenizedString
{
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory=$true, ValueFromPipeline=$false)]
        [string]$TokenizedString,

        [Parameter(Mandatory=$false, ValueFromPipeline=$false)]
        [string]$OpenToken = "@!",

        [Parameter(Mandatory=$false, ValueFromPipeline=$false)]
        [string]$CloseToken = "!@",

        [Parameter(Mandatory=$false, ValueFromPipeline=$true)]
        [object]$InputObject
    )


    $ErrorActionPreference = "Stop"


    ### Handle input
    if ($InputObject -eq $null) { $InputObject = $Input }


    ### Extract unique tokens found in tokenized string
    [hashtable]$oTokenValues = @{}
    [string]$sTemp = $TokenizedString
    while ($sTemp.IndexOf($OpenToken) -ge 0)
    {
        [int]$iBeginPos = $sTemp.IndexOf($OpenToken)
        [int]$iEndPos = $sTemp.IndexOf($CloseToken)
        [string]$sToken = $sTemp.Substring($iBeginPos + 2, $iEndPos - $iBeginPos - 2)
        if (!$oTokenValues.ContainsKey($sToken)) { $oTokenValues.Add($sToken, "") }
        $sTemp = $sTemp.Substring($iEndPos + 2)
    }


    ### Populate TokenValues from token values piped in
    [string[]]$oKeys = $oTokenValues.Keys
    ForEach ($sToken in $oKeys)
    {
        $oTokenValues[$sToken] = Invoke-Expression("`$InputObject." + $sToken)
    }

    ### Perform search and replace
    [string]$sUntokenizedString = $TokenizedString
    ForEach ($sToken in $oKeys)
    {
        $sUntokenizedString = $sUntokenizedString -Replace "$OpenToken$sToken$CloseToken", $oTokenValues[$sToken]
    }


    ### Send output into pipeline
    $sUntokenizedString
}

#########################################################################################
# Use-Module
#########################################################################################
# .ExternalHelp DevPack.Help.xml
function Use-Module
{
	param
	(
		[string]$Module,
		[string[]]$Noun,
		[switch]$List
	)

	$oAllCmds = Get-Command -Module $Module -Syntax -Noun $Noun | % {
		$oCommand = ("" | Select Alias, Function, Noun, Syntax)
		$oCommand.Function = ($_.Trim() -split " ")[0]
		$oCommand.Noun = ($oCommand.Function -split "-")[1]
		$oCommand.Syntax = $_.Trim()
		$oCommand.Alias = (Get-Alias -Definition $oCommand.Function -ErrorAction SilentlyContinue | Select-Object -ExpandProperty Name)
		$oCommand
	}

	if ($Noun.Length -gt 1)
	{
		$oAllCmds += Get-Command -Module $Module -CommandType Alias | % {
			if ($_.Name -notin $oAllCmds.Alias) {
				$oCommand = ("" | Select Alias, Function, Noun, Syntax)
				$oCommand.Function = ($_.DisplayName -split " ")[2]
				$oCommand.Noun = ""
				$oCommand.Syntax = $_.Name
				$oCommand.Alias = $_.Name
				$oCommand
			}
		}
	}

	if ($List)
	{
		$oAllCmds | Sort-Object -Property Alias, Function | Format-Table -AutoSize
	}
	else
	{
		$oCmd = $oAllCmds | Sort-Object -Property Alias, Function | Out-GridView -Title "$($Module) Commands" -PassThru
		if ($oCmd -ne $null)
		{
			$oCmd | % {
				$oThisCmd = $_
				Write-Host ("{0}:Use-Module:: Launching command helper {1} in {2}" -f $ExecutionContext.SessionState.Module.Name, $oThisCmd.Function, $Module) -ForegroundColor Green
				Show-Command $($oThisCmd.Function)
			}
		}
	}
}


#########################################################################################
# Set-Prompt
#########################################################################################
# .ExternalHelp DevPack.Help.xml
function Set-Prompt
{
	param
	(
		[string]$Template = $null,
		[switch]$Off,
		[switch]$Enable,
		[switch]$ListOptions,
		[switch]$Disable,
		[switch]$Show,
		[switch]$Full
	)

	if ($Enable -or $Disable)
	{
		$sCommand = $(if ($Disable) { "Remove-Item Alias:Prompt" } else { "Set-Alias -Name Prompt -Value Use-Prompt" })
		Invoke-FakeKey $sCommand -Quiet
		break
	}
	else
	{
		if ($Template.Length -gt 0)
		{
			$DevPackConfig.DevPackPromptTemplate = $Template
			break
		}

		if ($ListOptions)
		{
			$oOptions = @()
			$oOptions += "BuildWeek"
			$oOptions += "Changes"
			$oOptions += "ComputerName"
			$oOptions += "Domain"
			$oOptions += "Environment"
			$oOptions += "Location"
			$oOptions += "LoginName"
			$oOptions += "NewLine"
			$oOptions += "NewLine"
			$oOptions += "Operation"
			$oOptions += "RepoName"
			$oOptions += "TimeStamp"

			Write-Host ("{0}:Set-Prompt:: DevPack Prompt Options are:" -f $ExecutionContext.SessionState.Module) -ForegroundColor Green
			Write-Host
			$oOptions | % { "        @!$($_)!@" }
		}

		if ($Show)
		{
			[string]$sLocation = $(Get-Location).ToString().Replace("Microsoft.PowerShell.Core\FileSystem::", "")
			if ($sLocation -eq $HOME) { $sLocation = "~" }

			Write-Host ("{0}:Set-Prompt:: Git repository is {1}" -f $ExecutionContext.SessionState.Module, $sLocation) -ForegroundColor Green

			if ($Full)
			{
				Write-Host ("{0}:Set-Prompt:: Prompt template is {1}" -f $ExecutionContext.SessionState.Module, $DevPackConfig.DevPackPromptTemplate) -ForegroundColor Green
			}
		}

		if ($Off)
		{
			Write-Host ("{0}:Set-Prompt:: DevPack Prompt is now off." -f $ExecutionContext.SessionState.Module) -ForegroundColor Green
			$DevPackConfig.EnableDevPackPrompt = $false
		}
		else
		{
			Write-Host ("{0}:Set-Prompt:: DevPack Prompt is now on." -f $ExecutionContext.SessionState.Module) -ForegroundColor Green
			$DevPackConfig.EnableDevPackPrompt = $true
		}
	}
}


#########################################################################################
# Prompt
#########################################################################################
# .ExternalHelp DevPack.Help.xml
function Use-Prompt
{
    ### Get current directory (removing UNC path header)
    [string]$sLocation = $(Get-Location).ToString().Replace("Microsoft.PowerShell.Core\FileSystem::", "")
    if ($sLocation -eq $HOME) { $sLocation = "~" }

    if (-not $DevPackConfig.EnableDevPackPrompt)
    {
        return "PS $($sLocation)> "
    }
    else
    {
		### Determine Operation and Environment
		if (Test-Path -Path $DevPackConfig.OPENVFilePath)
		{
			[string[]]$oLastUpdate = (Get-Content $DevPackConfig.OPENVFilePath).Split('/')
			$DevPackConfig.Operation = $oLastUpdate[0]
			$DevPackConfig.Environment = $oLastUpdate[1]
		}
		else
		{
			$DevPackConfig.Operation = ""
			$DevPackConfig.Environment = ""
		}

		### Determine GIT repository
		if ((Test-Path "$($sLocation)\.git\HEAD") -and ($sLocation -ne $DevPackConfig.RepoRoot) -and (-not ($sLocation).StartsWith($DevPackConfig.RepoRoot + "\")))
		{
			### Switching repositories!
			Write-Host ("{0}:Prompt:: Switching repository to {1}" -f $ExecutionContext.SessionState.Module, $sLocation) -ForegroundColor Yellow
			$DevPackConfig.RepoRoot = $sLocation
		}

		### Allow some coloration even when deeper in directory structure
		[string]$sRepoRoot = $sLocation
		if ($sLocation.StartsWith($DevPackConfig.RepoRoot) -and $sLocation -ne $DevPackConfig.RepoRoot) { $sRepoRoot = $DevPackConfig.RepoRoot }

		### Pull repository name from HEAD file
		$DevPackConfig.RepoName = $(if (Test-Path "$($sRepoRoot)\.git\HEAD") { (Get-Content "$($sRepoRoot)\.git\HEAD").Replace("ref: refs/heads/","") } else { "no-repository" })

        ### Set prompt color
        [string]$sColor = "DarkGray"
        if ($DevPackConfig.RepoName -eq "develop" -and $sLocation.StartsWith($DevPackConfig.RepoRoot)) { $sColor = "Green" }
        if ($DevPackConfig.RepoName -eq "test" -and $sLocation.StartsWith($DevPackConfig.RepoRoot)) { $sColor = "Yellow" }
        if ($DevPackConfig.RepoName -eq "master" -and $sLocation.StartsWith($DevPackConfig.RepoRoot)) { $sColor = "Red" }
        if ($sLocation.StartsWith($DevPackConfig.RepoRoot) -and $sLocation -ne $DevPackConfig.RepoRoot) { $sColor = "Dark$($sColor)" }

		### Update title with current directory
		[string]$sAdmin = $(if (([Security.Principal.WindowsPrincipal] [Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]"Administrator") ) { "- Administrator" } else { "" })
		[string]$sChanges = $(if ((Test-Path "$($sRepoRoot)\.git\rebase*")) { " REBASE" } else { if ($(git ls-files -m).Count -gt 0) {" *"} else { "" } })
		$Host.UI.RawUI.WindowTitle = "PS:: $sLocation ($($DevPackConfig.RepoName)$($sChanges)) $($sAdmin)"

        ### Populate custom prompt
        [string]$sPromptTemplate = $DevPackConfig.DevPackPromptTemplate
        if ($sPromptTemplate.Length -eq 0) { $sPromptTemplate = "@!TimeStamp!@" }
        [string]$sPrompt = @{

            ### Prompt Token: BuildWeek
            BuildWeek = (Get-BuildWeek);

            ### Prompt Token: TimeStamp
            TimeStamp = (Get-Date).ToString("HH:mm:ss");

            ### Prompt Token: Domain
            Domain = $ENV:USERDOMAIN;

            ### Prompt Token: LoginName
            LoginName = [IO.Path]::GetFileName($ENV:USERPROFILE);

            ### Prompt Token: ComputerName
            ComputerName = $ENV:COMPUTERNAME;

            ### Prompt Token: NewLine
            NewLine = ([char]10);

            ### Prompt Token: Location
            Location = $sLocation;

            ### Prompt Token: Operation
			Operation = $DevPackConfig.Operation.ToUpper();

            ### Prompt Token: Environment
			Environment = $DevPackConfig.Environment.ToUpper();

            ### Prompt Token: RepoName
            RepoName = $DevPackConfig.RepoName;

            ### Prompt Token: Changes
            Changes = $sChanges;

        } | ConvertFrom-TokenizedString $sPromptTemplate

		### OVERRIDE prompt color to red if the data is pointing to anything production
		if ($DevPackConfig.Environment -match "prod") { $sColor = "Red" }

        ### Display prompt
        Write-Host $sPrompt -ForegroundColor $sColor -NoNewLine
        return "PS> "
    }
}


#########################################################################################
# Get-Clipboard
#########################################################################################
# .ExternalHelp DevPack.Help.xml
function Get-Clipboard
{
	param
	(
		[switch]$ToArray,
		[switch]$ToFloat
	)

	if ($Host.Runspace.ApartmentState -ne 'STA')
	{
		Write-Warning ("{0}:Get-Clipboard:: Run {1} with the -STA parameter to use this function" -f $ExecutionContext.SessionState.Module, $Host.Name)
		Break
	}

	Add-Type -Assembly PresentationCore
	$oContent = [Windows.Clipboard]::GetText()

	if ($ToArray)
	{
		if ($ToFloat)
		{
			$oContent -Split [System.Environment]::NewLine | % { [float]$_ }
		}
		else
		{
			$oContent -Split [System.Environment]::NewLine
		}
	}
	else
	{
		if ($ToFloat)
		{
			[float]$oContent
		}
		else
		{
			$oContent
		}
	}
}


#########################################################################################
# Get-WebResponse
#########################################################################################
#
# Example Use:
#		([xml](Get-WebResponse http://s3.usechicagotitle.com/)).ListBucketResult.Contents | Out-GridView
#
# .ExternalHelp DevPack.Help.xml
function Get-WebResponse
{
	param
	(
        [Parameter(Mandatory=$true)]
		[string]$URL
	)

	[Net.WebRequest]$oWebRequest = [Net.WebRequest]::Create($URL)
	[Net.WebResponse]$oResponse = $oWebRequest.GetResponse()

	$oStream = $oResponse.GetResponseStream()

	[IO.StreamReader]$oReader = New-Object System.IO.StreamReader -ArgumentList $oStream;
	[string]$sResults = $oReader.ReadToEnd()

	$sResults
}


#########################################################################################
# Find-Files
#########################################################################################
function Find-Files
{
	param
	(
        [Parameter(Mandatory=$true)]
		[string]$FileSpec
	)

	Get-ChildItem -Recurse -Filter $FileSPec -ErrorAction SilentlyContinue | Select-Object -Property FullName
}


#########################################################################################
# Find-InFiles
#########################################################################################
function Find-InFiles
{
	param
	(
        [Parameter(Mandatory=$true)]
		[string]$FileSpec,

        [Parameter(Mandatory=$true)]
		[string]$SearchString
	)

	Get-ChildItem -Recurse -Filter $FileSPec -ErrorAction SilentlyContinue | % {
		$oResults = Get-Content $_.FullName | Select-String -Pattern $SearchString
		if ($oResults.length -gt 0)
		{
			Write-Host $_.FullName -ForegroundColor Green
			$oResults
		}
	}
}


#########################################################################################
# Get-Response
#########################################################################################
# .ExternalHelp DevPack.Help.xml
function Get-Response([string]$Prompt, [string]$Default)
{
	Write-Host ("{0} {1}$([char]8)" -f ($Prompt -replace '\\n', [Environment]::NewLine), $Default) -NoNewLine -ForegroundColor Green
	Write-Output (((Read-Host)[0] -Replace $Default, "") -eq "")
}


#########################################################################################
# Get-ProcessOwner
#########################################################################################
function Get-ProcessOwner([string]$Filter)
{
	ForEach ($oProcess in (Get-WmiObject -Namespace ROOT\cimv2 -Class Win32_Process -Filter $Filter) )
	{
		try
		{
			Add-Member -MemberType NoteProperty -Name Owner -Value ($oProcess.GetOwner().User) -InputObject $oProcess -PassThru
		}
		catch {}
	}
}


#########################################################################################
# Open-IE
#########################################################################################
# .ExternalHelp DevPack.Help.xml
function Open-IE
{
	[CmdletBinding()]
	param
	(
		[string]$URL = "about:blank",
		[string]$HTML = $null,

		[switch]$Passthru,

		[object]$IE = $null
	)

	### Open a browser
	[object]$oIE = $IE
	if ($oIE -eq $null) { $oIE = New-Object -COM InternetExplorer.Application }
	$oIE.Navigate2($URL)

	### Wait for it
	While ($oIE.Busy) { Start-Sleep -Milliseconds 100 }
	if ($oIE -eq $null)
	{
		Write-Host ("{0}:Open-IE: Cannot attach to Internet Explorer." -f $ExecutionContext.SessionState.Module)
		Break
	}
	$oIE.Visible = $true

	if ($HTML.Length -gt 0)
	{
		### Put the HTML into the browser
		$oDocBody = $oIE.Document.DocumentElement.LastChild
		$oDocBody.InnerHTML = $HTML
	}

	if ($Passthru)
	{
		$oIE
	}
}


#########################################################################################
# Show-MessageBox
#########################################################################################
# .ExternalHelp DevPack.Help.xml
function Show-MessageBox
{
	param(
        [Parameter(Mandatory=$true)]
		[string]$Message,

        [Parameter(Mandatory=$true)]
		[string]$Caption,

		[string]$Button = "OK"
	)

	[System.Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms") | Out-Null
	([System.Windows.Forms.MessageBox]::Show($Message, $Caption, [System.Windows.Forms.MessageBoxButtons]$Button)).ToString()
}


#########################################################################################
# Redo-History.ps1 - Cross session command history management utility
# -------------------------------------------------------------------------------------
#
#  Version 1.0        Todd Howard              08/24/2012
#  Version 1.1        Todd Howard              10/19/2012	Moved default commands file to network location
#
#########################################################################################
<#
.SYNOPSIS
    Save and recall commands across PowerShell sessions and workstations.

.DESCRIPTION
	(All switches accept both short form or long form. For example both -s and -save are valid.)

    Use this utility to retain a set of complex commands across PowerShell sessions.  By default, commands are stored in a file named ".Redo_Commands" in the \\Intune99\OpsInfo\Users\$ENV:USERNAME directory.  This file name and location can changed by altering "$HOME\.Redo_Settings" manually.

	There are two main ways Redo-History can be used:

	1) To save and recall commands

    Redo-History <id or name> [-Confirm] [-WhatIf]         : Recall command at position x from Commands file

	2) To copy multiple commands from Get-History to the clipboard

    Redo-History                                    : List commands in Commands file
    Redo-History -F[ake]                            : Causes Redo-History to re-key the command
    Redo-History -G[rid]                            : Open command list in a grid
    Redo-History -E[dit]                            : Manually edit Commands file
    Redo-History -P[assthru] | ? { $_.Description -match "Count" } : Search history for a specific term
#>
# .ExternalHelp DevPack.Help.xml
function Redo-History
{
	[CmdletBinding()]
	param
	(
        [string]$Name = $null,
		[switch]$Confirm,
		[Alias('E')][switch]$Edit,
		[Alias('F')][switch]$Fake,
		[Alias('P')][switch]$Passthru,
		[Alias('G')][switch]$Grid,
		[int]$Id,
		[switch]$Help
	)

	if ($Help) { Get-Help Redo-History; Break }

	$ErrorActionPreference = "Stop"

	### Check for conflicting switches ###
    if ( $Grid -and $Passthru )
	{
		Write-Warning "Conflicting switches. -List and -Grid are mutually exclusive switches."
		Break
	}

	### Try and use Name as a Number
	[int]$Number = 0;
	try { $Number = [int]::Parse($Name) }
	catch {}
	if ($Number -gt 0) { $Name = $null }

	### Load default settings ###
	[object]$oVals = @{}
	[string]$sHistoryFilePath = "$($HOME)\.Redo_Commands"
	if ($CoreConfig.HistoryFilePath -ne $null) { $sHistoryFilePath = $CoreConfig.HistoryFilePath }
	$sOutputDir = Split-Path $sHistoryFilePath

	### Ensure output directory exists ###
	if (!(Test-Path "$sOutputDir" -PathType container)) { New-Item "$sOutputDir" -Type directory | Out-Null }

	### Ensure history file exists
	if (!(Test-Path $sHistoryFilePath)) { New-Item -Path $sHistoryFilePath -Type File -Value "### .Redo_Commands`n`n" | Out-Null }

	### Import shell history from Id
	if ($Id -gt 0)
	{
		$sCommand = (Get-History -Id $Id | Select-Object -ExpandProperty CommandLine)
		if ($Name -eq $null) { $Name = "NewCmd_{0:000}" -f (New-Object Random).Next(999) }

		("{2}<# {0}: #> {1}" -f $Name, $sCommand, [Environment]::NewLine) | Out-File -Append -FilePath $sHistoryFilePath -Encoding ascii

	    Write-Host ("{0}:Redo-History:: Added shell history id #{1} to Redo-History as {2}." -f $ExecutionContext.SessionState.Module, $Id, $Name) -ForegroundColor Green
		Break
	}

	### Enter Edit History Mode ###
	if ($Edit) { Notepad $sHistoryFilePath; Break }

	### Build object of commands
	[int]$iCounter = 0
	[object]$oCommands = @()
	Get-Content $sHistoryFilePath | ForEach-Object {
		$sCommand = $_
		if ($sCommand.Length -gt 2 -and !($sCommand -match "^#") )
		{
			$iCounter++

			if ($sCommand.Substring(0,3) -eq "<# ")
			{
				$sDescription = $sCommand.Substring(3,$sCommand.IndexOf(" #>") - 3 ).Trim()
                if ($sDescription.Length -gt 0 -and $sDescription.IndexOf(":") -gt 0)
                {
                    $sName = (($sDescription.Split(":"))[0]).Trim()
                    $sDescription = (($sDescription.Split(":"))[(1..99)]).Trim()
                    if ($sName.Length -gt 0 -and $sName.IndexOf(" ") -gt 0)
                    {
                        $sName = ($sName.Split(" "))[0]
                    }
                }
                else
                {
                    $sName = $iCounter
                }
				$sCommand = $sCommand.Substring($sCommand.IndexOf(" #>") + 4).Trim()
			}

			### Create object with DataTypes
			[object]$oCommand = "" | Select Id, Name, Description, CommandLine

			$oCommand.Id = $iCounter
            $oCommand.Name = $sName
			$oCommand.Description = $sDescription
			$oCommand.CommandLine = $sCommand

			$oCommands += $oCommand

            if ($Name -eq $sName)
            {
                $Number = $iCounter
            }
		}
	}


	### Force list if no options or ids on commandline
	$bNoOptions = ( !$Passthru -and !$Grid -and $Name.Length -eq 0 -and $Number -eq 0)


	### Show List / Execute Command / Save Command(s)
	if ($bNoOptions)
	{
		if ($oCommands.Count -eq 0)
		{
			Write-Host (" ** No commands have been saved to the history file: {0}" -f $sHistoryFilePath) -ForegroundColor Green
			Break
		}

		$oCommands | Format-Table -AutoSize ### Select-Object @{ Name="Id"; Expression = { ("{0}" -f $_.Id) } }, Description, CommandLine
	}
	elseif ($Passthru)
	{
		if (!$Id)
			{ $oCommands }
		else
			{ $Id | ForEach { $oCommands[$_ - 1] } }
	}
	else
	{
		if ($Grid)
		{
			$oCommands | Out-GridView -Title "Redo History Commands" -PassThru | % { $Number = $_.Id }
		}

		#Write-Verbose ("{0}:Redo-History:: Number of Commands = {1}" -f $ExecutionContext.SessionState.Module, $oCommands.Count)
		if ($Number -eq 0 -or $Number -gt $oCommands.Count)
		{
			Write-Warning ("{0}:Redo-History: Invalid Id specified.  See 'Help Redo-History' for more." -f $ExecutionContext.SessionState.Module)
			Break
		}

		### Extract command(s) from history file
		[string]$sDescription = $oCommands[$Number - 1].Description
		[string]$sCommand = $oCommands[$Number - 1].CommandLine

		Write-Verbose ("{0}:Redo-History:: Command Line to Execute: {1}" -f $ExecutionContext.SessionState.Module, $sCommand)

		if ($Fake)
		{
			Invoke-FakeKey -Command $sCommand
		}
		else
		{
			Invoke-Expression $sCommand
		}
	}
}


#########################################################################################
# Invoke-FakeKey
#########################################################################################
# .ExternalHelp DevPack.Help.xml
function Invoke-FakeKey([string]$Command, [switch]$Quiet)
{
	[string]$sCommand = $Command

	### Massage command for SendKey
	$sCommand = $sCommand.Replace("{","*OpenCB*")
	$sCommand = $sCommand.Replace("}","*CloseCB*")
	$sCommand = $sCommand.Replace("+","{+}")
	$sCommand = $sCommand.Replace("%","{%}")
	$sCommand = $sCommand.Replace("^","{^}")
	$sCommand = $sCommand.Replace("(","{(}")
	$sCommand = $sCommand.Replace(")","{)}")
	$sCommand = $sCommand.Replace("[","{[}")
	$sCommand = $sCommand.Replace("]","{]}")
	$sCommand = $sCommand.Replace("*OpenCB*","{{}")
	$sCommand = $sCommand.Replace("*CloseCB*","{}}")

	### Add Carriage-Return keystroke if not confirming
	if (!$Confirm)
	{
		$sCommand = $sCommand + "~"
	}
	else
	{
		### Add a semicolon instead (for multiple redos)
		if ($Id.Count -gt 1) { $sCommand = $sCommand + "; " }
	}

	### Execute stored command ###
	if ($sDescription.Length -gt 0) { Write-Host (" ** Redo: {0}" -f $sDescription) -ForegroundColor Green }
	if (-not $Quiet) { Write-Host " ** Typing ... Please wait ... Press {ESC} to cancel **" -ForegroundColor Green }

	#ALTERNATE?#
	##$WshShell = new-object -comobject "WScript.Shell"
	##$WshShell.SendKeys($sCommand)

	[void][Reflection.Assembly]::LoadWithPartialName("System.Windows.Forms")
	[System.Windows.Forms.SendKeys]::SendWait("$sCommand")
}


#########################################################################################
# Get-AgeTimeStamps
#########################################################################################
# .ExternalHelp DevPack.Help.xml
function Get-AgeTimeStamps
{
	[CmdletBinding()]
	param(
		[Parameter(Mandatory=$false, ValueFromPipeline=$true)]
		[object]$Objects,
		[int]$Top = 100,
		[object]$Property = "",
		[int]$MinutesAgo = 60,
		[int]$Padding = 55,
		[string]$Label = "",
		[switch]$LongForm,
		[switch]$ShortForm,
		[switch]$RawOutput,
		[switch]$AlertsOnly,
		[switch]$AlertCount,
		[switch]$ExcludeAlerts,
		[switch]$PassThru
	)

	[int]$iAlertCount = 0

	[string]$sLabel = ""
	if ($Label -ne "")
	{ $sLabel = $Label }


	if ($Property -eq "")
	{
		$Property = "DateTime"
		if ($_.LastWriteTimeUtc -ne "")
		{
			$Property = "LastWriteTimeUtc"
		}
	}

	$input | Sort-Object -Property $Property -Descending | Select-Object -First $Top `
		| ForEach-Object { `

			if ($_ -eq $null -or $_ -eq "") { Continue }

			if ($_.GetType().Name.Equals("DateTime") -or $_.GetType().Name.Equals("String"))
			{ [datetime]$oTimeStampUTC = $_ }
			else
			{ [datetime]$oTimeStampUTC = $_.$Property }

			### Determine time ago or in
			[bool]$bInFuture = $false
			[object]$oTimeStampLocal = (Get-Date) - $oTimeStampUTC.ToLocalTime()
			if ($oTimeStampLocal.Ticks -lt 0)
			{
				$bInFuture = $true
				$oTimeStampLocal = $oTimeStampUTC.ToLocalTime() - (Get-Date)
			}


			### Assess Age Intensity
			[string]$sColor = "Green"
			if ($oTimeStampLocal.TotalMinutes -gt $MinutesAgo)
			{
				$sColor = "Yellow"
				if ($oTimeStampLocal.TotalMinutes -gt ($MinutesAgo * 2))
				{ $sColor = "Red" }
			}

			[string]$sName = ""
			if ($_.Name -ne $null)
			{
				if ($Label -eq "")
				{ $sLabel = $_.Name }
				else
				{ $sName = "{0}" -f $_.Name }
			}


			if ($RawOutput)
			{
				if (-not ($sColor -eq "Red" -and $ExcludeAlerts)) { $oTimeStampLocal }
			}
			else
			{
				if ($oTimeStampUTC -eq [datetime]::MinValue -or $oTimeStampUTC -eq [datetime]::MaxValue)
				{
					$sOutput = "{0}(No Date)" -f ($sLabel + " " + $sName).PadRight($Padding)
				}
				else
				{
					### Create output
					if ($ShortForm)
					{
						$sOutput = ( "{0}@ {1:HH:mm MM/dd} - {2} {3:00}:{4:00}:{5:00}{6}" -f
							($sLabel + " " + $sName).PadRight($Padding),
							$oTimeStampUTC,
							$oTimeStampLocal.Days,
							$oTimeStampLocal.Hours,
							$oTimeStampLocal.Minutes,
							$oTimeStampLocal.Seconds,
							$(if (-not $bInFuture) {"-"}) )
					}
					else
					{
						if ($LongForm)
						{
							$sOutput = ( "{0}@ {1:HH:mm:ss yyyy/MM/dd} - {2} Days, {3} Hrs, {4} Mins, {5} Secs {6}" -f
								($sLabel + " " + $sName).PadRight($Padding),
								$oTimeStampUTC,
								$oTimeStampLocal.Days,
								$oTimeStampLocal.Hours,
								$oTimeStampLocal.Minutes,
								$oTimeStampLocal.Seconds,
								$(if ($bInFuture) {"from now"} else {"ago"}) )
						}
						else
						{
							$sOutput = ( "{0}@ {1:HH:mm yy/MM/dd} - {2} Days, {3} Hrs, {4} Mins {5}" -f
								($sLabel + " " + $sName).PadRight($Padding),
								$oTimeStampUTC,
								$oTimeStampLocal.Days,
								$oTimeStampLocal.Hours,
								$oTimeStampLocal.Minutes,
								$(if ($bInFuture) {"from now"} else {"ago"}) )
						}
					}
				}

				if ($sColor -eq "Red")
				{
					$iAlertCount++
					if ($ExcludeAlerts) { continue }
				}

				if (-not $AlertsOnly -or $sColor -eq "Red")
				{
					### Output
					if (!$PassThru)
						{ Write-Host $sOutput -ForegroundColor $sColor }
					else
						{ $sOutput }
				}
			}
		}

	if ($AlertCount) { $iAlertCount }
}


#########################################################################################
# Trace-Time
#########################################################################################
# .ExternalHelp DevPack.Help.xml
function Trace-Time
{
	param
	(
		[int]$Id = 0,
		[switch]$Quiet
	)

	begin
	{
		[datetime]$oStart = (Get-Date)
		[datetime]$oEnd = [DateTime]::MaxValue
	}

	process
	{
		if ($_ -eq $null)
		{
			$oHistory = $(if ($Id -eq 0) { Get-History -Count 1 } else { Get-History -Id:$Id })
			$oStart = $oHistory.StartExecutionTime
			$oEnd = $oHistory.EndExecutionTime

			if (-not $Quiet)
			{
				Write-Host
				Write-Host ("PS {0}> {1}" -f $Id, $oHistory.CommandLine) -ForegroundColor Green
			}
		}
		else
		{
			$_
		}
	}

	end
	{
		if ($oEnd -eq [DateTime]::MaxValue) { $oEnd = (Get-Date) }

		$oEnd - $oStart

		if (-not $Quiet)
		{
			[timespan]$oElapsed = ($oEnd - $oStart)
			Write-Host (" **       Started : {0:yyyy-MM-dd HH:mm:ss.fff}" -f $oStart) -ForegroundColor Green
			Write-Host (" **     Completed : {0:yyyy-MM-dd HH:mm:ss.fff}" -f $oEnd) -ForegroundColor Green
			Write-Host (" **  Elapsed time : {0} ({1})" -f $oElapsed, (ConvertFrom-Milliseconds $oElapsed.TotalMilliseconds -IncludeSeconds -IncludeMilliseconds)) -ForegroundColor Green
		}
	}
}

#endregion

#region Basic Tools

#########################################################################################
# Set-OPENV
#########################################################################################
# .ExternalHelp DevPack.Help.xml
function Set-OPENV([string]$OP = $DevPackConfig.Operation, [string]$ENV = $DevPackConfig.Environment, [switch]$Quiet)
{
	"{0}/{1}" -f $OP, $ENV | Out-File -FilePath $DevPackConfig.OPENVFilePath -Force

	$DevPackConfig.Operation = $OP
	$DevPackConfig.Environment = $ENV
}


#########################################################################################
# Get-BuildWeek - Determine the build week
#########################################################################################
# .ExternalHelp DevPack.Help.xml
function Get-BuildWeek
{
    [object]$oCal = New-Object -Type Globalization.GregorianCalendar -ArgumentList Localized
    [string]$sWOY = $oCal.GetWeekOfYear((Get-Date), [Globalization.CalendarWeekRule]::FirstFourDayWeek, [DayOfWeek]::Monday);

    return ("{0}{1}" -f ((Get-Date).Year).ToString().SubString(2,2), $sWOY.PadLeft(2,"0"))
}


#########################################################################################
# Get-DateFromBuildWeek
#########################################################################################
# .ExternalHelp DevPack.Help.xml
function Get-DateFromBuildWeek([string]$BuildWeek)
{
	[int]$iYear = "20" + $BuildWeek.Substring(0,2)
	[int]$iWeek = $BuildWeek.Substring(2,2)
    [object]$oCal = New-Object -Type Globalization.GregorianCalendar -ArgumentList Localized

	[int]$iMonth = -1
	for ([DateTime]$dt = [datetime]"1/1/$iYear"; $dt.Year -eq $iYear; $dt = $dt.AddDays(1))
	{
		if ($oCal.GetWeekOfYear($dt, [Globalization.CalendarWeekRule]::FirstFourDayWeek, [DayOfWeek]::Monday) -eq $iWeek ) 
		{
			return ([datetime]"$($dt.Month)/1/$($iYear)")
		}
	}
	$null
}


#########################################################################################
# Pop-Repo
#########################################################################################
# .ExternalHelp DevPack.Help.xml
function Pop-Repo
{
	Set-Location $DevPackConfig.RepoRoot
}


#########################################################################################
# Set-Repo
#########################################################################################
# .ExternalHelp DevPack.Help.xml
function Set-Repo
{
	param
	(
		[string]$Path = (Get-Location).Path
	)

	$DevPackConfig.RepoRoot = $Path
}


#########################################################################################
# Use-DevPack
#########################################################################################
# .ExternalHelp DevPack.Help.xml
function Use-DevPack
{
	param
	(
		[string]$Command = "",
		[switch]$Grid
	)

	if ($Command.Length -gt 0)
	{
		Write-Host ("{0}:Use-DevPack:: Launching command helper for {1}" -f $ExecutionContext.SessionState.Module.Name, $Command) -ForegroundColor Green
		Show-Command $Command
	}
	else
	{
		Use-Module -Module DevPack -Noun $Features -List:$($Grid -eq $false)
	}
}

#endregion

#region Misc Aliases

Set-Alias -Name _        -Value Redo-History
Set-Alias -Name ...      -Value Pop-Repo
Set-Alias -Name IE       -Value Open-IE
Set-Alias -Name Verbose  -Value Set-Verbose
Set-Alias -Name Prompt   -Value Use-Prompt

Set-Alias -Name Status    -Value Show-Git
Set-Alias -Name Add       -Value Add-Git
Set-Alias -Name Remove    -Value Remove-Git
Set-Alias -Name Commit    -Value Submit-Git
Set-Alias -Name Pull      -Value Request-Git
Set-Alias -Name Push      -Value Push-Git
Set-Alias -Name DiffTool  -Value Compare-Git
Set-Alias -Name Undo      -Value Undo-Git
Set-Alias -Name MergeTool -Value Merge-Git
Set-Alias -Name Resolve   -Value Resolve-Git

Set-Alias -Name Build    -Value .\build-all.ps1
Set-Alias -Name Update   -Value .\update-sensitive-data.ps1
Set-Alias -Name Sync     -Value .\site-staticcopy-formspublic.ps1

Set-Alias -Name Use      -Value Use-DevPack
Set-Alias -Name Elapsed  -Value Trace-Time

Set-Alias -Name Shelves  -Value Open-Shelf
Set-Alias -Name Shelve   -Value Push-Shelf
Set-Alias -Name UnShelve -Value Pop-Shelf

Set-Alias -Name Search   -Value Find-InFiles
Set-Alias -Name Tail     -Value Watch-Tail

Set-Alias -Name New      -Value New-Object

#endregion

Export-ModuleMember -Function * -Alias *

#region IF MISSING REQUIRED ENVIRONMENT SETTINGS do First-time Setup (Profile Creation)
if (-not (Test-Path $profile -PathType Leaf))
{
	if ($ExecutionContext.Host.Name -ne "Windows PowerShell ISE Host" -and $ExecutionContext.Host.Name -ne "ConsoleHost")
	{
		Write-Warning ("{0}:Setup:: Running under unrecognized host environment." -f $ExecutionContext.SessionState.Module)
	}

	### Ensure we create the non-ISE profile
	[string]$sProfilePath = $profile.Replace("PowerShellISE_", "PowerShell_")

    ### Create needed profile with the default configuration
    Write-Host ("{0}:Setup:: Creating PowerShell initialization script..." -f $ExecutionContext.SessionState.Module) -ForegroundColor Yellow
	if ($ExecutionContext.Host.Name -eq "Windows PowerShell ISE Host" -and (Test-Path $sProfilePath -PathType Leaf))
	{
		### NOTE: This is for backward compatibility, usually this is done on first-time import, but this time we are
		### Running in the ISE with no profile, so link the profile up for next time
		Write-Host ("{0}:Setup:: Linking ISE to original..." -f $ExecutionContext.SessionState.Module) -ForegroundColor Yellow
		[string]$sRegProfile = $profile.Replace("PowerShellISE_", "PowerShell_")
		Invoke-Expression ("CMD /C MKLINK {0} {1}" -f $profile, $sRegProfile)
	}
	else
	{
		### Create regular profile and link ISE profile to original
		try
		{
			### Create the module directory
			New-Item -Path ([IO.Path]::GetDirectoryName($sProfilePath)) -ItemType Container -ErrorAction SilentlyContinue | Out-Null

			### Create the default profile
			Write-Output "cd '$($PSScriptRoot)'; ipmo .\DevPack.psm1; if (Test-Path `$DevPackConfig.MyProfile) { . `$DevPackConfig.MyProfile }" | Out-File $sProfilePath -Encoding ascii

			### Point ISE profile to new profile
			[string]$sISEProfilePath = $sProfilePath.Replace("PowerShell_", "PowerShellISE_")
			if (-not (Test-Path $sISEProfilePath -PathType Leaf))
			{
				Write-Host ("{0}:Setup:: Linking ISE to original..." -f $ExecutionContext.SessionState.Module) -ForegroundColor Yellow
				Invoke-Expression ("CMD /C MKLINK {0} {1}" -f $sISEProfilePath, $sProfilePath)
			}

			### Hook Module into PowerShell's default module folder
			#[string]$sModuleFolder = ("""{0}\Documents\WindowsPowerShell\Modules\{1}""" -f $HOME, $ExecutionContext.SessionState.Module)
			#if (-not (Test-Path $sModuleFolder -PathType Container))
			#{
			#	Write-Host ("{0}:Setup:: Linking module folder Repo..." -f $ExecutionContext.SessionState.Module) -ForegroundColor Yellow
			#	Invoke-Expression ("CMD /C MKLINK /D ""{0}"" ""{1}""" -f $sModuleFolder, $PSScriptRoot)
			#}

			# Execute PowerShell initialization script
			Write-Host ("{0}:Setup:: Loading new initialization script..." -f $ExecutionContext.SessionState.Module) -ForegroundColor Yellow
			Write-Host
			. $profile
		}
		catch
		{
			Write-Warning ("Import-CorePreferences:: ERROR: DevPack:: An error occurred creating initialization script.  {0} {1} {2}" -f $_, $_.InvocationInfo.ScriptStackTrace, $_.InvocationInfo.PositionMessage)
		}
	}
}
#endregion
else
#region OTHERWISE do Normal Startup Initialization
{
	### Set up HOME variable for WPS authentication
	$ENV:HOME = Resolve-Path ~

	### Set up global configuration for DevPack
	[object]$global:DevPackConfig = New-Object -TypeName PSObject | Select-Object `
		"Version",              ### Version [string]
		"Features",             ### List of features (PowerShell Nouns) [string[]]
		"RepoRoot",             ### Repository Root [string]
		"RepoName",             ### Operations Codebase [string]
		"Operation",
		"Environment",
		"MyProfile",            ### Startup Script to set preferences and such...
		"OPENVFilePath",        ### Operation/Environment file path [string]
		"AutoSyncLog",          ### AutoSync log file path [string]
		"EnableDevPackPrompt",  ### Prompt::Preference: Whether DevPack prompt is displayed [bool]
		"DevPackPromptTemplate" ### Prompt::Preference: DevPack prompt format (See Prompt function below for more) [string]

	### Set DevPack defaults
	$DevPackConfig.Version = $Version
	$DevPackConfig.Features = $Features
	$DevPackConfig.RepoRoot = $PSScriptRoot

	### Default preferences (Override this in your $profile)
	$DevPackConfig.OPENVFilePath = "c:\windows\temp\Set-OPENV.txt"
	$DevPackConfig.AutoSyncLog = "c:\windows\temp\Start-AutoSync.log"
	$DevPackConfig.MyProfile = "$($ENV:HOME)\profile.ps1"
	$DevPackConfig.EnableDevPackPrompt = $true
	#$DevPackConfig.DevPackPromptTemplate = "@!NewLine!@@!LoginName!@@@!ComputerName!@ @!Location!@ (@!RepoName!@@!Changes!@) - @!Operation!@/@!Environment!@@!NewLine!@[@!BuildWeek!@/@!TimeStamp!@] "
	$DevPackConfig.DevPackPromptTemplate = "@!NewLine!@@!Operation!@@@!Environment!@ @!Location!@ (@!RepoName!@@!Changes!@)@!NewLine!@[@!BuildWeek!@/@!TimeStamp!@] "

	Write-Host ("{0}:Init:: Version {1} Developer Tool Pack ({2:MMM yyyy})" -f $ExecutionContext.SessionState.Module, $DevPackConfig.Version, (Get-DateFromBuildWeek ($DevPackConfig.Version.Split("."))[2])) -ForegroundColor Green

	### Show prompt settings
	Set-Prompt -Show

	Write-Host
	Write-Host "Run 'use' to display the available DevPack commands."
	Write-Host "Run 'use <command>' for assistance running a DevPack command."
	Write-Host "Run 'git help git' to display the help index."
	Write-Host "Run 'git help <command>' to display help for specific commands."
	Write-Host

	### Launch Auto-Sync
	Start-AutoSync | Out-Null

	### Set initial operation / environment
	Set-OPENV -OP "Local" -ENV "Dev"

	### Instantiate SSH-Agent
	if ($($ENV:PATH -split ';') -notcontains "$(${ENV:ProgramFiles(x86)})\git\bin") { $ENV:PATH += ";$(${ENV:ProgramFiles(x86)})\git\bin" }
	. "$($DevPackConfig.RepoRoot)\ssh-agent-utils.ps1"
}
#endregion