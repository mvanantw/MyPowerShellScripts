<#
.Synopsis
   Remove files from a folder that are older then X days.
.DESCRIPTION
   This script can be used to remove files from the system that are older then X days.
.PARAMETER Path <string>
   This is the path to the folder with the files you want to remove.
.PARAMETER Days <int>
   With this parameter you specify how old the files have to be before the files are removed.
.PARAMETER Filter <string>
   Enter a file extension to only remove files with that file extension. For example *.log. You can use *.* to remove all files.
.PARAMETER Recurse <switch>
   Use this switch if you also want to remove files from subfolders.
.EXAMPLE   
   Remove-FilesOlderThenNumberOfDays.ps1 -Path C:\logs -Days 30 -Filter *.log -Recurse
   Remove all *.log files from the folder c:\log and subfolders that are older then 30 days.
.EXAMPLE
   Remove-FilesOlderThenNumberOfDays.ps1 -Path C:\temp -Days 90 -Filter *.* 
   Remove all files from the folder c:\temp that are older then 90 days.
#>
[CmdletBinding()]
Param
(
    [ValidateScript({IF (Test-Path $_ -PathType 'Container') {$true} Else {Throw "Path $_ is not a valid path!"}})]
    [Parameter(Mandatory=$true,
                ValueFromPipelineByPropertyName=$true)]
    [string]$Path,

    [ValidateRange(0,[int]::MaxValue)]
    [Parameter(Mandatory=$true,
                ValueFromPipelineByPropertyName=$false)]
    [int]$Days,

    [Parameter(Mandatory=$true,
                ValueFromPipelineByPropertyName=$false)]
    [string]$Filter,

    [Parameter(Mandatory=$false,
                ValueFromPipelineByPropertyName=$false)]
    [switch]$Recurse
)

Begin
{
    $command = "Get-ChildItem -path $path -filter $filter"

    if ($Recurse)
    {
        $command = $command + " -Recurse"
    }

    $command = $command + " | Where-Object {`$_.LastWriteTime -lt (get-date).AddDays(-$days)}"

    Write-Verbose "Collecting files with command: $command"
    $files = Invoke-Expression $command
}

Process
{
    if ($files -ne $null)
    {   
        Write-Verbose "Start removing $filter files from $path older then $days days."  
        $files | Remove-Item
        Write-Verbose "Finished removing $($files.count) files."
    }
    else
    {
        Write-Verbose "Nothing Removed. No $filter files found in $path or older then $days days for removal."
    }

}