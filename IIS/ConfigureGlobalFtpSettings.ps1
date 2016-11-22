

# configure Global Basic Authentication Provider
Set-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST'  -filter "system.applicationHost/sites/siteDefaults/ftpServer/security/authentication/basicAuthentication" -name "enabled" -value "True"

# Set FTP Authorization Rule
Add-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST'  -filter "system.ftpServer/security/authorization" -name "." -value @{accessType='Allow';users='*';permissions='Read'}

# Configure Global FTP SSL Settings
Set-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST'  -filter "system.applicationHost/sites/siteDefaults/ftpServer/security/ssl" -name "serverCertStoreName" -value "WebHosting"
Set-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST'  -filter "system.applicationHost/sites/siteDefaults/ftpServer/security/ssl" -name "controlChannelPolicy" -value "SslAllow"
Set-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST'  -filter "system.applicationHost/sites/siteDefaults/ftpServer/security/ssl" -name "dataChannelPolicy" -value "SslAllow"

# Configure Global FTP Firewall Support
Set-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST'  -filter "system.ftpServer/firewallSupport" -name "lowDataChannelPort" -value 6000
Set-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST'  -filter "system.ftpServer/firewallSupport" -name "highDataChannelPort" -value 7000

# Configure Global FTP Logging
Set-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST'  -filter "system.ftpServer/log" -name "centralLogFileMode" -value "Site"
Set-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST'  -filter "system.ftpServer/log/centralLogFile" -name "logExtFileFlags" -value "Date,Time,ClientIP,UserName,SiteName,ComputerName,ServerIP,Method,UriStem,FtpStatus,Win32Status,BytesSent,BytesRecv,TimeTaken,ServerPort,Host,FtpSubStatus,Session,FullPath,Info,ClientPort,PhysicalPath"
Set-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST'  -filter "system.ftpServer/log/centralLogFile" -name "directory" -value "C:\inetpub\logs\logfiles\"
Set-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST'  -filter "system.ftpServer/log/centralLogFile" -name "period" -value "Daily"
Set-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST'  -filter "system.ftpServer/log/centralLogFile" -name "localTimeRollover" -value "True"

# Configure Global FTP User Isolation
Set-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST'  -filter "system.applicationHost/sites/siteDefaults/ftpServer/userIsolation" -name "mode" -value "IsolateAllDirectories"


