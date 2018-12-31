function Show-MvaNetFirewallRule {
<#
.SYNOPSIS
This function shows the firewall rules including all filters.
.DESCRIPTION
This function shows all the firewall rules that are present on the local computer, including all the filters.
Like port filters and address filters. The output should mimic wath you see in the Advanced Firewall GUI. The
default network module has a Show-NetFirewallRule but it is not possible to work with its output. This function
just outputs all the information as an object. This way it is possible to pipe it to other cmdlets.

You should use this function together with the Get-NetFirewallRule cmdlet.
.PARAMETER FirewallRule
This parameter accepts output from the Get-NetFirewallRule cmdlet.
.EXAMPLE
Get-NetFirewallRule | Show-MvaNetFirewallRule

Show all existing firewall rules with all filters.
.EXAMPLE
Get-NetFirewallRule -Enabled True | Show-MvaNetFirewallRule | Out-Gridview

Show all existing enabled firewall rules with all filters and pipe the output to a gridview.
.LINK
http://www.weblink.com
Get-NetFirewallRule
.INPUTS
Microsoft.Management.Infrastructure.CimInstance#root/standardcimv2/MSFT_NetFirewallRule
.OUTPUTS
System.Management.Automation.PSCustomObject
.NOTES
This function needs PowerShell 4.x to work.
#>
    [CmdletBinding()]
    [OutputType([PSCustomObject])]
    param(
        [Parameter(ValueFromPipeline=$true)]
        [psobject]$FirewallRule
    )

    process {
        if (($FirewallRule -ne $null) -and ($FirewallRule -ne "")) {
            Write-Verbose -Message "Processing rule $($FirewallRule.DisplayName)"
            try {
                Write-Verbose -Message "Getting address filter for rule $($FirewallRule.DisplayName)."
                $FirewallAddressFilter = $FirewallRule | Get-NetFirewallAddressFilter -ErrorAction Stop
                Write-Verbose -Message "Getting application filter for rule $($FirewallRule.DisplayName)."
                $FirewallApplicationFilter = $FirewallRule | Get-NetFirewallApplicationFilter -ErrorAction Stop
                Write-Verbose -Message "Getting port filter for rule $($FirewallRule.DisplayName)."
                $FirewallPortFilter = $FirewallRule | Get-NetFirewallPortFilter -ErrorAction Stop
                Write-Verbose -Message "Getting security filter for rule $($FirewallRule.DisplayName)."
                $FirewallSecurityFilter = $FirewallRule | Get-NetFirewallSecurityFilter -ErrorAction Stop
            }
            catch {
                Write-Error -Message "$($_.Exception.Message) - Line Number: $($_.InvocationInfo.ScriptLineNumber)"
            }
        } else {
            throw "No input supplied. Use Get-help Show-MvaNetFirewallRule to see how to use this function."
        }

        $Properties = [Ordered]@{
            'Name' = $FirewallRule.Name
            'DisplayName' = $FirewallRule.DisplayName
            'DisplayGroup' = $FirewallRule.DisplayGroup
            'Direction' = $FirewallRule.Direction
            'Profile' = $FirewallRule.Profile
            'Enabled' = $FirewallRule.Enabled
            'Action' = $FirewallRule.Action
            'Program' = $FirewallApplicationFilter.Program
            'LocalAddress' = $FirewallAddressFilter.LocalAddress
            'RemoteAddress'= $FirewallAddressFilter.RemoteAddress
            'Protocol' = $FirewallPortFilter.Protocol
            'LocalPort' = $FirewallPortFilter.LocalPort
            'RemotePort' = $FirewallPortFilter.RemotePort
            'RemoteUser' = $FirewallSecurityFilter.RemoteUser
            'RemoteMachine' = $FirewallSecurityFilter.RemoteMachine
            'LocalUser' = $FirewallSecurityFilter.LocalUser
            'Package' = $FirewallApplicationFilter.Package
        }
        Write-Verbose -Message "Creating output object for rule $($FirewallRule.DisplayName)."
        $FirewallRuleObject = New-Object -TypeName PSObject -Property $Properties
        Write-Output $FirewallRuleObject
    }
}

function Add-MvaNetFirewallRemoteAdressFilter {
    <#
.SYNOPSIS
This function adds one or more ipaddresses to the firewall remote address filter
.DESCRIPTION
With the default Set-NetFirewallAddressFilter you can set an address filter for a firewall rule. You can not use it to
add a ip address to an existing address filter. The existing address filter will be replaced by the new one.

The Add-MvaNetFirewallRemoteAdressFilter function will add the ip address. Which is very usefull when there are already
many ip addresses in de address filter.

.PARAMETER fwAddressFilter
This parameter conntains the AddressFilter that you want to change. It accepts pipeline output from the command
Get-NetFirewallAddressFilter

.PARAMETER IPaddresses
This parameter is mandatory and can contain one or more ip addresses. You can also use a subnet.
.EXAMPLE
Get-NetFirewallrule -DisplayName 'Test-Rule' | Get-NetFirewallAddressFilter | Add-MvaNetFirewallRemoteAdressFilter -IPAddresses 192.168.5.5
Add a single IP address to the remote address filter of the firewall rule 'Test-Rule'

.EXAMPLE
Get-NetFirewallrule -DisplayName 'Test-Rule' | Get-NetFirewallAddressFilter | Add-MvaNetFirewallRemoteAdressFilter -IPAddresses 192.168.5.5, 192.168.6.6, 192.168.7.0/24
Add multiple IP address to the remote address filter of the firewall rule 'Test-Rule'

.LINK
https://get-note.net/2018/12/31/edit-firewall-rule-scope-with-powershell/

.INPUTS
Microsoft.Management.Infrastructure.CimInstance#root/standardcimv2/MSFT_NetAddressFilter
.OUTPUTS
None
.NOTES
You need to be Administator to manage the firewall.
#>
    [CmdletBinding()]
    param(
        [Parameter(ValueFromPipeline = $true,
            Mandatory = $True)]
        [psobject]$fwAddressFilter,

        # Parameter help description
        [Parameter(Position = 0,
            Mandatory = $True,
            HelpMessage = "Enter one or more IP Addresses.")]
        [string[]]$IPAddresses
    )

    process {
        try {
            #Get the current list of remote addresses
            [string[]]$remoteAddresses = $fwAddressFilter.RemoteAddress
            Write-Verbose -Message "Current address filter contains: $remoteAddresses"

            #Add new ip address to the current list
            if ($remoteAddresses -in 'Any', 'LocalSubnet', 'LocalSubnet6', 'PlayToDevice') {
                $remoteAddresses = $IPAddresses
            }
            else {
                $remoteAddresses += $IPAddresses
            }
            #set new address filter
            $fwAddressFilter | Set-NetFirewallAddressFilter -RemoteAddress $remoteAddresses -ErrorAction Stop
            Write-Verbose -Message "New remote address filter is set to: $remoteAddresses"
        }
        catch {
            $PSCmdlet.ThrowTerminatingError($PSitem)
        }
    }
}