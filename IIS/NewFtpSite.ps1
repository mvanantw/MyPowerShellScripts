$FtpSiteName = 'FTPSite'
$FtpRootPath = 'c:\inetpub\ftproot'
$FtpUserName = 'mariova'
$ftpUserPath = 'c:\inetpub\wwwroot'

# Create FTP Folder
if ((Test-Path $FtpRootPath) -eq $false) {
    New-Item -Path $FtpRootPath -ItemType Directory
}

# Create FtpSite
if ((Get-Website -Name $FtpSiteName) -eq $null) {
    New-WebFtpSite -Name $FtpSiteName -Port 21 -IPAddress '*' -PhysicalPath $FtpRootPath
} else {
    Write-Error -Message "$FtpSiteName already exists!"
}

# Make localuser virtual directory
if ((Get-WebVirtualDirectory -name 'LocalUser') -eq $null) {
    New-WebVirtualDirectory -Site $FtpSiteName -Name 'LocalUser' -PhysicalPath $FtpRootPath
} else {
    Write-Error -Message "Virtual directory 'LocalUser' at $FtpSiteName already exists!"
}

# Make FtpUser Virtual Directory
if ((Get-WebVirtualDirectory -name "LocalUser/$FtpUserName") -eq $null) {
    New-WebVirtualDirectory -Site "$FtpSiteName\localuser" -Name $FtpUserName -PhysicalPath $ftpUserPath
    #Start-Sleep -Seconds 5
} else {
    Write-Error -Message "Virtual directory $FtpUserName at $FtpSiteName already exists!"
}

# Configure FTP Authorization rule for FtpUser Virtual Directory 
Remove-WebConfigurationProperty  -pspath 'MACHINE/WEBROOT/APPHOST' -location "FTPSite/LocalUser/$FtpUserName" -filter "system.ftpServer/security/authorization" -name "." -AtElement @{users='*';roles='';permissions='1'}
Add-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST' -location "FTPSite/LocalUser/$FtpUserName" -filter "system.ftpServer/security/authorization" -name "." -value @{accessType='Allow';users='*';permissions='Read,Write'}

