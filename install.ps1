# Define multiple URLs (in order)
$urls = @(
    "https://github.com/anycall6779/S1Uck-1DM/archive/refs/heads/main.zip",
    "https://codeload.github.com/anycall6779/S1Uck-1DM/zip/refs/heads/main"
)

# Define variables
$tempDir = "$env:TEMP\IDM_ACTIVATION_TEMP"
$output = "$tempDir\S1Uck-1DM-main.zip"
$extractDir = "$tempDir"
$versionFile = "$extractDir\S1Uck-1DM-main\src\idm_latest_version.txt"

# Ensure the temp directory exists
if (!(Test-Path -Path $tempDir)) {
    New-Item -ItemType Directory -Path $tempDir | Out-Null
}

# Try downloading from available URLs
$success = $false
foreach ($url in $urls) {
    Write-Host ""
    Write-Host "Downloading IDM Activation Script from:" -ForegroundColor Cyan
    Write-Host "$url" -ForegroundColor Yellow

    try {
        $webclient = New-Object System.Net.WebClient
        # Show simple progress
        $webclient.DownloadFile($url, $output)

        Write-Host "Download successful!" -ForegroundColor Green
        $success = $true
        break
    } catch {
        Write-Host "Failed to download from this URL. Trying next..." -ForegroundColor Red
    }
}

if (-not $success) {
    Write-Host ""
    Write-Host "ERROR: Download failed from all available sources." -ForegroundColor Red
    exit 1
}

# Extract ZIP
Write-Host "Extracting files..."
Expand-Archive -Path $output -DestinationPath $extractDir -Force

# Fetch Latest IDM Version
$versionURL = "https://www.internetdownloadmanager.com/news.html"
try {
    $response = Invoke-WebRequest -Uri $versionURL -UseBasicParsing -ErrorAction Stop
    if ($response.Content -match "What's new in version ([\d\.]+ Build \d+)") {
        $latestVersion = $matches[1]
        "Latest IDM Version: $latestVersion" | Set-Content -Path $versionFile -Encoding UTF8
    } else {
        Write-Host "Could not extract version from response."
        "Latest IDM Version: Unknown" | Set-Content -Path $versionFile -Encoding UTF8
    }
} catch {
    Write-Host "Version check failed: $_"
    "ERROR: PowerShell request failed: $($_.Exception.Message)" | Set-Content -Path $versionFile -Encoding UTF8
}

# Run the batch script
$batchFile = "$extractDir\S1Uck-1DM-main\IASL.cmd"
if (Test-Path -Path $batchFile) {
    Write-Host "Running the activation script..."
    Start-Process -FilePath "cmd.exe" -ArgumentList "/c `"$batchFile`"" -Wait
} else {
    Write-Host "Batch script not found in expected folder."
    exit 1
}

# Cleanup
Write-Host "Cleaning up extracted files..."
Remove-Item -Path "$tempDir" -Recurse -Force -ErrorAction SilentlyContinue

Write-Host "All set." -ForegroundColor Green
Write-Host "IDM Activation Script closed successfully." -ForegroundColor Green
