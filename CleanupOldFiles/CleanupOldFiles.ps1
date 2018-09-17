<#
.Synopsis
   Short description
.DESCRIPTION
   Long description
.EXAMPLE
   Example of how to use this cmdlet
.EXAMPLE
   Another example of how to use this cmdlet
#>

function Compress-FileOlderThenNumberOfDays {
    [CmdletBinding()]
    Param
    (
        [ValidateScript( {IF (Test-Path $_ -PathType 'Container') {$true} Else {Throw "Path $_ is not a valid path or does not exist!"}})]
        [Parameter(Mandatory = $true,
            ValueFromPipelineByPropertyName = $true)]
        [string]$Path,

        [ValidateRange(0, [int]::MaxValue)]
        [Parameter(Mandatory = $true,
            ValueFromPipelineByPropertyName = $false)]
        [int]$Days,

        [Parameter(Mandatory = $true,
            ValueFromPipelineByPropertyName = $false)]
        [string]$Filter,

        [Parameter(Mandatory = $false,
            ValueFromPipelineByPropertyName = $false)]
        [switch]$Recurse
    )

    <#
    .Synopsis
    Compress files in a folder that are older then X days.
    .DESCRIPTION
    This script can be used to compress files that are older then X days.
    .PARAMETER Path <string>
    This is the path to the folder with the files you want to compress.
    .PARAMETER Days <int>
    With this parameter you specify how old the files have to be before the files are compressed.
    .PARAMETER Filter <string>
    Enter a file extension to only compress files with that file extension. For example *.log. You can use *.* to compress every file in that folder.
    .PARAMETER Recurse <switch>
    Use this switch if you also want to compress files that are in subfolders.
    .EXAMPLE
    Compress-FilesOlderThenNumberOfDays.ps1 -Path C:\logs -Days 30 -Filter *.log -Recurse
    Compress all *.log files in the folder c:\log and subfolders that are older then 30 days.
    .EXAMPLE
    Compress-FilesOlderThenNumberOfDays.ps1 -Path C:\temp -Days 90 -Filter *.*
    Compress all files in the folder c:\temp that are older then 90 days.
    #>

    $command = "Get-ChildItem -path $path -filter $filter"

    if ($Recurse) {
        $command = $command + " -Recurse"
    }

    $command = $command + " | Where-Object {`$_.LastWriteTime -lt (get-date).AddDays(-$days)}"

    Write-Verbose "Collecting files with command: $command"
    $files = Invoke-Expression $command

    if ($files -ne $null) {

        Write-Verbose "Start compressing $filter files in $path older then $days days."
        foreach ($file in $files) {
            $Destination = $($file.FullName.Replace($file.Extension, ".zip"))
            Compress-Archive -LiteralPath $($file.fullname) -DestinationPath $Destination -CompressionLevel Optimal
            Write-Verbose "Finished compressing file $($file.fullname)."

            If (Test-path $Destination) {
                Remove-Item -Path $($file.FullName)
                Write-Verbose "Removing original file $($file.FullName)"
            }
        }
        Write-Verbose "Compressed $($files.count) files in $path older then $days days."
    }
    else {
        Write-Verbose "Nothing to compress. No $filter files found in $path or older then $days days for archiving."
    }
}

function Remove-FilesOlderThenNumberOfDays {
    [CmdletBinding()]
    Param (
        [ValidateScript( {IF (Test-Path $_ -PathType 'Container') {$true} Else {Throw "Path $_ is not a valid path!"}})]
        [Parameter(Mandatory = $true,
            ValueFromPipelineByPropertyName = $true)]
        [string]$Path,

        [ValidateRange(0, [int]::MaxValue)]
        [Parameter(Mandatory = $true,
            ValueFromPipelineByPropertyName = $false)]
        [int]$Days,

        [ValidateSet("*.log", "*.done", "*.zip")]
        [Parameter(Mandatory = $true,
            ValueFromPipelineByPropertyName = $false)]
        [string]$Filter,

        [Parameter(Mandatory = $false,
            ValueFromPipelineByPropertyName = $false)]
        [switch]$Recurse
    )

    <#
    .Synopsis
    Short description
    .DESCRIPTION
    Long description
    .EXAMPLE
    Example of how to use this cmdlet
    .EXAMPLE
    Another example of how to use this cmdlet
    #>

    Begin {
        $command = "Get-ChildItem -path $path -filter $filter"

        if ($Recurse) {
            $command = $command + " -Recurse"
        }

        $command = $command + " | Where-Object {`$_.LastWriteTime -lt (get-date).AddDays(-$days)}"

        Write-Verbose "Collecting files with command: $command"
        $files = Invoke-Expression $command
    }
    Process {
        if ($files -ne $null) {
            Write-Verbose "Start removing $filter files from $path older then $days days."
            $files | Remove-Item -WhatIf
            Write-Verbose "Finished removing $($files.count) files."
        }
        else {
            Write-Verbose "Nothing Removed. No $filter files found in $path or older then $days days for removal."
        }
    }
    End {
    }
}

# Main Script
$logdirs = Get-Content $PSScriptRoot\logdirecttories.txt

foreach ($logdir in $logdirs) {
    Remove-FilesOlderThenNumberOfDays -Path $logdir -Days 60 -Filter *.zip -Recurse -Verbose
    Compress-FileOlderThenNumberOfDays -Path $logdir -Days 7 -Filter *.log -Recurse -Verbose

}
