# Implement your module commands in this script.


# Export only the functions using PowerShell standard verb-noun naming.
# Be sure to list each exported functions in the FunctionsToExport field of the module manifest file.
# This improves performance of command discovery in PowerShell.


<#
.Synopsis
   Get all certificates from a certificate store
.DESCRIPTION
   Long description
.EXAMPLE
   Get all certificates from cert:\LocalMachine\My

   Get-MvaCertificate -CertificateStore 'My'
.EXAMPLE
   Get all certificates from cert:\LocalMachine\WebHosting

   Get-MvaCertificate -CertificateStore 'WebHosting'
#>
function Get-MvaCertificate
{
    [CmdletBinding()]
    [OutputType([psobject])]
    Param
    (
        # Param1 help description
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        [ValidateSet("TrustedPublisher","ClientAuthIssuer","Remote Desktop","Root","TrustedDevices","WebHosting","CA", "AuthRoot", "TrustedPeople","My","SmartCardRoot","Trust","Disallowed")]
        [string]
        $CertificateStore='My'
    )

    Begin
    {
        try {
            $certs = Get-ChildItem -Path Cert:\LocalMachine\$CertificateStore -ErrorAction Stop
        }
        catch {
            $_
        }
    }
    Process
    {
        foreach ($cert in $certs)
        {
            $Properties = @{
            'FriendlyName'= $cert.FriendlyName
            'Thumbprint'= $cert.Thumbprint
            'Subject'= $cert.Subject
            'SubjectAlternativeNames'= $cert.DnsNameList
            'SerialNumber' = $cert.SerialNumber
            'Issuer' = $cert.Issuer
            'EffectiveDate' = [datetime]$cert.GetEffectiveDateString()
            'ExpirationDate' = [datetime]$cert.GetExpirationDateString()
            }

            $CertInfo = New-Object -TypeName PSObject -Property $Properties

            write-output $CertInfo
        }
    }
    End
    {
        $certs = $null
        $CertInfo = $null
    }
}

<#
.Synopsis
   Find expired certificates
.DESCRIPTION
   Find certificates in a certificate store that are expired or will expire in a number of days
.EXAMPLE
   Find certificates in cert:\LocalMachine\WebHosting that are already expired.

   Find-MvaExpiredCertificate -CertificateStore 'WebHosting'
.EXAMPLE
   Find certificates in cert:\LocalMachine\WebHosting that will expire in 30 days.

   Find-MvaExpiredCertificate -Days 30 -CertificateStore 'WebHosting'
#>
function Find-MvaExpiredCertificate
{
    [CmdletBinding()]
    [OutputType()]
    Param
    (
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        [int]
        $days=0,

        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true,
                   Position=1)]
        [ValidateSet("TrustedPublisher","ClientAuthIssuer","Remote Desktop","Root","TrustedDevices","WebHosting","CA", "AuthRoot", "TrustedPeople","My","SmartCardRoot","Trust","Disallowed")]
        [string]
        $CertificateStore='My'
    )

    Begin
    {
        $ExpireDate = (get-date).AddDays($days)
    }
    Process
    {
        Write-Verbose -Message "INFO: Finding certificates in certificate story $CertificateStore that expire before $Expiredate"
        try {
            Get-MvaCertificate -CertificateStore $CertificateStore | Where-Object ExpirationDate -lt $Expiredate -ErrorAction Stop
        }
        catch {
            $_
        }
    }
    End
    {
            $ExpireDate = $null
    }
}

<#
.Synopsis
   Remove certificates from a certificate store.
.DESCRIPTION
   Long description
.EXAMPLE
   Example of how to use this cmdlet
.EXAMPLE
   Another example of how to use this cmdlet
#>
function Remove-MvaCertificate
{
    [CmdletBinding()]
    [OutputType()]
    Param
    (
        # Param1 help description
        [Parameter(Mandatory=$True,
                   ValueFromPipelineByPropertyName=$true,
                   Position=0)]
        [ValidateNotNullOrEmpty]
        [string]
        $ThumbPrint,

        # Param1 help description
        [Parameter(Mandatory=$false,
                   ValueFromPipelineByPropertyName=$true,
                   Position=1)]
        [ValidateSet("TrustedPublisher","ClientAuthIssuer","Remote Desktop","Root","TrustedDevices","WebHosting","CA", "AuthRoot", "TrustedPeople","My","SmartCardRoot","Trust","Disallowed")]
        [string]
        $CertificateStore='My'
    )

    Begin
    {
    }
    Process
    {
        try {
            Write-Verbose -Message "INFO: Trying to remove cert:\LocalMachine\$CertificateStore\$ThumbPrint."
            Remove-Item -Path cert:\LocalMachine\$CertificateStore\$ThumbPrint -ErrorAction Stop
            Write-Verbose -Message "INFO: Removed cert:\LocalMachine\$CertificateStore\$ThumbPrint."
        }
        catch [System.Management.Automation.ItemNotFoundException] {
            Write-Verbose -Message "ERROR: No certificate with thumbprint $ThumbPrint found in certificate store cert:\LocalMachine\$CertificateStore."
            Write-host "ERROR:" $error[0].Exception.Message -ForegroundColor Red
        }
        catch [System.ComponentModel.Win32Exception] {
            Write-Verbose -Message "ERROR: You have no permission to remove certificate with thumbprint $ThumbPrint from certificate store cert:\LocalMachine\$CertificateStore."
            Write-host "ERROR:" $error[0].Exception.Message -ForegroundColor Red
        }
        catch {
            $_
        }
    }
    End
    {
    }
}

Export-ModuleMember -Function *-*