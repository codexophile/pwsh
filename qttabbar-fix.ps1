. "C:\mega\IDEs\powershell\#lib\functions.ps1"
RunAsAdmin

$viveToolPath = Join-Path $env:SystemDrive "Program Files (Portable)\ViVeTool\ViVeTool.exe"

if (-not (Test-Path -LiteralPath $viveToolPath -PathType Leaf)) {
	Write-Warning "ViVeTool.exe was not found at: $viveToolPath"
	$openViveRepo = Read-Host "Open https://github.com/thebookisclosed/ViVe now? (Y/N)"

	if ($openViveRepo -match '^(?i)y(?:es)?$') {
		Start-Process "https://github.com/thebookisclosed/ViVe"
	}
  Exit
}

$viveIds = @(
	"57048216"
	"57048237"
	"58988972"
)

$allSucceeded = $true

foreach ($id in $viveIds) {
	& $viveToolPath /disable /id:$id
	$commandExitCode = $LASTEXITCODE

	if ($commandExitCode -eq 0) {
		Write-Host "SUCCESS: vivetool /disable /id:$id"
	}
	else {
		Write-Warning "FAILED (exit code $commandExitCode): vivetool /disable /id:$id"
		$allSucceeded = $false
	}
}

if ($allSucceeded) {
	Write-Host "ViVeTool changes completed successfully." -ForegroundColor Green
}
else {
	Write-Warning "One or more ViVeTool commands failed."
}

Pause
