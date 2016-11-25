<#
.Synopsis
   This script configures some global FTP Settings.
.DESCRIPTION
   This script configures some global FTP Settings. It configfures Authentication Providers, Authorization Rules, SSL Setting, Firewall Support, Logging , User Isolation
.EXAMPLE
   ConfigureGlobalFtpSettings.ps1
#>
[CmdletBinding()]
Param ()

# Configure authorization providers
Write-Verbose -Message "---------- Authentication Providers ----------"
Write-Verbose "Setting AuthenticationProvider basicAuthentication to enabled"
Set-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST'  -filter "system.applicationHost/sites/siteDefaults/ftpServer/security/authentication/basicAuthentication" -name "enabled" -value "True"
Write-Verbose "Setting AuthenticationProvider anonymousAuthentication to disabled"
Set-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST'  -filter "system.applicationHost/sites/siteDefaults/ftpServer/security/authentication/anonymousAuthentication" -name "enabled" -value "False"

# Set FTP Authorization Rule
Write-Verbose -Message "---------- FTP Authorization Rules ----------"
Write-Verbose -Message "Creating new FTP Authorization rule."
Add-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST'  -filter "system.ftpServer/security/authorization" -name "." -value @{accessType='Allow';users='*';permissions='Read,Write'}

# Configure Global FTP SSL Settings
Write-Verbose -Message "---------- FTP SSL Settings ----------"
Set-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST'  -filter "system.applicationHost/sites/siteDefaults/ftpServer/security/ssl" -name "serverCertStoreName" -value "WebHosting"
Set-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST'  -filter "system.applicationHost/sites/siteDefaults/ftpServer/security/ssl" -name "controlChannelPolicy" -value "SslAllow"
Set-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST'  -filter "system.applicationHost/sites/siteDefaults/ftpServer/security/ssl" -name "dataChannelPolicy" -value "SslAllow"

# Configure Global FTP Firewall Support
Write-Verbose -Message "---------- FTP Firewall Support ----------"
Set-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST'  -filter "system.ftpServer/firewallSupport" -name "lowDataChannelPort" -value 6000
Set-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST'  -filter "system.ftpServer/firewallSupport" -name "highDataChannelPort" -value 7000

# Configure Global FTP Logging
Write-Verbose -Message "---------- FTP Logging ----------"
Set-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST'  -filter "system.ftpServer/log" -name "centralLogFileMode" -value "Site"
Set-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST'  -filter "system.ftpServer/log/centralLogFile" -name "logExtFileFlags" -value "Date,Time,ClientIP,UserName,SiteName,ComputerName,ServerIP,Method,UriStem,FtpStatus,Win32Status,BytesSent,BytesRecv,TimeTaken,ServerPort,Host,FtpSubStatus,Session,FullPath,Info,ClientPort,PhysicalPath"
Set-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST'  -filter "system.ftpServer/log/centralLogFile" -name "directory" -value "C:\inetpub\logs\logfiles\"
Set-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST'  -filter "system.ftpServer/log/centralLogFile" -name "period" -value "Daily"
Set-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST'  -filter "system.ftpServer/log/centralLogFile" -name "localTimeRollover" -value "True"

# Configure Global FTP User Isolation
Write-Verbose -Message "---------- FTP User Isolation ----------"
Set-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST'  -filter "system.applicationHost/sites/siteDefaults/ftpServer/userIsolation" -name "mode" -value "IsolateAllDirectories"
