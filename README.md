# YouTube Transcript Processor

A PowerShell script to process the last 30 days of videos from the YouTube channel @TheNextNewThingAI and download their transcriptions.

## Features

- Fetches videos posted in the last 30 days from a specified YouTube channel
- Downloads English subtitles (both regular and auto-generated captions)
- Extracts clean text from subtitle files (removing sequence numbers and timestamps)
- Formats output with each video's title in **bold** as requested
- Saves all transcriptions to a local text file
- Handles videos without subtitles gracefully
- Cleans up temporary subtitle files after processing

## Files

- `get_youtube_transcripts.ps1` - Main PowerShell script
- `get_youtube_transcripts_debug.ps1` - Debug version with verbose output
- Other versions are experimental iterations

## Usage

1. Ensure you have [yt-dlp](https://github.com/yt-dlp/yt-dlp) installed
2. Run the script in PowerShell:
   ```powershell
   pwsh -File get_youtube_transcripts.ps1
   ```
3. Transcriptions will be saved to `youtube_transcripts\all_transcripts.txt`

## Output Format

Each video section in the output file follows this format:

```
** Video: [Video Title] (ID: [VideoID]) **

[Transcription content]
```

## Requirements

- PowerShell
- yt-dlp (installed via `pip install yt-dlp`)

## Notes

- The script processes videos from the last 30 days by default
- It tries regular subtitles first, then falls back to auto-generated captions
- Videos without any subtitles will be noted as such in the output
- Temporary subtitle files are automatically cleaned up after processing