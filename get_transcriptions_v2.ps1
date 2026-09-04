$ErrorActionPreference = "Stop"

# Check for yt-dlp
if (-not (Get-Command yt-dlp -ErrorAction SilentlyContinue)) {
    Write-Host "Installing yt-dlp..."
    pip install yt-dlp
}

$outputDir = "D:\projects\RadarTheNewThing\transcriptions_v2"
if (-not (Test-Path $outputDir)) {
    New-Item -ItemType Directory -Path $outputDir
}

$date = (Get-Date).AddDays(-30).ToString("yyyyMMdd")
$channelUrl = "https://www.youtube.com/@TheNextNewThingAI/videos"
$jsonFile = "$outputDir\videos.json"

Write-Host "Fetching video list from the last 30 days..."
# Get video IDs and basic info, limit to 20 videos to avoid huge files
yt-dlp --js-runtimes deno --dateafter $date --no-warnings --ignore-errors --print-json --flat-playlist "$channelUrl" | select -first 20 > $jsonFile

# Check if we got any videos
if (-not (Test-Path $jsonFile) -or (Get-Content $jsonFile | Measure-Object -Line).Lines -eq 0) {
    Write-Host "No videos found in the last 30 days."
    exit
}

Write-Host "Downloading subtitles for each video..."
# Process each video
$transcriptionFile = "$outputDir\all_transcriptions.txt"
# Initialize or clear the transcription file
Set-Content -Path $transcriptionFile -Value ''

$videoCount = 0
foreach ($line in Get-Content $jsonFile) {
    $videoCount++
    $video = $line | ConvertFrom-Json
    $videoId = $video.id
    $videoTitle = $video.title

    Write-Host ("Processing video {0}: {1}" -f $videoCount, $videoTitle)

    # Download English subtitles (skip video download)
    # Note: In PowerShell, % is the format operator, so we need to escape it as %% for yt-dlp
    $outputTemplate = Join-Path $outputDir ("%%(id)s.%%(ext)s")
    yt-dlp --js-runtimes deno --skip-download --write-sub --sub-format srt --sub-lang en --no-warnings --ignore-errors --geo-bypass -o $outputTemplate "https://www.youtube.com/watch?v=$videoId"

    $srtFile = Join-Path $outputDir "$videoId.srt"

    if (Test-Path $srtFile) {
        Write-Host ("  Extracting subtitles for {0}" -f $videoTitle)
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
        Add-Content $transcriptionFile ("`n** Video: {0} (ID: {1}) **`n" -f $videoTitle, $videoId)
        Add-Content $transcriptionFile $plainTextBlock
        Add-Content $transcriptionFile "`n"
    } else {
        Write-Host ("  No subtitles found for {0}" -f $videoTitle)
        Add-Content $transcriptionFile ("`n** Video: {0} (ID: {1}) **`n" -f $videoTitle, $videoId)
        Add-Content $transcriptionFile "No subtitles available for this video."
        Add-Content $transcriptionFile "`n"
    }
}

Write-Host ("Transcriptions saved to {0}" -f $transcriptionFile)
Write-Host ("Processed {0} videos." -f $videoCount)