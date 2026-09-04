$ErrorActionPreference = "Stop"

# Check for yt-dlp
if (-not (Get-Command yt-dlp -ErrorAction SilentlyContinue)) {
    Write-Host "Installing yt-dlp..."
    pip install yt-dlp
}

$outputDir = "D:\projects\RadarTheNewThing\transcriptions"
if (-not (Test-Path $outputDir)) {
    New-Item -ItemType Directory -Path $outputDir
}

$date = (Get-Date).AddDays(-30).ToString("yyyyMMdd")
$channelUrl = "https://www.youtube.com/@TheNextNewThingAI/videos"
$jsonFile = "$outputDir\videos.json"

# Step 2: Get the JSON for the videos (last 30 days)
Write-Host "Fetching video list from the last 30 days..."
yt-dlp --dateafter $date --no-warnings --ignore-errors -j $channelUrl > $jsonFile

# Step 3: Download the subtitles (last 30 days) to the output directory
Write-Host "Downloading subtitles..."
yt-dlp --skip-download --write-sub --sub-format srt --sub-lang en --dateafter $date --no-warnings --ignore-errors --geo-bypass -o "$outputDir\%(id)s.%(ext)s" $channelUrl

# Step 4: Process each video
$transcriptionFile = "$outputDir\all_transcriptions.txt"
Clear-Content $transcriptionFile

foreach ($line in Get-Content $jsonFile) {
    $video = $line | ConvertFrom-Json
    $videoId = $video.id
    $videoTitle = $video.title

    $srtFile = Join-Path $outputDir "$videoId.srt"

    if (Test-Path $srtFile) {
        Write-Host "Processing $videoTitle"
        # Read the SRT file
        $content = Get-Content $srtFile
        $plainText = @()
        foreach ($l in $content) {
            # Skip lines that are numbers (sequence) or timestamps (containing -->)
            if ($l -notmatch "^\d+$" -and $l -notmatch "-->") {
                $plainText += $l
            }
        }
        $plainTextBlock = $plainText -join "`n"
        Add-Content $transcriptionFile "`n=== Video: $videoTitle (ID: $videoId) ===`n"
        Add-Content $transcriptionFile $plainTextBlock
        Add-Content $transcriptionFile "`n"
    } else {
        Write-Host "No subtitles found for $videoTitle"
    }
}

Write-Host "Transcriptions saved to $transcriptionFile"