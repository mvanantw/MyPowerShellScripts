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
.NOTES
   Version:         0.1.0
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

#>
[CmdletBinding(SupportsShouldProcess=$true,
               ConfirmImpact='High')]
[Alias()]
[OutputType([int])]
Param
(
    [Parameter(Mandatory=$true,
                ValueFromPipelineByPropertyName=$true,
                Position=0)]
    [string]$Name,

    [Parameter(Mandatory=$true,
                ValueFromPipelineByPropertyName=$true,
                Position=1)]
    [string[]]$HostHeader,

    [Parameter(Mandatory=$false,
                ValueFromPipelineByPropertyName=$true,
                Position=2)]
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
                Position=3)]
    [ValidateRange(1,65535)] 
    [int]
    $Port=80
)

Begin
{
}
Process
{
    foreach ($binding in $HostHeader)
    {
        try 
        {
            New-WebBinding -Name $name -Port $Port -IPAddress $IPAddress -HostHeader $Binding -ErrorAction Stop
            Write-Host "INFO: Added binding $Binding, $IPAddress, $Port to website $name."
        }
        catch [System.Management.Automation.ItemNotFoundException]
        {
            Write-Host "ERROR: There is no website with name $name!" -ForegroundColor Red
        }
        catch [System.Runtime.InteropServices.COMException]
        {
            Write-Host "ERROR: Binding $binding already exists!"  -ForegroundColor Red
        }
        catch [System.Management.Automation.ParameterBindingException]
        {
            Write-Host "ERROR: Unable to bind parameter!" -ForegroundColor Red
            Write-Host "ERROR: $_" -ForegroundColor Red
        }
    }
}
End
{
}