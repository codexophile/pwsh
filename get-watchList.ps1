# Define movie file extensions
$movieExtensions = @(".mp4", ".mkv", ".avi", ".mov", ".wmv")

# Get all movie files recursively
$movieFiles = Get-ChildItem -Path "E:\Movies" -Recurse | 
Where-Object { $_.Extension -in $movieExtensions }

# Initialize counters and size trackers
$totalMovies = 0
$watchedMovies = 0
$nonWatchedMovies = 0
$errorMovies = 0
$unwatchedTitles = @()

$totalSize = 0
$watchedSize = 0
$nonWatchedSize = 0
$errorSize = 0

# Process each movie file
foreach ($file in $movieFiles) {
  $totalMovies++
  $totalSize += $file.Length
    
  # Check for watched tag
  if ($file.Name -match '\[w\]') {
    $watchedMovies++
    $watchedSize += $file.Length
  }
  else {
    $nonWatchedMovies++
    $nonWatchedSize += $file.Length
    # Add to unwatched list, removing extension and common tags
    $cleanTitle = $file.BaseName -replace '\[.*?\]', '' -replace '^\s+|\s+$', ''
    $unwatchedTitles += $cleanTitle
  }
    
  # Check for error tag
  if ($file.Name -match '\[error\]') {
    $errorMovies++
    $errorSize += $file.Length
  }
}

# Function to format file size
function Format-FileSize {
  param([int64]$Size)
  if ($Size -gt 1TB) { return "{0:N2} TB" -f ($Size / 1TB) }
  if ($Size -gt 1GB) { return "{0:N2} GB" -f ($Size / 1GB) }
  if ($Size -gt 1MB) { return "{0:N2} MB" -f ($Size / 1MB) }
  if ($Size -gt 1KB) { return "{0:N2} KB" -f ($Size / 1KB) }
  return "$Size B"
}

# Print statistics
Write-Host "Movie Collection Analysis" -ForegroundColor Cyan
Write-Host "======================" -ForegroundColor Cyan
Write-Host "Total movies:       $totalMovies"
Write-Host "Total size:         $(Format-FileSize $totalSize)"
Write-Host
Write-Host "Watched movies:     $watchedMovies"
Write-Host "Watched size:       $(Format-FileSize $watchedSize)"
Write-Host
Write-Host "Unwatched movies:   $nonWatchedMovies"
Write-Host "Unwatched size:     $(Format-FileSize $nonWatchedSize)"
Write-Host
Write-Host "Movies with errors: $errorMovies"
Write-Host "Error size:         $(Format-FileSize $errorSize)"

# Copy unwatched titles to clipboard
if ($unwatchedTitles.Count -gt 0) {
  $unwatchedTitles | Set-Clipboard
  Write-Host "`nUnwatched movie titles have been copied to clipboard!" -ForegroundColor Green
}
else {
  Write-Host "`nNo unwatched movies found!" -ForegroundColor Yellow
}

pause