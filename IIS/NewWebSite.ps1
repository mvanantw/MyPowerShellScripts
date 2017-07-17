#requires -Version 3 -Modules localaccounts, WebAdministration -RunAsAdministrator
<#
.Synopsis
    This script creates a new website in IIS.
.DESCRIPTION
    This script creates a new website in IIS. To do this it creates:
    - The directory structure
    - A user account for the customer
    - A decicated application pool
    - And the website with hostheader

    The script accepts 4 parameters.
    - [string]Username
        This is the username that a customer can use for publishing. It is also used to name the directory, website ID and application pool.
    - [string]Password
        This is the password for the customer account.
    - [string]HostHeader
        The FQDN that will be used for the website.
    - [string]RootDir
        This the directory were all websites are. Like c:\inetpub
.EXAMPLE
   NewWebSite.ps1 -UserName "Customer1" -Password "P@ssw0rd" -HostHeader "www.website.nl" -RootDir "d:\data"
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

<#
.Synopsis
   Add an ACL to a directory.
.DESCRIPTION
   Add an ACL to a directory.
.EXAMPLE
   Set-MvaAcl -Path "d:\data\Customer1 -UserName "Customer1" -Permission "FullControl"
#>
function Set-MvaAcl
{
    [CmdletBinding()]
    Param
    (
        # Param1 help description
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        [string]$Path,

        # Param2 help description
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=1)]
        [string]$UserName,

        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=2)]
        [ValidateSet("FullControl","Modify","Read","ReadAndExecute","Write")]
        [string]$Permission
    )

    Begin
    {
    }
    Process
    {
        $acl = get-acl $path
        Write-Verbose "Setting $Permission file permission for user $username on folder $path."
        $acl.AddAccessRule((New-Object System.Security.AccessControl.FileSystemAccessRule("$Username","$Permission", "ContainerInherit, ObjectInherit", "None", "Allow")))
        Set-Acl -Path $Path -AclObject $acl
    }
    End
    {
        $acl = $null
    }
}

Function New-MvaWebSiteUser {
    [CmdletBinding()]
    param (
        [string]$Username=$(throw "Username missing"),
        [string]$Password=$(throw "Password missing"),
        [string]$Group="Users"
    )

    $Result = Get-Localuser -Name $Username -ErrorAction SilentlyContinue
    if ($Result -eq $null) {
        write-Verbose "Creating user $UserName"
        $spwd = ConvertTo-SecureString -String $Password -AsPlainText -force
        New-LocalUser -Name $Username -Password $spwd -AccountNeverExpires -PasswordNeverExpires -UserMayNotChangePassword

        Write-Verbose "Add $Username to group $Group"
        $GroupMember = Get-LocalUser -Name $UserName
        Add-LocalGroupMember -Group $Group -Member $GroupMember
    } else {
        Write-Verbose -Message "User $username already exists. Skipping this step."
    }
}

<#
.SYNOPSIS
    Set the ASP option enableParentPaths to true or false
.PARAMETER Enable
    Switch parameter that enables parentpaths
.PARAMETER Disable
    Switch parameter that disables parentpaths
.EXAMPLE
    Example of how to use this cmdlet
.EXAMPLE
    Another example of how to use this cmdlet
#>
function Set-MvaIisAspParenPaths {
    [CmdletBinding()]
    param(
        [Parameter(Mandatory=$true)]
        [string]
        $websitename,
        [Parameter(Mandatory=$true,
                    ParameterSetName="enable")]
        [switch]
        $enable,
        [Parameter(Mandatory=$true,
                    ParameterSetName="disable")]
        [switch]
        $disable
    )

    process {
        try {
            if ($enable.IsPresent) {
                Write-Verbose "Enabling parent paths."
                Set-WebConfigurationProperty -Filter '/system.webServer/asp' -Name enableParentPaths -Value true -PSPath IIS:\ -Location $WebsiteName
            }
            if ($disable.IsPresent) {
                Write-Verbose "Disabling parent paths."
                Set-WebConfigurationProperty -Filter '/system.webServer/asp' -Name enableParentPaths -Value false -PSPath IIS:\ -Location $WebsiteName
            }
        }
        catch {
            Write-Error -Message "$($_.Exception.Message) - Line Number: $($_.InvocationInfo.ScriptLineNumber)"
        }
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
        Set-MvaIisAspParenPaths -websitename $WebsiteName -enable -Verbose

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

    $AppPoolIdentity = "IIS AppPool\"+$Username+"AppPool"

    ##Set file permissions
    ##Root dir
    Set-MvaAcl -Path "$RootDir\$Username" -UserName $Username -Permission "FullControl"
    Set-MvaAcl -Path "$RootDir\$Username" -UserName $AppPoolIdentity -Permission "ReadAndExecute"

    ##Access-DB dir
    Set-MvaAcl -Path "$RootDir\$Username\Access-DB" -UserName $Username -Permission "FullControl"
    Set-MvaAcl -Path "$RootDir\$Username\Access-DB" -UserName $AppPoolIdentity -Permission "FullControl"

    ##Logfiles dir
    Set-MvaAcl -Path "$RootDir\$Username\Logs\LogFiles" -UserName $Username -Permission "FullControl"

    ## FailedReqLogFiles
    Set-MvaAcl -Path "$RootDir\$Username\Logs\FailedReqLogFiles" -UserName $Username -Permission "FullControl"
    Set-MvaAcl -Path "$RootDir\$Username\Logs\FailedReqLogFiles" -UserName $AppPoolIdentity -Permission "FullControl"

    ##wwwroot dir
    Set-MvaAcl -Path "$RootDir\$Username\wwwroot" -UserName $Username -Permission FullControl
    Set-MvaAcl -Path "$RootDir\$Username\Logs\FailedReqLogFiles" -UserName $AppPoolIdentity -Permission "ReadAndExecute"

    ##wwwroot/app_data
    Set-MvaAcl -Path "$RootDir\$Username\wwwroot\app_data" -UserName $Username -Permission FullControl
    Set-MvaAcl -Path "$RootDir\$Username\wwwroot\app_data" -UserName $AppPoolIdentity -Permission FullControl
}

function New-MvaWebFolder {
    [CmdletBinding()]
    Param
    (
        # Param1 help description
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        [string]$Path
    )

    Begin
    {
    }
    Process
    {
        if (test-path -Path $Path) {
            Write-Verbose -Message "Folder $Path already exists. Skipping this step."
        } else {
            Write-Verbose -Message "Creating folder $Path."
            New-Item -Path $Path -ItemType Directory
        }
    }
    End
    {
    }
}

## Create Directories
Write-Verbose -Message "---------- Content Folders ----------"
Write-Verbose "Creating folder for content and logs."
New-MvaWebFolder -Path "$RootDir\$UserName"
New-MvaWebFolder -Path "$RootDir\$UserName\Access-DB"
New-MvaWebFolder -Path "$RootDir\$UserName\Logs"
New-MvaWebFolder -Path "$RootDir\$UserName\Logs\LogFiles"
New-MvaWebFolder -Path "$RootDir\$UserName\Logs\FailedReqLogFiles"
New-MvaWebFolder -Path "$RootDir\$UserName\wwwroot"
New-MvaWebFolder -Path "$RootDir\$UserName\wwwroot\App_Data"


##Make new user for the website
Write-Verbose -Message "---------- Website User ----------"
New-MvaWebSiteUser -Username $UserName -Password $Password -Group w3users -verbose
Start-Sleep -Seconds 1

##Make new website
Write-Verbose -Message "---------- Website & Application Pool ----------"
New-MvaWebSiteAndAppPool -WebsiteName $UserName -Hostheader $Hostheader -RootDir $RootDir -ErrorAction Stop
Start-Sleep -Seconds 1

##Set Directory permissions
Write-Verbose -Message "---------- Folder Permissions ----------"
Set-MvaWebsiteDirectoryPermissions -Username $UserName -RootDir $RootDir -verbose
Start-Sleep -Seconds 1

Write-Verbose "Finished creating website $UserName with binding $Hostheader!"


