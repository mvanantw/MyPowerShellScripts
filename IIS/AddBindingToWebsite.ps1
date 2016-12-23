#requires -Version 3 -Modules WebAdministration -RunAsAdministrator

<#
.Synopsis
   With this script you can add one or more hostheaders to a website.

.DESCRIPTION
   With this script you can add one or more hostheaders to a website. 
   All hostheaders will be bound the same IPAddress and Port.
   It is not possible to do an SSL binding.

.PARAMETER
   Name
.PARAMETER
   HostHeader

.PARAMETER
   IPAddresss

.PARAMETER
   Port

.EXAMPLE
   Add 2 new hostheaders to the "Default Web Site" for any IP Address on default port 80.

   PS> AddBindingToWebsite.ps1 -Name "Default Web Site" -HostHeader "www.test.nl","test.nl"

.EXAMPLE
   Add a new hostheader to the "Default Web Site" for a specifc IP Address on default port 80.

   PS> AddBindingToWebsite.ps1 -Name "Default Web Site" -HostHeader "www.test.nl" -IPAddress "127.0.0.1"

.EXAMPLE
   Add a new hostheader to the "Default Web Site" for any IP Address on port 8080.

   PS> AddBindingToWebsite.ps1 -Name "Default Web Site" -HostHeader "www.test.nl","test.nl" -port 8080

.EXAMPLE
   Another example of how to use this cmdlet
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