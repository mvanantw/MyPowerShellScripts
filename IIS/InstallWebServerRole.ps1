<#
.Synopsis
   This script install the webserver role on a windows server.
.DESCRIPTION
   This script install the webserver role on a windows server with its defaukt settings. You can also install additional webserver role features. 
   After installing it enables the firewall for HTTP and disables the firewall rule foor HTTPS. 
.EXAMPLE
   This example installs just the default webserver role.

   InstallWebserverRole.ps1
.EXAMPLE
   This example installs the webserver role including some additional features.

   InstallWebserverRole.ps1 -IncludeAdditionalWebFeatures
.EXAMPLE
   This example installs the webserver role including some additional features. And gives verbose output.

   InstallWebserverRole.ps1 -IncludeAdditionalWebFeatures -Verbose
#>
[CmdletBinding()]
Param
(
    # If this parameter is used The additional webfeatures like will be installed. Default state is False.
    [Parameter(
        Mandatory=$false,
        HelpMessage="Use this parameter to also install additional webfeatures")
    ]
    [switch]$IncludeAdditionalWebFeatures=$false
)

# Install webserver role
Write-Verbose -Message 'Installing webserver role'
$result = Install-WindowsFeature -Name 'web-server'
if ($result.Success) {
    Write-Verbose -Message "Installation of the webserver role was succesful."
    if ($result.ExitCode -eq 'SuccessRestartRequired') {
        Write-Verbose -Message "To complete the installation you need to restart the server." 
    }
    if ($result.ExitCode -ne 'NoChangeNeeded') { 
        Write-Verbose -Message "The following modules are installed:"
        foreach ($feature in $Result.FeatureResult) {
            Write-Verbose -Message "  $($feature.DisplayName)"
        }
    }
}
$result = $null

if ($IncludeAdditionalWebFeatures) {
    Write-Verbose -Message '---------- Additional Webserver Feature ----------'
    # Install Additional Web Server Features
    $AdditionalWebFeatures = "Web-Http-Redirect","Web-Stat-Compression","Web-ISAPI-Ext","Web-ISAPI-Filter","Web-Http-Logging","Web-Request-Monitor","Web-Basic-Auth","Web-Filtering","Web-IP-Security","Web-Performance","Web-Asp","Web-Asp-Net","Web-Asp-Net45","Web-Mgmt-Console","Web-Ftp-Service"
    Write-Verbose -Message "Installing additional webserver role features"
    $result = Install-WindowsFeature -name $AdditionalWebFeatures
    if ($result.Success) {
        Write-Verbose -Message "Installation of the additional webserver role features was succesful."
        if ($result.ExitCode -eq 'SuccessRestartRequired') {
            Write-Verbose -Message "To complete the installation you need to restart the server." 
        }
        if ($result.ExitCode -ne 'NoChangeNeeded') { 
            Write-Verbose -Message "The following modules are installed:"
            foreach ($feature in $Result.FeatureResult) {
                Write-Verbose -Message "  $($feature.DisplayName)"
            }
        }
    }
} else {
    Write-Verbose -Message "Skipping installing additional Webserver role features"
}
$result = $null

# Enable Built-In Firewall Rule for HTTP-IN for all profiles
Write-Verbose -Message '---------- Firewall Rules ----------'
Write-Verbose -Message 'Enabling HTTP-IN firewall role for all profiles'
Set-NetFirewallRule -Name 'IIS-WebServerRole-HTTP-In-TCP' -Profile 'Domain','Public','Private' -Enabled 'True'
Write-Verbose -Message 'Disabling HTTPS-IN firewall role for all profiles'
Set-NetFirewallRule -Name 'IIS-WebServerRole-HTTPS-In-TCP' -Profile 'Domain','Public','Private' -Enabled 'False'
