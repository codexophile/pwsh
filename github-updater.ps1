param($owner, $repo, $assetName, $downloadFolder = $PWD)

# ---- Fetch Latest Release info ----
$latestReleaseApi = "https://api.github.com/repos/$owner/$repo/releases/latest"
$headers = @{ "User-Agent" = "pwsh-auto-updater" }

# ErrorAction is set to SilentlyContinue to prevent script termination on a failed request.
$releaseInfo = Invoke-RestMethod -Uri $latestReleaseApi -Headers $headers -ErrorAction SilentlyContinue

# If the release information could not be fetched, print an error and exit.
if (-not $releaseInfo) {
    Write-Host "Error: Unable to fetch release information. Please check the repository details and your network connection."
    return
}

# Find the specific asset from the release information.
$asset = $releaseInfo.assets | Where-Object { $_.name -eq $assetName }

if ($asset) {
    # The download URL and the last-modified date of the online asset.
    $downloadUrl = $asset.browser_download_url
    $remoteUpdated = [datetime]$asset.updated_at

    # The full path to the local file.
    $outputPath = Join-Path $downloadFolder $assetName

    # Check if a local file already exists.
    if (Test-Path $outputPath) {
        # If it exists, get its last write time.
        $localUpdated = (Get-Item $outputPath).LastWriteTime
    } else {
        # If it does not exist, set the date to its minimum value to ensure the remote asset is considered newer.
        $localUpdated = [datetime]::MinValue
    }

    # Compare the modification dates of the remote and local files.
    if ($remoteUpdated -gt $localUpdated) {
        Write-Host "A new version of the asset is available. Commencing download..."
        # Download the new asset.
        Invoke-WebRequest -Uri $downloadUrl -OutFile $outputPath -UseBasicParsing
        # Set the local file's last write time to match the remote asset's last-modified time.
        (Get-Item $outputPath).LastWriteTime = $remoteUpdated
        Write-Host "The asset has been successfully downloaded."
    } else {
        Write-Host "The local asset is already the latest version."
    }
} else {
    Write-Host "The specified asset '$assetName' could not be located in the most recent release."
}