Add-Type -AssemblyName System.Windows.Forms
[System.Windows.Forms.SendKeys]::SendWait("%{TAB}") #Return focus to the original window.
Clear-Host
. ( 'C:\mega\IDEs\powershell\functions.ps1' )

(get-netconnectionProfile).Name 

if ( (get-netconnectionProfile).Name -match "PdaNet" -and !( (get-netconnectionProfile).Name -match "PdaNet Broadband Connection" ) ) {

    Write-Host "Current network: " -NoNewline
    write-host "PdaNet" -BackgroundColor DarkGreen

    if ( (Get-Proxy)."ProxyEnable" -ne "1" -or (Get-Proxy)."ProxyServer" -ne "192.168.49.1:8000"  ) {
        set-proxy -server 192.168.49.1 -port 8000
    }
    else {
        Write-Host PdaNet proxy is already enabled -ForegroundColor Green
    }

}
else {
    Write-Host Not connected to PdaNet Wifi -BackgroundColor DarkRed
    remove-proxy
    Write-Host ( Get-Proxy | Format-Table | out-string )
	exit
}

pause