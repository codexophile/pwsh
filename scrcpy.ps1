# Import external functions
set-location $PSScriptRoot
. .\#lib\functions.ps1

# Configuration
$scrcpyPath = 'D:\Program Files - Portable\scrcpy\scrcpy.exe'
$outputDirectory = "W:\#later\#scrcpy"

function Show-MessageBox {
  param(
    [string]$Message,
    [string]$Title = "scrcpy",
    [string]$ButtonType = 'OK',
    [string]$IconType = 'Information'
  )
  return [System.Windows.Forms.MessageBox]::Show($Message, $Title, $ButtonType, $IconType)
}

function Invoke-Scrcpy {
  param([string[]]$Arguments)
  $result = & $scrcpyPath $Arguments 2>&1
  $result | Write-Host
  return $result
}

function Start-DeviceDetection {
  Write-Host "`nDetecting device..." -ForegroundColor Cyan
  $result = Invoke-Scrcpy --tcpip
  Process-ScrcpyResult $result
}

function Process-ScrcpyResult {
  param([string[]]$Result)
    
  switch -Regex ($Result) {
    'ERROR: Could not find any ADB device' {
      if (Show-MessageBox "$_`n`nDetect device?" -ButtonType 'YesNo' -IconType 'Question' -eq 'Yes') {
        Start-DeviceDetection
      }
    }
    'Select a device via' {
      Show-MessageBox "$_`n`nMultiple connections found!" -ButtonType 'OK' -IconType 'Information'
      Start-ScrcpyRecording
    }
  }
}

function Start-ScrcpyRecording {
  Clear-Host
    
  $destination = Join-Path $outputDirectory "scrcpy $(Get-Date -f 'yyyy-MM-dd HHmm').mp4"
  $destination = checkFile $destination  # Assuming this is from the imported functions.ps1
  Write-Host "Destination: $destination"
    
  $result = Invoke-Scrcpy --record=$destination 
  [console]::Beep(200, 50)

  Process-ScrcpyResult $result
    
  if (Show-MessageBox 'Run again?' -ButtonType 'YesNo' -IconType 'Question' -eq 'Yes') {
    Start-ScrcpyRecording
  }
}

# Main execution
Start-ScrcpyRecording