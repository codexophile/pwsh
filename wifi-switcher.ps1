# Define the two Wi-Fi network names
$network1 = "SLT-FIBER"
$network2 = "Jay"

function Get-CurrentNetwork {
    $netshOutput = & netsh wlan show interface
    $netshOutputString = [string]$netshOutput
    $null = $netshOutputString -match ' SSID +: (.+?) ' 
    if ($Matches[1]) { return $Matches[1] }
    else { return $false }
}

# Function to get the name of the network to connect to
function Get-NetworkToConnect {
    param (
        [string]$currentNetwork
    )
    switch ($currentNetwork) {
        $network1 { return $network2 }
        $network2 { return $network1 }
        Default { return $false }
    }
}

# Function to connect to a Wi-Fi network
function Connect-WiFiNetwork {
    param (
        [string]$networkName
    )
    try {
        Write-Host "Connecting to $networkName ..."
        $result = & netsh wlan connect name=$networkName
        Write-Host $result
        Start-Sleep -Seconds 5  # Wait for connection to establish
        $connected = Test-Connection -ComputerName www.google.com -Count 1 -Quiet
        if ($connected) {
            Write-Host "Successfully connected to $networkName"
            return $true
        }
        else {
            throw "Connected to $networkName, but no internet access"
        }
    }
    catch {
        Write-Host "Failed to connect to $networkName. Error: $_"
        return $false
    }
}

# Main script execution
$currentNetwork = Get-CurrentNetwork
$networkToConnect = Get-NetworkToConnect -currentNetwork $currentNetwork
$connected = Connect-WiFiNetwork -networkName $networkToConnect
Pause