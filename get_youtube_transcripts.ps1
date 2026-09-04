$ErrorActionPreference = "Stop"

# Check for yt-dlp
if (-not (Get-Command yt-dlp -ErrorAction SilentlyContinue)) {
    Write-Host "Installing yt-dlp..."
    pip install yt-dlp
}

$outputDir = "D:\projects\RadarTheNewThing\youtube_transcripts"
if (-not (Test-Path $outputDir)) {
    New-Item -ItemType Directory -Path $outputDir
}

$date = (Get-Date).AddDays(-30).ToString("yyyyMMdd")
$channelUrl = "https://www.youtube.com/@TheNextNewThingAI/videos"
$jsonFile = "$outputDir\videos_info.json"

Write-Host "Fetching video list from the last 30 days..."
# Get video IDs and basic info
yt-dlp --js-runtimes deno --dateafter $date --no-warnings --ignore-errors --print-json --flat-playlist "$channelUrl" > $jsonFile

# Check if we got any videos
if (-not (Test-Path $jsonFile) -or (Get-Content $jsonFile | Measure-Object -Line).Lines -eq 0) {
    Write-Host "No videos found in the last 30 days."
    exit
}

$videoCount = (Get-Content $jsonFile | Measure-Object -Line).Lines
Write-Host ("Found {0} videos from the last 30 days." -f $videoCount)

# Process each video
$transcriptionFile = "$outputDir\all_transcripts.txt"
# Initialize or clear the transcription file
Set-Content -Path $transcriptionFile -Value ''

$processedCount = 0
# Save current directory to restore later
$originalDir = Get-Location

try {
    Set-Location $outputDir
    
    foreach ($line in Get-Content $jsonFile) {
        $processedCount++
        $video = $line | ConvertFrom-Json
        $videoId = $video.id
        $videoTitle = $video.title
        $videoUrl = "https://www.youtube.com/watch?v=$videoId"

        Write-Host ("Processing video {0}/{1}: {2}" -f $processedCount, $videoCount, $videoTitle)

        # Remove any existing subtitle files
        Remove-Item -Path "$videoId.en.*" -ErrorAction SilentlyContinue
        
        # Try to download English subtitles first
        $args = @(
            "--js-runtimes", "deno",
            "--skip-download",
            "--write-sub",
            "--sub-format", "srt",
            "--sub-lang", "en",
            "--no-warnings",
            "--ignore-errors",
            "--geo-bypass",
            "-o", "%(id)s.%(ext)s",
            $videoUrl
        )
        & yt-dlp @args
        
        # If no regular subtitles, try auto-generated captions
        if (-not (Test-Path "$videoId.en.srt")) {
            Write-Host "  Trying auto-generated captions..."
            Remove-Item -Path "$videoId.en.*" -ErrorAction SilentlyContinue
            $argsAuto = @(
                "--js-runtimes", "deno",
                "--skip-download",
                "--write-auto-sub",
                "--sub-format", "srt",
                "--sub-lang", "en",
                "--no-warnings",
                "--ignore-errors",
                "--geo-bypass",
                "-o", "%(id)s.%(ext)s",
                $videoUrl
            )
            & yt-dlp @argsAuto
        }

        # Check if we got any subtitle file
        $subtitleFile = Get-ChildItem -Path "." -Filter "$videoId.en.*" -ErrorAction SilentlyContinue | Select-Object -First 1
        
        if ($subtitleFile) {
            Write-Host ("  Extracting subtitles for {0}" -f $videoTitle)
            # Read the subtitle file
            try {
                $content = Get-Content $subtitleFile.Name -ErrorAction Stop
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
            } catch {
                Write-Host "  Error reading subtitle file for $videoTitle"
                Add-Content $transcriptionFile ("`n** Video: {0} (ID: {1}) **`n" -f $videoTitle, $videoId)
                Add-Content $transcriptionFile "Error reading subtitle file."
                Add-Content $transcriptionFile "`n"
            }
        } else {
            Write-Host ("  No subtitles found for {0}" -f $videoTitle)
            Add-Content $transcriptionFile ("`n** Video: {0} (ID: {1}) **`n" -f $videoTitle, $videoId)
            Add-Content $transcriptionFile "No subtitles available for this video."
            Add-Content $transcriptionFile "`n"
        }
        
        # Clean up any downloaded subtitle files to save space
        Get-ChildItem -Path "." -Filter "$videoId.en.*" -ErrorAction SilentlyContinue | Remove-Item -Force
    }
} finally {
    # Restore original directory
    Set-Location $originalDir
}

Write-Host ("Transcriptions saved to {0}" -f $transcriptionFile)
Write-Host ("Processed {0} videos." -f $processedCount)