#requires -Version 3 -Modules localaccounts, WebAdministration -RunAsAdministrator
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
    [Parameter(Mandatory=$True)]
    [string]$UserName,

    [Parameter(Mandatory=$True)]
    [string]$Password,

    [Parameter(Mandatory=$True)]
    [string]$HostHeader,
	
    [Parameter(Mandatory=$false)]
    [string]$RootDir='C:\Inetpub'
)
$VerbosePreference = "Continue"

Function New-MvaWebSiteUser{
    [CmdletBinding()]        
    param (
        [string]$Username=$(throw "Username missing"),
        [string]$Password=$(throw "Password missing"),
        [string]$Group="Users"
    )
    
    $Result = Get-Localuser -Name $Username -ErrorAction SilentlyContinue
    if ($Result -eq $null) {
        write-Verbose "Creating user $($user.UserName)"
        New-LocalUser -Name $UserName -Password $Password  -CannotChangePassword -PasswordNeverExpires

        Write-Verbose "Add $Username to group $Group"
        $GroupMember = Get-LocalUser -Name $UserName
        Add-LocalGroupMember -Name $Group -Members $GroupMember
    } else {
        Write-Verbose -Message "User $username already exists. Skipping this step."
    }
} 

Function New-MvaWebSiteAndAppPool {
    [CmdletBinding()]
    param (
        [string]$WebsiteName=$(throw "Parameter WebsiteName is missing"),
        [string]$Hostheader=$(throw "Parameter WebsiteName is missing"),
        [string]$RootDir=$(throw "Parameter WebsiteName is missing")
    )
    
    ##Make new apppool
    $AppPoolName = $WebsiteName + "AppPool"
    $Result = Get-ChildItem IIS:\\apppools | Where-Object -Property name -eq $AppPoolName
    if ($Result -eq $null) {
        Write-Verbose "Creating application pool $AppPoolName"
        New-WebAppPool -Name $AppPoolName
    } else {
        Write-Verbose -Message "There is already an application pool with the name $AppPoolName. Skipping this step."
    }
    $Result = $null
        
    ##Make new website
    $Result = Get-ChildItem IIS:\\sites | Where-Object -Property Name -eq $WebsiteName
    if ($result -eq $null) {
        Write-Verbose "Creating website $WebsiteName with binding $HostHeader running in application pool $AppPoolName."
        New-WebSite -Name $WebsiteName -Port 80 -HostHeader $Hostheader -PhysicalPath "$RootDir\$WebsiteName\wwwroot" -ApplicationPool $AppPoolName -ErrorAction Stop

        ##Set webconfiguration setting
        #enable anonymous authentication
        Write-Verbose "Enabling anynomous authentication."
        Set-WebConfigurationProperty -Filter '/system.webServer/security/authentication/anonymousAuthentication' -Name enabled -Value true -PSPath IIS:\ -Location $WebsiteName
        Write-Verbose "Setting anymous user to application pool identity."
        Set-WebConfigurationProperty -Filter '/system.webServer/security/authentication/anonymousAuthentication' -Name username -Value '' -PSPath IIS:\ -Location $WebsiteName
        
        #enable basic authentication
        Write-Verbose "Enabling basic authentication."
        Set-WebConfigurationProperty -Filter '/system.webServer/security/authentication/basicAuthentication' -Name enabled -Value true -PSPath IIS:\ -Location $WebsiteName

        #asp enable parentpaths
        Write-Verbose "Enabling parent paths."
        Set-WebConfigurationProperty -Filter '/system.webServer/asp' -Name enableParentPaths -Value true -PSPath IIS:\ -Location $WebsiteName

        #set log file directory
        Write-Verbose "Setting log directory to $RootDir\$WebsiteName\Logs\LogFiles"
        Set-ItemProperty "IIS:\Sites\$WebsiteName" -name logfile.directory -value "$RootDir\$WebsiteName\Logs\LogFiles"
        Set-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST'  -filter "system.applicationHost/sites/site[@name='$WebsiteName']/logFile" -name "localTimeRollover" -value "True"

        #set FailedReqLogFiles directory
        Write-Verbose "Setting FailedReqLogFiles directory to $RootDir\$WebsiteName\Logs\FailedReqLogFiles"
        Set-WebConfigurationProperty -pspath 'MACHINE/WEBROOT/APPHOST'  -filter "system.applicationHost/sites/site[@name='$WebsiteName']/traceFailedRequestsLogging" -name "directory" -value "$RootDir\$WebsiteName\logs\FailedReqLogFiles"
    } else {
        Write-Error -Message "There is already a website with the name $websitename"
    }    
}

Function Set-MvaWebsiteDirectoryPermissions {
    [CmdletBinding()]
    param (
        [string]$Username=$(throw "Username missing"),
        [string]$RootDir=$(throw "Parameter WebsiteName is missing")
    )
    
    $w3user = "IIS AppPool\"+$Username+"AppPool"

    ##Set file permissions
    ##Root dir
    $acl = get-acl "$RootDir\$Username"
    Write-Verbose "Setting FullControl file permission for user $username on folder $RootDir\$Username."
    $acl.AddAccessRule((New-Object System.Security.AccessControl.FileSystemAccessRule("$Username","FullControl", "ContainerInherit, ObjectInherit", "None", "Allow")))
    Write-Verbose "Setting ReadAndExecute file permission for user $w3user on folder $RootDir\$Username."
    $acl.AddAccessRule((New-Object System.Security.AccessControl.FileSystemAccessRule("$w3user","ReadAndExecute", "ContainerInherit, ObjectInherit", "None", "Allow")))
    set-acl "$RootDir\$Username" $acl
    
    ##Access-DB dir
    $acl = get-acl "$RootDir\$Username\Access-DB"
    Write-Verbose "Setting FullControl file permission for user $username on folder $RootDir\$Username\access-db."
    $acl.AddAccessRule((New-Object System.Security.AccessControl.FileSystemAccessRule("$Username","FullControl", "ContainerInherit, ObjectInherit", "None", "Allow")))
    Write-Verbose "Setting FullControl file permission for user $w3user on folder $RootDir\$Username\access-db."
    $acl.AddAccessRule((New-Object System.Security.AccessControl.FileSystemAccessRule("$w3user","FullControl", "ContainerInherit, ObjectInherit", "None", "Allow")))
    set-acl "$RootDir\$Username\Access-DB" $acl

    ##Logfiles dir
    $acl = get-acl "$RootDir\$Username\Logs\LogFiles"
    Write-Verbose "Setting FullControl file permission for user $username on folder $RootDir\$Username\Logs\LogFiles."
    $acl.AddAccessRule((New-Object System.Security.AccessControl.FileSystemAccessRule("$Username","FullControl", "ContainerInherit, ObjectInherit", "None", "Allow")))
    set-acl "$RootDir\$Username\Logs\LogFiles" $acl

    ## FailedReqLogFiles
    $acl = get-acl "$RootDir\$Username\Logs\FailedReqLogFiles"
    Write-Verbose "Setting FullControl file permission for user $username on folder $RootDir\$Username\Logs\FailedReqLogFiles."
    $acl.AddAccessRule((New-Object System.Security.AccessControl.FileSystemAccessRule("$Username","FullControl", "ContainerInherit, ObjectInherit", "None", "Allow")))
    Write-Verbose "Setting FullControl file permission for user $w3user on folder $RootDir\$Username\Logs\FailedReqLogFiles."
    $acl.AddAccessRule((New-Object System.Security.AccessControl.FileSystemAccessRule("$w3user","FullControl", "ContainerInherit, ObjectInherit", "None", "Allow")))
    set-acl "$RootDir\$Username\Logs\FailedReqLogFiles" $acl
    
    ##wwwroot dir
    $acl = get-acl "$RootDir\$Username\wwwroot"
    Write-Verbose "Setting FullControl file permission for user $username on folder $RootDir\$Username\wwwroot."
    $acl.AddAccessRule((New-Object System.Security.AccessControl.FileSystemAccessRule("$Username","FullControl", "ContainerInherit, ObjectInherit", "None", "Allow")))
    Write-Verbose "Setting ReadAndExecute file permission for user $w3user on folder $RootDir\$Username\wwwroot."
    $acl.AddAccessRule((New-Object System.Security.AccessControl.FileSystemAccessRule("$w3user","ReadAndExecute", "ContainerInherit, ObjectInherit", "None", "Allow")))
    set-acl "$RootDir\$Username\wwwroot" $acl
    
    ##wwwroot/app_data
    $acl = get-acl "$RootDir\$Username\wwwroot\app_data"
    Write-Verbose "Setting FullControl file permission for user $username on folder $RootDir\$Username\wwwroot\app_data."
    $acl.AddAccessRule((New-Object System.Security.AccessControl.FileSystemAccessRule("$Username","FullControl", "ContainerInherit, ObjectInherit", "None", "Allow")))
    Write-Verbose "Setting FullControl file permission for user $w3user on folder $RootDir\$Username\wwwroot\app_data."
    $acl.AddAccessRule((New-Object System.Security.AccessControl.FileSystemAccessRule("$w3user","FullControl", "ContainerInherit, ObjectInherit", "None", "Allow")))
    set-acl "$RootDir\$Username\wwwroot\app_data" $acl    
    
}

## Create Directories
Write-Verbose "Creating folder for content and logs."
if (test-path -Path "$RootDir\$UserName") {
    Write-Verbose -Message "Folder $RootDir\$UserName already exists. Skipping this step."
} else {
    New-Item -Path "$RootDir\$UserName" -ItemType Directory
}

if (test-path -Path "$RootDir\$UserName\Access-DB") {
    Write-Verbose -Message "Folder $RootDir\$UserName\access-DB already exists. Skipping this step."
} else {
    New-Item -Path "$RootDir\$UserName\Access-DB" -ItemType Directory
}

if (test-path -Path "$RootDir\$UserName\Logs") {
    Write-Verbose -Message "Folder $RootDir\$UserName\Logs already exists. Skipping this step."
} else {
    New-Item -Path "$RootDir\$UserName\Logs" -ItemType Directory
}

if (test-path -Path "$RootDir\$UserName\logs\LogFiles") {
    Write-Verbose -Message "Folder $RootDir\$UserName\Logs\LogFiles already exists. Skipping this step."
} else {
    New-Item -Path "$RootDir\$UserName\logs\LogFiles" -ItemType Directory
}

if (test-path -Path "$RootDir\$UserName\logs\FailedReqLogFiles") {
    Write-Verbose -Message "Folder $RootDir\$UserName\Logs\FailedReqLogFiles already exists. Skipping this step."
} else {
    New-Item -Path "$RootDir\$UserName\logs\FailedReqLogFiles" -ItemType Directory
}

if (test-path -Path "$RootDir\$UserName\wwwroot") {
    Write-Verbose -Message "Folder $RootDir\$UserName\wwwroot already exists. Skipping this step."
} else {
    New-Item -Path "$RootDir\$UserName\wwwroot" -ItemType Directory
}

if (test-path -Path "$RootDir\$UserName\wwwroot\App_Data") {
    Write-Verbose -Message "Folder $RootDir\$UserName\wwwroot\App_Data already exists. Skipping this step."
} else {
    New-Item -Path "$RootDir\$UserName\wwwroot\App_Data" -ItemType Directory
}

##Set Directory permissions
Set-MvaWebsiteDirectoryPermissions -Username $UserName -RootDir $RootDir -verbose
Start-Sleep -Seconds 1

##Make new user for the website
New-MvaWebSiteUser -Username $UserName -Password $Password -Group w3users -verbose	
Start-Sleep -Seconds 1

##Make new website
New-MvaWebSiteAndAppPool -WebsiteName $UserName -Hostheader $Hostheader -RootDir $RootDir -ErrorAction Stop
Start-Sleep -Seconds 1

Write-Verbose "Finished creating website $UserName with binding $Hostheader!"        


