#requires -Version 3 -Modules WebAdministration -RunAsAdministrator
<#
.Synopsis
   This script create a new FTP site on the server.
.DESCRIPTION
   This script create a new FTP site on the server.
.EXAMPLE
   NewFtpSite.ps1
#>
[CmdletBinding()]
Param(
    [Parameter(Mandatory=$True,Position=1)]
    [string]$FtpSiteName='FTPSite',
	
    [Parameter(Mandatory=$True)]
    [string]$FtpRootPath
)

# Create FTP Folder
Write-Verbose -Message "---------- FTP Folder ----------"
if ((Test-Path $FtpRootPath) -eq $false) {
    Write-Verbose -Message "Creating folder $FtpRootPath"
    New-Item -Path $FtpRootPath -ItemType Directory
} else {
    Write-Verbose -Message "Folder $FtpRootPath already exists."
}

# Create FtpSite
Write-Verbose -Message "---------- FTP Site ----------"
if ((Get-Website -Name $FtpSiteName) -eq $null) {
    Write-Verbose -Message "Creating new FTP Site."
    New-WebFtpSite -Name $FtpSiteName -Port 21 -IPAddress '*' -PhysicalPath $FtpRootPath
} else {
    Write-Error -Message "$FtpSiteName already exists!"
}

# Make localuser virtual directory
Write-Verbose -Message "---------- FTP User Isolation ----------"
if ((Get-WebVirtualDirectory -name 'LocalUser') -eq $null) {
    Write-Verbose -Message "Creating LocalUser virtual directory for user isolation."
    New-WebVirtualDirectory -Site $FtpSiteName -Name 'LocalUser' -PhysicalPath $FtpRootPath
} else {
    Write-Error -Message "Virtual directory 'LocalUser' at $FtpSiteName already exists!"
}