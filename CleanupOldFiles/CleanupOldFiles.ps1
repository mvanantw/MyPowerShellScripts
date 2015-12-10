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
function Compress-FileOlderThenNumberOfDays
{
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true)]
        [string]$Path,

        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$false)]
        [int]$Age,

        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$false)]
        [string]$Filter='',

        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$false)]
        [switch]$Recurse
    )

    Begin
    {
    }
    Process
    {
    }
    End
    {
    }
}

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
function Remove-FilesOlderThenNumberOfDays
{
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

        [ValidateSet("*.log","*.done","*.zip")]
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
            $files | Remove-Item -WhatIf
            Write-Verbose "Finished removing $($files.count) files."
        }
        else
        {
            Write-Verbose "Nothing Removed. No $filter files found in $path or older then $days days for removal."
        }

    }
    End
    {
    }
}

Remove-FilesOlderThenNumberOfDays -Path E:\logs -Days 30 -Filter *.log -Recurse -Verbose