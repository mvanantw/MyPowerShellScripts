#requires -Version 3 -Modules WebAdministration -RunAsAdministrator
<#
.Synopsis
   This script create a new FTP Virtual Directory for the ftp user in the Ftp Site.
.DESCRIPTION
   This script create a new FTP Virtual Directory for the ftp user in the Ftp Site.
.EXAMPLE
   NewFtpUserVdir.ps1
#>
[CmdletBinding()]
Param(
    [Parameter(Mandatory=$True,Position=1)]
    [string]$FtpSiteName='FTPSite',

    [Parameter(Mandatory=$True)]
    [string]$FtpUserName,

    [Parameter(Mandatory=$True)]
    [string]$ftpUserPath
)
# Make FtpUser Virtual Directory
Write-Verbose -Message "---------- FTP User Virtual Directory ----------"
if ((Get-WebVirtualDirectory -name "LocalUser/$FtpUserName") -eq $null) {
    Write-Verbose -Message "Creating LocalUser/$FtpUserName virtual directory for user isolation."
    New-WebVirtualDirectory -Site "$FtpSiteName\localuser" -Name $FtpUserName -PhysicalPath $ftpUserPath
    #Start-Sleep -Seconds 5
} else {
    Write-Error -Message "Virtual directory $FtpUserName at $FtpSiteName already exists!"
}

# Configure FTP Authorization rule for FtpUser Virtual Directory
Write-Verbose -Message "---------- FTP User Folder Authorization Rule ----------" 
Write-Verbose -Message "Configuring authorization rule for LocalUser/$FtpUserName virtual directory."
Remove-WebConfigurationProperty  -pspath 'MACHINE/WEBROOT/APPHOST' -location "$FtpSiteName/LocalUser/$FtpUserName" -filter "system.ftpServer/security/authorization" -name "." -AtElement @{users='*';roles='';permissions='1'}
Add-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST' -location "$FtpSiteName/LocalUser/$FtpUserName" -filter "system.ftpServer/security/authorization" -name "." -value @{accessType='Allow';users='*';permissions='Read,Write'}
