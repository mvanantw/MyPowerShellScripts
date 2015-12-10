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
[CmdletBinding()]
Param
(
    [ValidateScript({IF (Test-Path $_ -PathType 'Container') {$true} Else {Throw "Path $_ is not a valid path or does not exist!"}})]
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

<#
.Synopsis
   Creates a new archive from a file
.DESCRIPTION
   Creates a new archive with the contents from a file. This function relies on the
   .NET Framework 4.5. On windwows Server 2012 R2 Core you can install it with 
   Install-WindowsFeature Net-Framework-45-Core
.EXAMPLE
   New-ArchiveFromFile -Source c:\test\test.txt -Destination c:\test.zip
#>
function New-ArchiveFromFile
{
    [CmdletBinding()]
    [OutputType([int])]
    Param
    (
        # Param1 help description
        [Parameter(Mandatory=$true,
                   ValueFromPipeline=$true,
                   Position=0)]
        [string]$Source,

        # Param2 help description
        [Parameter(Mandatory=$true,
                   Position=1)]
        [string]$Destination
    )

    Begin
    {
        [System.Reflection.Assembly]::LoadWithPartialName("System.IO.Compression.FileSystem") | Out-Null
    }
    Process
    {
        try
        {
            Write-Verbose -Message "Creating archive $Destination...."
            $zipEntry = "$Source" | Split-Path -Leaf
            $zipFile = [System.IO.Compression.ZipFile]::Open($Destination, 'Update')
            $compressionLevel = [System.IO.Compression.CompressionLevel]::Optimal
            [System.IO.Compression.ZipFileExtensions]::CreateEntryFromFile($zipfile,$Source,$zipEntry,$compressionLevel)
            Write-Verbose -Message "Created archive $destination."
        }
        catch [System.IO.DirectoryNotFoundException]
        {
            Write-Host -object "ERROR: The source $source does not exist!" -ForegroundColor Red
        }
        catch [System.IO.IOException]
        {
            Write-Host -object "ERROR: The file $Source is in use or $destination already exists!" -ForegroundColor Red
        }
        catch [System.UnauthorizedAccessException]
        {
            Write-Host -object "ERROR: You are not authorized to access the source or destination" -ForegroundColor Red
        }
    }
    End
    { 
        $zipFile.Dispose()
    }
}


$command = "Get-ChildItem -path $path -filter $filter"

if ($Recurse)
{
    $command = $command + " -Recurse"
}

$command = $command + " | Where-Object {`$_.LastWriteTime -lt (get-date).AddDays(-$days)}"

Write-Verbose "Collecting files with command: $command"
$files = Invoke-Expression $command


if ($files -ne $null)
{
              
    Write-Verbose "Start compressing $filter files in $path older then $days days."  
    foreach ($file in $files)
    {
        $Destination = $($file.FullName.Replace($file.Extension,".zip"))
        New-ArchiveFromFile -Source $($file.fullname) -Destination $Destination
        Write-Verbose "Finished compressing file $($file.fullname)."

        If (Test-path $Destination)
        {
            Remove-Item -Path $($file.FullName)
            Write-Verbose "Removing original file $($file.FullName)"
        }       
    }
    Write-Verbose "Compressed $($files.count) files in $path older then $days days."
}
else
{
    Write-Verbose "Nothing to compress. No $filter files found in $path or older then $days days for archiving."
}


