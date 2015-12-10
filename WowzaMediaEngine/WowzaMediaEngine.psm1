<#

#>

Function Get-WowzaServerStats {
<# 
      .SYNOPSIS 
          Gets server connection statistics from Wowza Media Server
      .DESCRIPTION 
          This function reads the real time server statistics from the Wowza Media Server xml interface. 
      .NOTES 
          Author:    Mario van Antwerpen, mario@fiorano.net
		  Website: http://danvers72.wordpress.com
      .EXAMPLE 
          Get-WowzaServerStats -server "server.example.com"
#>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$True,
                   ValueFromPipeline=$True,
                   ValueFromPipelineByPropertyName=$True,
                   HelpMessage='Which server would you like to target?')]
        [string]$ComputerName="localhost",
        [Parameter(Mandatory=$True,
                   HelpMessage='Supply valid credentials?')]
        [PSCredential]$Credential
    )

    process {
        $downloadstring = "http://",$computerName,":8086/connectioncounts" -join ""
	    Write-Verbose "Connecting to website"
        try {
            $result = Invoke-WebRequest -Uri $downloadstring -Credential $Credential
        } #try
        catch [System.Net.WebException] {
            return $_.Exception.Message
        } #catch
        [xml]$xml = $result.content

        $ServerStats = new-Object PSObject -Property @{	
            Name = $computerName;
	        ConnectionsCurrent = $xml.WowzaStreamingEngine.ConnectionsCurrent;
	        ConnectionsTotal = $xml.WowzaStreamingEngine.ConnectionsTotal;
	        ConnectionsTotalAccepted = $xml.WowzaStreamingEngine.ConnectionsTotalAccepted;
	        ConnectionsTotalRejected = $xml.WowzaStreamingEngine.ConnectionsTotalRejected;
	        MessagesInBytesRate = $xml.WowzaStreamingEngine.MessagesInBytesRate;
	        MessagesOutBytesRate = $xml.WowzaStreamingEngine.MessagesOutBytesRate
	    }
        write-verbose "Writing object"
	    Write-Output $ServerStats
    } #process
} #function

Function Get-WowzaStreamStats {
<# 
      .SYNOPSIS 
          Gets stream connection statistics from Wowza Media Server
      .DESCRIPTION 
          This function reads the real time stream statistics from the Wowza Media Server xml interface. 
      .NOTES 
          Author:    Mario van Antwerpen, mario@fiorano.net
		  Website: http://danvers72.wordpress.com
      .EXAMPLE 
          Get-WowzaStreamStats -server "server.example.com"
#>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory=$True,
                   ValueFromPipeline=$True,
                   ValueFromPipelineByPropertyName=$True,
                   HelpMessage='Which server would you like to target?')]
        [string]$ComputerName="localhost",
        [Parameter(Mandatory=$True,
                   HelpMessage='Supply valid credentials?')]
        [PSCredential]$Credential
    )

    process {
        $downloadstring = "http://",$computerName,":8086/connectioncounts" -join ""
        Write-Verbose "Connecting to website"
        try {
	        $result = Invoke-WebRequest -Uri $downloadstring -Credential $Credential
        } #try
        catch [System.Net.WebException] {
            return $_.Exception.Message
        } #catch
        [xml]$xml = $result.content

        Write-Verbose "Looping vhosts"
	    foreach ($vhost in $xml.WowzaStreamingEngine.VHost) {
	        Write-Verbose "Looping applications"
		    foreach ($Application in $xml.WowzaStreamingEngine.VHost.Application) {
                Write-Verbose "Looping streams" 
			    foreach ($Stream in $Application.ApplicationInstance.Stream) {				
				    $StreamStats = new-Object PSObject -Property @{
				        TotalConnections = $Stream.SessionsTotal;
				        StreamName = $Stream.Name;
				        FlashConnections = $Stream.SessionsFlash;
				        SilverlightConnections = $Stream.SessionsSmooth;
				        RTSPConnections = $Stream.SessionsRTSP;
				        iOSConnections = $Stream.SessionsCupertino;
				        Application = $Application.name;
				        Vhost = $vhost.name
				    }
                    write-verbose "Writing object"
				    Write-Output $StreamStats
			    } #foreach stream
		    } #foreach application
	    } #foreach vhost
    } #process
} # function