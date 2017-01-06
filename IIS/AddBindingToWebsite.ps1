#requires -Version 3 -Modules WebAdministration -RunAsAdministrator
<#
.SYNOPSIS
   With this script you can add one or more hostheaders to a website.
.DESCRIPTION
   With this script you can add one or more hostheaders to a website. 
   All hostheaders will be bound the same IPAddress and Port.
   It is not possible to do an SSL binding.
.PARAMETER Name <string>
   This is name of the website you want to add one or more extra bindings to. For example Default Web Site.
.PARAMETER HostHeader <string[]>
   This is one or more domain names you want to add to a website. The domain name can be www.test.com or test.com or blog.test.com.
   It is possible to add multiple domain names at the same time as long as these domain names will be bound to the same website, ipaddress and port.
.PARAMETER IPAddresss <string>
   This is the ipaddress you want to bind a domain name too. This parameter is optional. If you don't supply an ipaddress the default value '*' will
   be used. So the domain name will be bound to any ipaddress on the server.
.PARAMETER Port <int>
   This is an optional parameter with a default value of '80'. If you want to use another port you can supply it here.
.PARAMETER UseSSL <switch>
   This is an optional parameter. Use this switch to when you want to enable SSL on a domain. 
.PARAMETER CertSubject <string>
   When the switch -UseSSL is used you need to supply a certificate. For this script you only need to supply the subject name that is used in the 
   certificate and the script will lookup the correct certificate.
.PARAMETER CertStore <string>
   When the switch -UseSSL is used you also need to to supply the certificate store where the certificate is stored. Be aware that is only uses the
   certificate for LocalMachine. Valid choices are 'My' and 'WebHosting'.
.NOTES
   Version:         0.2.0
   Author:          Mario van Antwerpen
   Creation Date:   23-12-20016
   Purpose/Change:  Initial script development
.EXAMPLE
   .\AddBindingToWebsite.ps1 -Name "Default Web Site" -HostHeader "www.test.com","test.com"
   Add 2 new hostheaders to the "Default Web Site" for any IP Address on default port 80.
.EXAMPLE
   .\AddBindingToWebsite.ps1 -Name "Default Web Site" -HostHeader "www.test.com" -IPAddress "127.0.0.1"
   Add a new hostheader to the "Default Web Site" for a specifc IP Address on default port 80.
.EXAMPLE
   .\AddBindingToWebsite.ps1 -Name "Default Web Site" -HostHeader "www.test.com","test.nl" -port 8080
   Add a new hostheader to the "Default Web Site" for any IP Address on port 8080.
.EXAMPLE
   .\AddBindingToWebsite.ps1 -Name "Default Web Site" -HostHeader "www.test.com" -UseSSL -Port 443 -CertSubject "www.test.com" -CertStore "WebHosting"
   Add a new SSL Binding to the "Defaul Web Site"
#>
[CmdletBinding(SupportsShouldProcess=$true,
               ConfirmImpact='High',
               DefaultParameterSetName="nonssl")]
Param
(
    [Parameter(Mandatory=$true,
                ValueFromPipelineByPropertyName=$true,
                ParameterSetName="nonssl")]
    [Parameter(Mandatory=$true,
                ParameterSetName="ssl")]
    [ValidateNotNullOrEmpty()]
    [string]
    $Name,

    [Parameter(Mandatory=$true,
                ValueFromPipelineByPropertyName=$true,
                ParameterSetName="nonssl")]
    [Parameter(Mandatory=$true,
                ParameterSetName="ssl")]
    [ValidateNotNullOrEmpty()]
    [string[]]
    $Binding,

    [Parameter(Mandatory=$false,
                ValueFromPipelineByPropertyName=$true,
                ParameterSetName="nonssl")]
    [Parameter(Mandatory=$false,
                ParameterSetName="ssl")]
    [ValidateScript(
    {If ($_ -match '^(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$') {
        $True
    } Else {
        Throw "$_ is not a valid IPV4 Address!"
    }})]
    [string]
    $IPAddress="*",

    [Parameter(Mandatory=$false,
                ValueFromPipelineByPropertyName=$true,
                ParameterSetName="nonssl")]
    [Parameter(Mandatory=$true,
                ParameterSetName="ssl")]
    [ValidateRange(1,65535)] 
    [int]
    $Port=80,

    #SSL Parameters
    [Parameter(Mandatory=$false,
                ParameterSetName="ssl")]
    [switch]
    $UseSSL,

    # Param1 help description
    [Parameter(Mandatory=$true,
                ParameterSetName="ssl")]
    [ValidateNotNullOrEmpty()]
    [String]
    $CertSubject,

    # Param1 help description
    [Parameter(Mandatory=$true,
                ParameterSetName="ssl")]
    [ValidateSet("My","WebHosting")]
    [String]
    $CertStore
)

function New-MvaWebsiteBinding 
{
    [CmdletBinding()]
    Param
    (
        [Parameter(Mandatory=$true,
                    ValueFromPipelineByPropertyName=$true)]
        [string]$Name,

        [Parameter(Mandatory=$true,
                    ValueFromPipelineByPropertyName=$true)]
        [string[]]$Binding,

        [Parameter(Mandatory=$false,
                    ValueFromPipelineByPropertyName=$true)]
        #[ValidateScript(
        #{If ($_ -match '^(?:(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(?:25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$') {
        #    $True
        #} Else {
        #    Throw "$_ is not a valid IPV4 Address!"
        #}})]
        [string]
        $IPAddress="*",

        [Parameter(Mandatory=$false,
                    ValueFromPipelineByPropertyName=$true)]
        [ValidateRange(1,65535)] 
        [int]
        $Port=80
    )

    Begin
    {
    }
    Process
    {
        Foreach ($hostheader in $Binding)
        {
            Try 
            {
                New-WebBinding -Name $name -Port $Port -IPAddress $IPAddress -HostHeader $hostheader -ErrorAction Stop
                Write-Host "INFO: Added binding $hostheader, $IPAddress, $Port to website $name."
            }
            Catch [System.Management.Automation.ItemNotFoundException]
            {
                Write-Host "ERROR: There is no website with name $name!" -ForegroundColor Red
            }
            Catch [System.Runtime.InteropServices.COMException]
            {
                Write-Host "ERROR: Binding $hostheader already exists!"  -ForegroundColor Red
            }
            Catch [System.Management.Automation.ParameterBindingException]
            {
                Write-Host "ERROR: Unable to bind parameter!" -ForegroundColor Red
                Write-Host "ERROR: $_" -ForegroundColor Red
            }
            Catch 
            {
                $_
            }  
        }
    }
    End
    {
    }
}

function New-MvaSslWebsiteBinding
{
    [CmdletBinding()]
    Param
    (
        # Param1 help description
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true)]
        [String]
        $Name,

        # Param1 help description
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true)]
        [String[]]
        $Binding,

        # Param1 help description
        [Parameter(Mandatory=$true,
                   ValueFromPipelineByPropertyName=$true)]
        [String]
        $CertSubject,

        # Param1 help description
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [ValidateSet("My","WebHosting")]
        [String]
        $CertStore="WebHosting",

        # Param1 help description
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        $IPAddress,

        # Param1 help description
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true)]
        [ValidateRange(1,65535)]
        [Int]
        $Port=443
    )

    Begin
    {
        Import-Module WebAdministration
    }
    Process
    {
        Foreach ($hostheader in $Binding)
        {
            $cert = Get-ChildItem -Path Cert:\LocalMachine\$CertStore | where-Object {$_.subject -like "*$CertSubject*"}
            if ($cert -ne $null)
            {
                if ($cert.Count -eq 1) {                
                    Try 
                    {
                        New-WebBinding -name $name -Protocol https -HostHeader $hostheader -Port $port -SslFlags 1 -ErrorAction Stop
                        Write-Host "INFO: Added SSL binding $hostheader, $Port to website $name."
                        New-Item -Path "IIS:\SSLBindings\0.0.0.0!$port!$hostheader" -Value $cert -SSLFlags 1 -ErrorAction Stop
                        Write-Host "INFO: Created new SSL Binding: IIS:\SSLBindings\0.0.0.0!$port!$hostheader"
                    }
                    Catch [System.Management.Automation.ItemNotFoundException]
                    {
                        Write-Host "ERROR: There is no website with name $name!" -ForegroundColor Red
                    }
                    Catch [System.Runtime.InteropServices.COMException]
                    {
                        Write-Host "ERROR: Binding $hostheader already exists!"  -ForegroundColor Red
                    }
                    Catch [System.Management.Automation.ParameterBindingException]
                    {
                        Write-Host "ERROR: Unable to bind parameter!" -ForegroundColor Red
                        Write-Host "ERROR: $_" -ForegroundColor Red
                    }
                    Catch 
                    {
                        $_
                    }
                } else {
                    Write-Host "ERROR: Multiple certificates found for subject $CertSubject!" -ForegroundColor Red
                }    
            } else {
                Write-Host "ERROR: Cannot find a certificate for subject $CertSubject!" -ForegroundColor Red
            }
        }
    }
    End
    {
    }
}

foreach ($hostheader in $binding) {
    if ($UseSSL) {
        New-MvaSslWebsiteBinding -Name $Name -Binding $hostheader -CertSubject $CertSubject -CertStore $CertStore -IPAddress $IPAddress -Port $Port
    }
    else {
        New-MvaWebsiteBinding -Name $Name -Binding $hostheader -IPAddress $IPAddress -Port $Port
    }    
}

