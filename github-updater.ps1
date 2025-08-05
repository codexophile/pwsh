# PowerShell script to auto-update a GitHub release asset
param($owner, $repo, $assetName, $downloadFolder)

# ---- Fetch Latest Release info ----
$latestReleaseApi = "https://api.github.com/repos/$owner/$repo/releases/latest"
$headers = @{ "User-Agent" = "pwsh-auto-updater" }

try {
    $releaseInfo = Invoke-RestMethod -Uri $latestReleaseApi -Headers $headers
    $asset = $releaseInfo.assets | Where-Object { $_.name -eq $assetName }
    if ($asset) {
        $downloadUrl = $asset.browser_download_url
        $outputPath = Join-Path $downloadFolder $assetName

        # Download the asset
        Invoke-WebRequest -Uri $downloadUrl -OutFile $outputPath -UseBasicParsing
        Write-Host "Downloaded latest asset to: $outputPath"
    } else {
        Write-Host "Asset '$assetName' not found in the latest release."
    }
} catch {
    Write-Host "Error fetching release info or downloading asset: $_"
}
