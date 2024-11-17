# Define movie file extensions
$movieExtensions = @(".mp4", ".mkv", ".avi", ".mov", ".wmv")

# Get all movie files recursively
$movieFiles = Get-ChildItem -Path "E:\Movies" -Recurse | 
Where-Object { $_.Extension -in $movieExtensions }

# Initialize counters
$totalMovies = 0
$watchedMovies = 0
$nonWatchedMovies = 0
$errorMovies = 0
$unwatchedTitles = @()

# Process each movie file
foreach ($file in $movieFiles) {
    $totalMovies++
    
    # Check for watched tag
    if ($file.Name -match '\[w\]') {
        $watchedMovies++
    }
    else {
        $nonWatchedMovies++
        # Add to unwatched list, removing extension and common tags
        $cleanTitle = $file.BaseName -replace '\[.*?\]', '' -replace '^\s+|\s+$', ''
        $unwatchedTitles += $cleanTitle
    }
    
    # Check for error tag
    if ($file.Name -match '\[error\]') {
        $errorMovies++
    }
}

# Print statistics
Write-Host "Movie Collection Analysis" -ForegroundColor Cyan
Write-Host "======================" -ForegroundColor Cyan
Write-Host "Total movies:       $totalMovies"
Write-Host "Watched movies:     $watchedMovies"
Write-Host "Unwatched movies:   $nonWatchedMovies"
Write-Host "Movies with errors: $errorMovies"

# Copy unwatched titles to clipboard
if ($unwatchedTitles.Count -gt 0) {
    $unwatchedTitles | Set-Clipboard
    Write-Host "`nUnwatched movie titles have been copied to clipboard!" -ForegroundColor Green
}
else {
    Write-Host "`nNo unwatched movies found!" -ForegroundColor Yellow
}

pause