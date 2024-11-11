Clear-Host
# Get all movie files, excluding specific patterns
$movieFiles = Get-ChildItem -Path "E:\Movies" -Recurse |
Where-Object {
    # Only include files (not directories)
    $_.PSIsContainer -eq $false -and
    # Exclude files with [w] in the name
    $_.Name -notmatch '\[w\]' -and
    # Exclude .srt files
    $_.Extension -ne '.srt' -and
    # Include common video file extensions
    $_.Extension -match '\.(mp4|mkv|avi|mov|wmv|m4v)$'
} |
Select-Object -ExpandProperty FullName

# Check if any files were found
if ($movieFiles) {
    Write-Host "Found $($movieFiles.Count) movie files."

    try {
        # Copy to clipboard
        $movieFiles | Set-Clipboard
        Write-Host "Successfully copied file list to clipboard."
        Write-Host "First few files:"
        $movieFiles | Select-Object -First 3 | ForEach-Object { Write-Host $_ }
    }
    catch {
        Write-Host "Error copying to clipboard: $_"
    }
}
else {
    Write-Host "No movie files found in E:\Movies matching the criteria."
    Write-Host "Please verify:"
    Write-Host "1. The path E:\Movies exists"
    Write-Host "2. You have permission to access the directory"
    Write-Host "3. There are video files with extensions .mp4, .mkv, .avi, .mov, .wmv, or .m4v"
}