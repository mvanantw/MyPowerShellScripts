[CmdletBinding()]
param ()
$webfarm = 'test'

$starttime = get-date
#region Install web feautures
Write-Verbose -Message  "Installing IIS webserver and additional modules"
Install-WindowsFeature -Name "web-server", "Web-Http-Redirect", "Web-Stat-Compression", "Web-ISAPI-Ext", "Web-ISAPI-Filter", "Web-Http-Logging", "Web-Request-Monitor", "Web-Basic-Auth", "Web-Filtering", "Web-IP-Security", "Web-Performance", "Web-Asp", "Web-Asp-Net", "Web-Asp-Net45", "Web-Mgmt-Console", "Web-Ftp-Service"
#endregion

#region Install web pi
Write-Verbose -Message  "Installing Web Platform Installer"
choco install webpi --version 5.0 -y
#endregion

#Region Install Application and Request Routing via chocolatey
Write-Verbose -Message  "Installing Application and Request Routing"
choco install ARRv3_0 --source webpi -y
#endregion

##Blue/green setup
#region Green Website
Write-Verbose -Message  "Creating user for the green website"
New-LocalGroup -Name w3users -Description 'Group for customer account' | Out-Null
#Create user for green website
$username = 'GreenWebsite'
$password = 'P@ssw0rd'
$group = 'w3users'
$Result = Get-Localuser -Name $Username -ErrorAction SilentlyContinue
if ($null -eq $Result) {
    write-Verbose "Creating user $UserName"
    $spwd = ConvertTo-SecureString -String $Password -AsPlainText -force
    New-LocalUser -Name $Username -Password $spwd -AccountNeverExpires -PasswordNeverExpires -UserMayNotChangePassword | Out-Null

    Write-Verbose "Add $Username to group $Group"
    $GroupMember = Get-LocalUser -Name $UserName
    Add-LocalGroupMember -Group $Group -Member $GroupMember | Out-Null
}
else {
    Write-Verbose -Message "User $username already exists. Skipping this step."
}

#Create folder structure for green website
Write-Verbose -Message  "Creating folders for the green website"
New-Item -Path 'c:\inetpub\' -Name 'GreenWebsite' -ItemType Directory -Force | Out-Null
New-Item -Path 'c:\inetpub\GreenWebsite' -Name 'wwwroot' -ItemType Directory -Force | Out-Null
New-Item -Path 'c:\inetpub\GreenWebsite' -Name 'access-db' -ItemType Directory -Force | Out-Null
New-Item -Path 'c:\inetpub\GreenWebsite' -Name 'logs' -ItemType Directory -Force | Out-Null
New-Item -Path 'c:\inetpub\GreenWebsite\logs' -Name 'logfiles' -ItemType Directory -Force | Out-Null
New-Item -Path 'c:\inetpub\GreenWebsite\logs' -Name 'failedreqlogfiles' -ItemType Directory -Force | Out-Null

#Change file permissions
# TODO

#Create Green ApplicationPool
Write-Verbose -Message  "Creating application pool for the green website"
Add-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST'  -filter "system.applicationHost/applicationPools" -name "." -value @{name = 'greenAppPool'; startMode = 'AlwaysRunning'}
Set-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST'  -filter "system.applicationHost/applicationPools/add[@name='greenAppPool']/recycling/periodicRestart" -name "time" -value "00:00:00"
Add-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST'  -filter "system.applicationHost/applicationPools/add[@name='greenAppPool']/recycling/periodicRestart/schedule" -name "." -value @{value = '02:00:00'}

#Create green website port 8001
Write-Verbose -Message  "Creating the green website"
New-WebSite -Name 'GreenWebsite' -Port 8001 -HostHeader '*' -PhysicalPath 'c:\inetpub\GreenWebsite\wwwroot' -ApplicationPool 'greenAppPool' -ErrorAction Stop | Out-Null
New-Item -Path c:\inetpub\greenwebsite\wwwroot\ -Name index.html -ItemType File -Value "Green Website is active" | Out-Null

##Set webconfiguration setting
#enable anonymous authentication
Write-Verbose -Message  "Enabling anynomous authentication."
Set-WebConfigurationProperty -Filter '/system.webServer/security/authentication/anonymousAuthentication' -Name enabled -Value true -pspath 'MACHINE/WEBROOT/APPHOST' -Location 'GreenWebsite'

Write-Verbose -Message  "Setting anymous user to application pool identity."
Set-WebConfigurationProperty -Filter '/system.webServer/security/authentication/anonymousAuthentication' -Name username -Value '' -pspath 'MACHINE/WEBROOT/APPHOST' -Location 'GreenWebsite'

#enable basic authentication
Write-Verbose -Message  "Enabling basic authentication."
Set-WebConfigurationProperty -Filter '/system.webServer/security/authentication/basicAuthentication' -Name enabled -Value true -pspath 'MACHINE/WEBROOT/APPHOST' -Location 'GreenWebsite'

#set log file directory
Write-Verbose -Message  "Setting log directory to c:\inetpub\GreenWebsite\Logs\LogFiles"
Set-ItemProperty "IIS:\Sites\GreenWebsite" -name logfile.directory -value "c:\inetpub\GreenWebsite\Logs\LogFiles"
Set-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST'  -filter "system.applicationHost/sites/site[@name='GreenWebsite']/logFile" -name "localTimeRollover" -value "True"

#set FailedReqLogFiles directory
Write-Verbose -Message  "Setting FailedReqLogFiles directory to c:\inetpub\GreenWebsite\logs\FailedReqLogFiles"
Set-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST'  -filter "system.applicationHost/sites/site[@name='GreenWebsite']/traceFailedRequestsLogging" -name "directory" -value "c:\inetpub\GreenWebsite\logs\FailedReqLogFiles"
#endregion


#region Blue Website
#Create user for blue website
Write-Verbose -Message  "Creating user for the blue website"
$username = 'BlueWebsite'
$password = 'P@ssw0rd'
$group = 'w3users'
$Result = Get-Localuser -Name $Username -ErrorAction SilentlyContinue
if ($null -eq $Result) {
    write-Verbose "Creating user $UserName"
    $spwd = ConvertTo-SecureString -String $Password -AsPlainText -force
    New-LocalUser -Name $Username -Password $spwd -AccountNeverExpires -PasswordNeverExpires -UserMayNotChangePassword | Out-Null

    Write-Verbose "Add $Username to group $Group"
    $GroupMember = Get-LocalUser -Name $UserName
    Add-LocalGroupMember -Group $Group -Member $GroupMember | Out-Null
}
else {
    Write-Verbose -Message "User $username already exists. Skipping this step."
}

#Create folder structure for Blue website
Write-Verbose -Message  "Creating Folder for the blue website"
New-Item -Path 'c:\inetpub\' -Name 'BlueWebsite' -ItemType Directory -Force | Out-Null
New-Item -Path 'c:\inetpub\BlueWebsite' -Name 'wwwroot' -ItemType Directory -Force | Out-Null
New-Item -Path 'c:\inetpub\BlueWebsite' -Name 'access-db' -ItemType Directory -Force | Out-Null
New-Item -Path 'c:\inetpub\BlueWebsite' -Name 'logs' -ItemType Directory -Force | Out-Null
New-Item -Path 'c:\inetpub\BlueWebsite\logs' -Name 'logfiles' -ItemType Directory -Force | Out-Null
New-Item -Path 'c:\inetpub\BlueWebsite\logs' -Name 'failedreqlogfiles' -ItemType Directory -Force | Out-Null

#Change file permissions
# TODO

#Create Blue ApplicationPool
Write-Verbose -Message  "Creating application pool for the blue website"
Add-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST'  -filter "system.applicationHost/applicationPools" -name "." -value @{name = 'blueAppPool'; startMode = 'AlwaysRunning'}
Set-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST'  -filter "system.applicationHost/applicationPools/add[@name='blueAppPool']/recycling/periodicRestart" -name "time" -value "00:00:00"
Add-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST'  -filter "system.applicationHost/applicationPools/add[@name='blueAppPool']/recycling/periodicRestart/schedule" -name "." -value @{value = '04:00:00'}

#Create blue website port 8002
Write-Verbose -Message  "Creating the blue website"
New-WebSite -Name 'BlueWebsite' -Port 8002 -HostHeader '*' -PhysicalPath 'c:\inetpub\BlueWebsite\wwwroot' -ApplicationPool 'blueAppPool' -ErrorAction Stop  | Out-Null
New-Item -Path c:\inetpub\bluewebsite\wwwroot\ -Name index.html -ItemType File -Value "Blue Website is active" | Out-Null

##Set webconfiguration setting
#enable anonymous authentication
Write-Verbose -Message  "Enabling anynomous authentication."
Set-WebConfigurationProperty -Filter '/system.webServer/security/authentication/anonymousAuthentication' -Name enabled -Value true -pspath 'MACHINE/WEBROOT/APPHOST' -Location 'BlueWebsite'

Write-Verbose -Message  "Setting anymous user to application pool identity."
Set-WebConfigurationProperty -Filter '/system.webServer/security/authentication/anonymousAuthentication' -Name username -Value '' -pspath 'MACHINE/WEBROOT/APPHOST' -Location 'BlueWebsite'

#enable basic authentication
Write-Verbose -Message  "Enabling basic authentication."
Set-WebConfigurationProperty -Filter '/system.webServer/security/authentication/basicAuthentication' -Name enabled -Value true -pspath 'MACHINE/WEBROOT/APPHOST' -Location 'BlueWebsite'

#set log file directory
Write-Verbose -Message  "Setting log directory to c:\inetpub\GreenWebsite\Logs\LogFiles"
Set-ItemProperty "IIS:\Sites\BlueWebsite" -name logfile.directory -value "c:\inetpub\BlueWebsite\Logs\LogFiles"
Set-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST'  -filter "system.applicationHost/sites/site[@name='BlueWebsite']/logFile" -name "localTimeRollover" -value "True"

#set FailedReqLogFiles directory
Write-Verbose -Message  "Setting FailedReqLogFiles directory to c:\inetpub\BlueWebsite\logs\FailedReqLogFiles"
#endregion

#region Modify Default Application Pool settings
Write-Verbose -Message  "Modifying settings for the Default Application Pool"
Set-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST'  -filter "system.applicationHost/applicationPools/add[@name='DefaultAppPool']/processModel" -name "idleTimeout" -value "00:00:00"
Set-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST'  -filter "system.applicationHost/applicationPools/add[@name='DefaultAppPool']/recycling/periodicRestart" -name "time" -value "00:00:00"

Add-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST'  -filter "system.applicationHost/applicationPools/add[@name='DefaultAppPool']/recycling/periodicRestart/schedule" -name "." -value @{value = '00:00:00'}
Set-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST'  -filter "system.applicationHost/applicationPools/add[@name='DefaultAppPool']" -name "startMode" -value "AlwaysRunning"
#endregion


#region setup webfarm
#create webfarm
Write-Verbose -Message  "Creating the webfarm"
Add-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST'  -filter "webFarms" -name "." -value @{name = 'test'}

#Add hosts to webfarm
Write-Verbose -Message  "Adding hosts to the webfarm"
Add-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST'  -filter "webFarms/webFarm[@name='test']" -name "." -value @{address = 'GreenWebsite'}
Set-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST'  -filter "webFarms/webFarm[@name='test']/server[@address='GreenWebsite']/applicationRequestRouting" -name "httpPort" -value 8001

Add-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST'  -filter "webFarms/webFarm[@name='test']" -name "." -value @{address = 'BlueWebsite'}
Set-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST'  -filter "webFarms/webFarm[@name='test']/server[@address='BlueWebsite']/applicationRequestRouting" -name "httpPort" -value 8002

#Add up.html test file to green and blue sites
Write-Verbose -Message  "Creating up.html for the healthcheck"
New-Item -Path c:\inetpub\greenwebsite\wwwroot\ -Name up.html -ItemType File -Value up | Out-Null
New-Item -Path c:\inetpub\bluewebsite\wwwroot\ -Name up.html -ItemType File -Value down | Out-Null

#Add health check to webfarm
Write-Verbose -Message  "Creating the Health check for the webfarm"
Set-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST'  -filter "webFarms/webFarm[@name='test']/applicationRequestRouting/healthCheck" -name "url" -value "http://test/up.html"
Set-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST'  -filter "webFarms/webFarm[@name='test']/applicationRequestRouting/healthCheck" -name "interval" -value "00:00:01"
Set-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST'  -filter "webFarms/webFarm[@name='test']/applicationRequestRouting/healthCheck" -name "responseMatch" -value "up"

#Create Global Rewrite Rule for ARR
#create a rewrite rule for HTTP
Write-Verbose -Message  "Create a rewrite rule (HTTP) for ARR"
Add-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST'  -filter "system.webServer/rewrite/globalRules" -name "." -value @{name = 'ARR_Rewrite_Rule'; stopProcessing = 'True'}
Set-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST'  -filter "system.webServer/rewrite/globalRules/rule[@name='ARR_Rewrite_Rule']/match" -name "url" -value ".*"

Add-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST'  -filter "system.webServer/rewrite/globalRules/rule[@name='ARR_Rewrite_Rule']/conditions" -name "." -value @{input = '{HTTP_HOST}'; pattern = 'srv2019.homelab.lan$'}

Add-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST'  -filter "system.webServer/rewrite/globalRules/rule[@name='ARR_Rewrite_Rule']/conditions" -name "." -value @{input = '{SERVER_PORT}'; pattern = '^80$'}
Set-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST'  -filter "system.webServer/rewrite/globalRules/rule[@name='ARR_Rewrite_Rule']/action" -name "type" -value "Rewrite"
Set-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST'  -filter "system.webServer/rewrite/globalRules/rule[@name='ARR_Rewrite_Rule']/action" -name "url" -value "http://test/{R:0}"

#create a rewrite rule for HTTPS (disabled)
Write-Verbose -Message  "Create a rewrite rule (HTTPS) for ARR. This one is disabled, there is no SSL yet"
Add-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST'  -filter "system.webServer/rewrite/globalRules" -name "." -value @{name = 'ARR_Rewrite_Rule HTTPS'; enabled = 'False'; stopProcessing = 'True'}
Set-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST'  -filter "system.webServer/rewrite/globalRules/rule[@name='ARR_Rewrite_Rule HTTPS']/match" -name "url" -value ".*"

Add-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST'  -filter "system.webServer/rewrite/globalRules/rule[@name='ARR_Rewrite_Rule HTTPS']/conditions" -name "." -value @{input = '{HTTP_HOST}'; pattern = 'srv2019.homelab.lan$'}

Add-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST'  -filter "system.webServer/rewrite/globalRules/rule[@name='ARR_Rewrite_Rule HTTPS']/conditions" -name "." -value @{input = '{SERVER_PORT}'; pattern = '^443$'}
Set-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST'  -filter "system.webServer/rewrite/globalRules/rule[@name='ARR_Rewrite_Rule HTTPS']/action" -name "type" -value "Rewrite"
Set-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST'  -filter "system.webServer/rewrite/globalRules/rule[@name='ARR_Rewrite_Rule HTTPS']/action" -name "url" -value "http://test/{R:0}"
#endregion

#region create HTTP to HTTPS Rewrite Rule (disabled)
Write-Verbose -Message  "Create a rewrite rule HTTP to HTTPS in the Default Web Site. This one is disabled, there is no SSL yet"
Add-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST/Default Web Site' -filter "system.webServer/rewrite/rules" -name "." -value @{name = 'HTTP/S to HTTPS Redirect'; enabled = 'False'; stopProcessing = 'True'}
Set-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST/Default Web Site' -filter "system.webServer/rewrite/rules/rule[@name='HTTP/S to HTTPS Redirect']/match" -name "url" -value "(.*)"

Add-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST/Default Web Site' -filter "system.webServer/rewrite/rules/rule[@name='HTTP/S to HTTPS Redirect']/conditions" -name "." -value @{input = '{SERVER_PORT_SECURE}'; pattern = '^0s'}
Set-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST/Default Web Site' -filter "system.webServer/rewrite/rules/rule[@name='HTTP/S to HTTPS Redirect']/action" -name "type" -value "Redirect"
Set-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST/Default Web Site' -filter "system.webServer/rewrite/rules/rule[@name='HTTP/S to HTTPS Redirect']/action" -name "url" -value "https://{HTTP_HOST}{REQUEST_URI}"
Set-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST/Default Web Site' -filter "system.webServer/rewrite/rules/rule[@name='HTTP/S to HTTPS Redirect']/action" -name "appendQueryString" -value "False"
#endregion


#region Edit Host file
Write-Verbose -Message  "Adding entries to the host file. ARR need this"
$hostentries = @'
127.0.0.1 test
127.0.0.1 greenwebsite
127.0.0.1 bluewebsite
'@
Add-Content -Path C:\windows\System32\drivers\etc\hosts -Value $hostentries
#endregion


#region Security: Remove server headers
##remove removeServerHeader
Write-Verbose -Message  "Security: Removing the Server Header"
Set-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST'  -filter "system.webServer/security/requestFiltering" -name "removeServerHeader" -value "True"
Set-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST/Default Web Site'  -filter "system.webServer/security/requestFiltering" -name "removeServerHeader" -value "True"
Set-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST' -location 'Default Web Site' -filter "system.webServer/security/requestFiltering" -name "removeServerHeader" -value "True"

##remove X-AspNet-Version
Write-Verbose -Message  "Security: Removing X-AspNet-Version Header"
Set-WebConfigurationProperty -pspath 'MACHINE/WEBROOT'  -filter "system.web/httpRuntime" -name "enableVersionHeader" -value "False"
Set-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST/Default Web Site'  -filter "system.web/httpRuntime" -name "enableVersionHeader" -value "False"
Set-WebConfigurationProperty -pspath 'MACHINE/WEBROOT' -location 'Default Web Site' -filter "system.web/httpRuntime" -name "enableVersionHeader" -value "False"

##remove arrResponseHeader (reverse proxy)
Write-Verbose -Message  "Security: Removing arrResponseHeader (reverse proxy) header"
Set-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST'  -filter "system.webServer/proxy" -name "arrResponseHeader" -value "False"
Write-Verbose -Message "IIS needs to be restarted to apply this setting"

##remove arrResponseHeader (webfarm)
Set-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST'  -filter "webFarms/webFarm[@name='test']/applicationRequestRouting/protocol" -name "arrResponseHeader" -value "False"

##remove X-Powered-By
Write-Verbose -Message  "Security: Removing X-Powered-By header"
Remove-WebConfigurationProperty  -pspath 'MACHINE/WEBROOT/APPHOST'  -filter "system.webServer/httpProtocol/customHeaders" -name "." -AtElement @{name = 'X-Powered-By'}
Remove-WebConfigurationProperty  -pspath 'MACHINE/WEBROOT/APPHOST/Default Web Site'  -filter "system.webServer/httpProtocol/customHeaders" -name "." -AtElement @{name = 'X-Powered-By'}

#endregion

#region FTP site & config
#Create FTP Site
# TODO

#Config global FTP settings
# TODO

#Create FTP virtual folder for websites
# TODO

#endregion

#region Security: Firewall Rules

#endregion

$endtime = Get-Date
$duration = $endtime - $starttime
$Finishmessage = "Finished Blue/Green Deployment in {0} minutes and {1} seconds." -f $duration.Minutes, $duration.Seconds
Write-Verbose -Message $Finishmessage