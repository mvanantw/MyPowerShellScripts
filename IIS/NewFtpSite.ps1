[CmdletBinding()]
Param(
    [Parameter(Mandatory=$True,Position=1)]
    [string]$FtpSiteName='FTPSite',
	
    [Parameter(Mandatory=$True)]
    [string]$FtpRootPath,

    [Parameter(Mandatory=$True)]
    [string]$FtpUserName,

    [Parameter(Mandatory=$True)]
    [string]$ftpUserPath
)

# Create FTP Folder
if ((Test-Path $FtpRootPath) -eq $false) {
    Write-Verbose -Message "Creating folder $FtpRootPath"
    New-Item -Path $FtpRootPath -ItemType Directory
}

# Create FtpSite
if ((Get-Website -Name $FtpSiteName) -eq $null) {
    Write-Verbose -Message "Creating new FTP Site."
    New-WebFtpSite -Name $FtpSiteName -Port 21 -IPAddress '*' -PhysicalPath $FtpRootPath
} else {
    Write-Error -Message "$FtpSiteName already exists!"
}

# Make localuser virtual directory
if ((Get-WebVirtualDirectory -name 'LocalUser') -eq $null) {
    Write-Verbose -Message "Creating LocalUser virtual directory for user isolation."
    New-WebVirtualDirectory -Site $FtpSiteName -Name 'LocalUser' -PhysicalPath $FtpRootPath
} else {
    Write-Error -Message "Virtual directory 'LocalUser' at $FtpSiteName already exists!"
}

# Make FtpUser Virtual Directory
if ((Get-WebVirtualDirectory -name "LocalUser/$FtpUserName") -eq $null) {
    Write-Verbose -Message "Creating LocalUser/$FtpUserName virtual directory for user isolation."
    New-WebVirtualDirectory -Site "$FtpSiteName\localuser" -Name $FtpUserName -PhysicalPath $ftpUserPath
    #Start-Sleep -Seconds 5
} else {
    Write-Error -Message "Virtual directory $FtpUserName at $FtpSiteName already exists!"
}

# Configure FTP Authorization rule for FtpUser Virtual Directory 
Write-Verbose -Message "Configuring authorization rule for LocalUser/$FtpUserName virtual directory."
Remove-WebConfigurationProperty  -pspath 'MACHINE/WEBROOT/APPHOST' -location "$FtpSiteName/LocalUser/$FtpUserName" -filter "system.ftpServer/security/authorization" -name "." -AtElement @{users='*';roles='';permissions='1'}
Add-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST' -location "$FtpSiteName/LocalUser/$FtpUserName" -filter "system.ftpServer/security/authorization" -name "." -value @{accessType='Allow';users='*';permissions='Read,Write'}