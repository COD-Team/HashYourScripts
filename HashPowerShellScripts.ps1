<#
    .DESCRIPTION
    Protecting File Integrity is critical in today’s environment, this script will 
    hash of all your scripts and compare regularly for changes

    .OUTPUTS
    Text file - $MasterScript\HashDelta.txt    
    Screen - Ensure Command Prompt Window is full width or maximized
        
        SideIndicator 
        <= $ReferenceHash.csv
        => #DifferenceHash.csv (Indicates Changes or New File not included in $ReferenceHash.csv
    
    .EXAMPLE
        1. PowerShell 5.1 Command Prompt (Admin) 
            "powershell -Executionpolicy Bypass -File PATH\FILENAME.ps1"
        2. Powershell 7.2.1 Command Prompt (Admin) 
            "pwsh -Executionpolicy Bypass -File PATH\FILENAME.ps1"
    
    Updating Master ReferenceHash.csv, if you are confident with changes, delete the file and it will be recreated
    next time script is executed. 
        
    .NOTES
        Author Perkins
        Last Update 1/8/22
    
        Powershell 5 or higher
        Run as Administrator

        Powershell Extensions
            .ps1 (Script)
            .ps1xml (XML Document)
            .psc1 (Console File)
            .psd1 (Data File)
            .psm1 (Script Module)
            .pssc (Session Configuration File)
            .psrc (Role Capability File)
            .cdxml (Cmdlet Definition XML Document)
    
    .FUNCTIONALITY
        PowerShell Language
        Active Directory
    
    .Link
        https://github.com/COD-Team
        YouTube Video https://youtu.be/4LSMP0gj1IQ

#>

# Location of the MasterScripts
$MasterScripts = '\\DC2016\Shares\MasterScripts'

# File Extensions we are Hashing in the $MasterScript Folder
$ExtensionList = @('*.ps1*', '*.ps1xml*', '*.psc1*', '*psd1*', '*psm1*', '*pssc*', '*psrc*', '*cdxml*')

# Location of the ReferenceHash File, When approved changes happen, copy Manually copy DifferenceHash to ReferenceHash
# Location should be readonly unless you require updating this file
$ReferenceHash = '\\DC2016\Shares\ReferenceHash.csv'

# This file will be archived and recreated each time you execute
$DifferenceHash = '\\DC2016\Shares\MasterScripts\DifferenceHash.csv'

# Path for the Archived Hash Files
$ArchiveHash = "\\DC2016\Shares\ArchiveHash\$(get-date -format "yyyyMMdd-hhmmss")"

# Added 1/7/21 PowerShell 7.2.1 Compatibility for Out-File not printing escape characters
if ($PSVersionTable.PSVersion.major -ge 7) {$PSStyle.OutputRendering = 'PlainText'} 

# Tests for the DifferenceHash.csv, if exsist will move to Archives
if (Test-Path $DifferenceHash) 
    {
        If(-Not(test-path $ArchiveHash))
    {
          New-Item -ItemType Directory -Force -Path $ArchiveHash
    }
        move-Item -Path $DifferenceHash -Destination $ArchiveHash -Force -ErrorAction SilentlyContinue
        move-Item -Path $MasterScripts\HashDelta.txt -Destination $ArchiveHash -Force -ErrorAction SilentlyContinue
        if (Test-Path $ReferenceHash) {Copy-Item -Path $ReferenceHash -Destination $ArchiveHash}
        Write-Output "$DifferenceHash has been Archived." | Out-File $MasterScripts\HashDelta.txt -Append
        Write-Output "$MasterScripts\HashDelta.txt has been Archived." | Out-File $MasterScripts\HashDelta.txt -Append
        Write-Output "$ReferenceHash has been Archived." | Out-File $MasterScripts\HashDelta.txt -Append
    }

# Returns all files based on the $MasterScripts path and $ExtensionList
$FileNames = Get-ChildItem -Path $MasterScripts -Recurse -Include $ExtensionList | Select-Object FullName

# Based on each $FileName, calculates Hash values
    Foreach ($Filename in $FileNames.FullName)
    {
        $Results = Get-ChildItem -Path $FileName | Get-FileHash
        $Results | Select-Object Algorithm, Hash, Path | Export-Csv -Path $MasterScripts\DifferenceHash.csv -Append -NoTypeInformation
    }
# If the ReferenceHash.csv does not exist, it will create from the current $DifferenceHash Take Note in the Report.
if (-Not(Test-Path $ReferenceHash)) 
{
    Copy-Item -Path $DifferenceHash -Destination $ReferenceHash
    Write-Output "******* New Reference $ReferenceHash File Created! *******" | Out-File $MasterScripts\HashDelta.txt -Append
}

# Compares the Master $ReferenceHash.csv to new $DifferenceHash    
$objects = @{
    ReferenceObject = (Get-Content -Path $ReferenceHash)
    DifferenceObject = (Get-Content -Path $DifferenceHash)
  }

Compare-Object @objects | Format-Table
Compare-Object @objects | Format-Table | Out-File $MasterScripts\HashDelta.txt -Append

Start-Process notepad.exe $MasterScripts\HashDelta.txt -NoNewWindow