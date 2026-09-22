# RESUMEN Y ARQUITECTURA

## Propósito general

Herramienta de línea de comandos, escrita en PowerShell, para el canal de YouTube [@TheNextNewThingAI](https://www.youtube.com/@TheNextNewThingAI). Recorre los videos publicados en los últimos 30 días, descarga los subtítulos en inglés con `yt-dlp` (sin descargar el video), elimina números de secuencia y marcas de tiempo del formato SRT, y concatena el texto plano en un único archivo.

No hay aplicación web, API, base de datos, tests ni empaquetado. El repositorio contiene cinco iteraciones del mismo script, un README, un `.gitignore` y un volcado de salida ya generado.

El README designa `get_youtube_transcripts.ps1` como script principal y `get_youtube_transcripts_debug.ps1` como variante de depuración. Las demás copias son iteraciones experimentales. `get_youtube_transcripts_final.ps1` repite la tubería del script principal y añade un tope de 50 videos.

## Stack tecnológico, lenguajes, frameworks y dependencias

- Lenguaje único del proyecto: PowerShell. Todos los scripts empiezan con `$ErrorActionPreference = "Stop"`. El README indica ejecutarlos con `pwsh -File`.
- Dependencia externa obligatoria: [yt-dlp](https://github.com/yt-dlp/yt-dlp). Si `Get-Command yt-dlp` no lo encuentra, cada script ejecuta `pip install yt-dlp`.
- Runtime de JavaScript declarado en las cuatro versiones posteriores a la primera: Deno, mediante el flag `--js-runtimes deno` (lo usa el extractor de YouTube de yt-dlp). `get_transcriptions.ps1` no pasa ese flag.
- Frameworks de aplicación: ninguno. No hay `package.json`, `requirements.txt`, `pyproject.toml`, Dockerfile ni configuración de CI.
- Control de versiones: Git, rama `master`, remoto `origin`. La carpeta `.git` existe en disco y queda fuera de este documento.

Canal fijo en los cinco scripts:

```
https://www.youtube.com/@TheNextNewThingAI/videos
```

## Flujo de datos

```
https://www.youtube.com/@TheNextNewThingAI/videos
        |
        |  yt-dlp --flat-playlist --print-json --dateafter YYYYMMDD
        v
videos_info.json   (un objeto JSON por línea: id, title, ...)
        |
        |  por cada video: https://www.youtube.com/watch?v=<id>
        v
yt-dlp --skip-download --write-sub --sub-lang en --sub-format srt
        |
        |  si no existe <id>.en.srt
        v
yt-dlp --skip-download --write-auto-sub --sub-lang en --sub-format srt
        |
        |  descartar líneas que coinciden con ^\d+$ o que contienen "-->"
        v
all_transcripts.txt
        |
        v
borrar archivos temporales <id>.en.*
```

La fecha límite es `(Get-Date).AddDays(-30).ToString("yyyyMMdd")`, pasada a `--dateafter`.

Formato de cada bloque en las versiones maduras (`get_youtube_transcripts.ps1`, `_debug.ps1`, `_final.ps1` y `get_transcriptions_v2.ps1`):

```
** Video: <título> (ID: <videoId>) **

<texto plano>
```

Si no hay subtítulos, el bloque se escribe igual y el cuerpo es la frase `No subtitles available for this video.` Si el archivo de subtítulos no se puede leer, el cuerpo es `Error reading subtitle file.`

La iteración más antigua (`get_transcriptions.ps1`) usa otro encabezado, `=== Video: <título> (ID: <videoId>) ===`, y omite por completo los videos sin subtítulos.

## Árbol de directorios y archivos relevantes

Se excluyen `.git` y cualquier carpeta de build, binarios o dependencias. En este repositorio no existen `node_modules`, `bin`, `obj` ni `venv`.

```
youtube-transcript-processor/
├── .gitignore
├── README.md
├── get_transcriptions.ps1                 # iteración 1
├── get_transcriptions_v2.ps1              # iteración 2
├── get_youtube_transcripts.ps1            # script principal según el README
├── get_youtube_transcripts_debug.ps1      # depuración, tope de 5 videos
├── get_youtube_transcripts_final.ps1      # misma tubería que el principal, tope de 50
└── youtube_transcripts/
    └── all_transcripts.txt                # salida generada (no es código)
```

## Artefacto generado

`youtube_transcripts/all_transcripts.txt` está versionado en el repositorio. Pesa 430809 bytes y tiene 11274 líneas, UTF-8 sin BOM. Es el producto de una ejecución, no código fuente, y su cuerpo no se copia en la sección 2.

El primer bloque real del archivo empieza así (muestra de las primeras líneas; el resto del archivo sigue el mismo patrón de un cue por línea con la línea en blanco del SRT conservada):

```
** Video: New: AI seller + phone for your agent + OpenClaw 2.0 boy-is-it-bad (ID: MaTkyO-8hZ0) **

I have an AI pitchwoman who can sell

anything for you. You're going to see
```

`.gitignore` ignora subtítulos temporales (`*.en.srt`, `*.en.vtt`), los JSON regenerables (`*/videos.json`, `*/videos_info.json`) y basura de sistema (`.DS_Store`, `Thumbs.db`, `*.log`, `*.tmp`, `*.temp`). No ignora `all_transcripts.txt`.

## Mapa de los cinco scripts

Los cinco apuntan al mismo canal y a la misma ventana de 30 días. Cambian la ruta de salida, el tope de videos, el fallback a subtítulos automáticos y el nombre de archivo SRT que buscan después de la descarga.

| Archivo | Rol | Directorio de salida (absoluto, fijo en el script) | Tope | Subtítulos automáticos | SRT que busca | Limpia temporales | Encabezado |
|---|---|---|---|---|---|---|---|
| `get_transcriptions.ps1` | Iteración 1 | `D:\projects\RadarTheNewThing\transcriptions` | ninguno | no | `<id>.srt` | no | `=== Video: ... ===` |
| `get_transcriptions_v2.ps1` | Iteración 2 | `D:\projects\RadarTheNewThing\transcriptions_v2` | 20 | no | `<id>.srt` | no | `** Video: ... **` |
| `get_youtube_transcripts.ps1` | Principal según el README | `D:\projects\RadarTheNewThing\youtube_transcripts` | ninguno | sí, si falta `<id>.en.srt` | `<id>.en.*` | sí | `** Video: ... **` |
| `get_youtube_transcripts_debug.ps1` | Depuración verbosa | `D:\projects\RadarTheNewThing\youtube_transcripts_debug` | 5 | sí | `<id>.en.*` | sí | `** Video: ... **` |
| `get_youtube_transcripts_final.ps1` | Variante con tope | `D:\projects\RadarTheNewThing\youtube_transcripts` | 50 | sí | `<id>.en.*` | sí | `** Video: ... **` |

Nombres de los archivos que produce cada familia:

- Iteraciones 1 y 2: listado `videos.json` y transcripción acumulada `all_transcriptions.txt`.
- Las tres versiones `get_youtube_transcripts*.ps1`: listado `videos_info.json` y transcripción acumulada `all_transcripts.txt`.

El README describe la salida como `youtube_transcripts\all_transcripts.txt`, relativa al directorio de trabajo. Los cinco scripts escriben siempre bajo `D:\projects\RadarTheNewThing\`, fuera de este repositorio. La copia versionada `youtube_transcripts\all_transcripts.txt` usa el encabezado `** Video: ... **` de las versiones maduras.

`get_youtube_transcripts.ps1` y `get_youtube_transcripts_final.ps1` comparten directorio de salida. Ejecutar uno y después el otro reescribe el mismo `all_transcripts.txt` y el mismo `videos_info.json`.

## Etapas de las versiones maduras

Aplica a `get_youtube_transcripts.ps1`, `get_youtube_transcripts_debug.ps1` y `get_youtube_transcripts_final.ps1`.

1. Comprobar `yt-dlp` en el `PATH`. Si falta, `pip install yt-dlp`.
2. Crear el directorio de salida si no existe (`New-Item -ItemType Directory`).
3. Calcular la fecha límite `yyyyMMdd`.
4. Listar el tab `/videos` del canal:

```
yt-dlp --js-runtimes deno --dateafter <fecha> --no-warnings --ignore-errors --print-json --flat-playlist "<channelUrl>"
```

`_debug` recorta con `select -first 5` y `_final` con `select -first 50` (`select` es el alias de `Select-Object`). Cada línea guardada es un JSON independiente. Si el archivo no existe o tiene 0 líneas, el script termina con `exit`.

5. Vaciar la transcripción acumulada con `Set-Content -Path <archivo> -Value ''`.
6. Guardar `Get-Location`, hacer `Set-Location` al directorio de salida dentro de `try/finally`, y restaurar el directorio al salir. La plantilla de yt-dlp queda en `%(id)s.%(ext)s` y el SRT cae en ese directorio.
7. Por cada línea: `ConvertFrom-Json`, leer `.id` y `.title`, construir `https://www.youtube.com/watch?v=<id>`.
8. Invocar yt-dlp mediante un array de argumentos y el operador splat (`& yt-dlp @args`), para que PowerShell no trate el `%` de la plantilla como operador de formato. Flags comunes:

- `--js-runtimes deno`
- `--skip-download`
- `--write-sub` en el primer intento; `--write-auto-sub` en el segundo
- `--sub-format srt`
- `--sub-lang en`
- `--no-warnings --ignore-errors --geo-bypass`
- `-o %(id)s.%(ext)s`

Con `--sub-lang en`, yt-dlp nombra el archivo `<id>.en.srt` (o `<id>.en.vtt` si no respeta el formato pedido). Por eso estas versiones buscan `<id>.en.*`.

9. Leer el primer archivo que coincida. Conservar la línea cuando no cumple `^\d+$` y no contiene `-->`. Unir con `` `n ``. Añadir encabezado, cuerpo y una línea en blanco mediante `Add-Content`.
10. Borrar `<id>.en.*` con `Remove-Item -Force`.

## Diferencias que cambian el resultado

- `get_transcriptions.ps1` hace dos llamadas de canal, no una por video. La primera es `yt-dlp --dateafter <fecha> -j <channelUrl>` (`-j` es `--dump-json`: metadatos completos, no el listado plano `--print-json --flat-playlist`). La segunda descarga todos los subtítulos del canal de una vez, con plantilla `"$outputDir\%(id)s.%(ext)s"`. Entre comillas dobles de PowerShell, `%` llega literal a yt-dlp, así que esa plantilla es válida. Después busca `<id>.srt`. Con `--sub-lang en` el nombre habitual es `<id>.en.srt`, y el `Test-Path` puede fallar aunque el SRT se haya escrito. Los videos sin subtítulo no aparecen en la salida. `Clear-Content` sobre `all_transcriptions.txt` falla si el archivo todavía no existe, porque la preferencia de error es `Stop`. No usa Deno ni `try/finally`.

- `get_transcriptions_v2.ps1` sí procesa video a video, con tope 20, y sigue buscando `<id>.srt`. La plantilla se arma con `Join-Path $outputDir ("%%(id)s.%%(ext)s")`, así que yt-dlp recibe el texto literal `%%(id)s.%%(ext)s`, que no es la plantilla `%(id)s`. No hay fallback a subtítulos automáticos ni borrado de temporales.

- `get_youtube_transcripts_final.ps1` coincide con el script principal salvo el tope de 50 videos y un detalle de limpieza: antes del primer intento borra solo `<id>.en.srt`; antes del fallback borra `<id>.en.*`. El script principal borra `<id>.en.*` ya en el primer intento.

- `get_youtube_transcripts_debug.ps1` añade `Write-Host` en cada fase, enumera los SRT encontrados con su tamaño en bytes y, si la lectura falla, imprime `$_.Exception.Message` en consola. El archivo de salida recibe la misma frase fija `Error reading subtitle file.` que las otras versiones maduras. Tope de 5 videos y directorio propio.

## Ejecución

Requisitos que declara el README: PowerShell y yt-dlp instalado con `pip install yt-dlp`. Las versiones que pasan `--js-runtimes deno` necesitan además el runtime Deno.

```
pwsh -File get_youtube_transcripts.ps1
```

Ese script escribe en `D:\projects\RadarTheNewThing\youtube_transcripts\all_transcripts.txt`.

## Ausencias útiles para no inferir estructura que no existe

- No hay tests, linter, configuración de editor, CI, licencia ni manifiesto de dependencias.
- No hay código Python, JavaScript ni de aplicación propio. `pip` aparece solo para instalar yt-dlp.
- Los JSON intermedios (`videos.json`, `videos_info.json`) y los SRT temporales se generan en la ruta `D:\projects\RadarTheNewThing\...`. `.gitignore` los excluye si alguna copia cae dentro del repo.
- No hay carpetas de build, binarios, `node_modules` ni `venv`. `.git` existe y se omite en la sección 2.

# ARCHIVOS DEL PROYECTO

Cada bloque es el contenido íntegro del archivo en disco, en este orden: documentación, configuración y scripts (primero el que el README marca como principal, después las variantes). Codificación de origen: UTF-8 sin BOM. Los finales de línea CRLF del archivo original se conservan dentro del bloque.

`youtube_transcripts/all_transcripts.txt` es salida generada (430809 bytes, 11274 líneas) y no se incluye aquí. Su formato está descrito en la sección 1.

## Ruta: `README.md`

````markdown
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
````

## Ruta: `.gitignore`

```gitignore
# Temporary subtitle files
*.en.srt
*.en.vtt

# Large JSON files that can be regenerated
*/videos.json
*/videos_info.json

# OS and editor files
.DS_Store
Thumbs.db
*.log
*.tmp
*.temp
```

## Ruta: `get_youtube_transcripts.ps1`

```powershell
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
```

## Ruta: `get_youtube_transcripts_final.ps1`

```powershell
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
# Get video IDs and basic info, limit to 50 videos
yt-dlp --js-runtimes deno --dateafter $date --no-warnings --ignore-errors --print-json --flat-playlist "$channelUrl" | select -first 50 > $jsonFile

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

        # Try to download English subtitles first
        Remove-Item -Path "$videoId.en.srt" -ErrorAction SilentlyContinue
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
        
        if (-not (Test-Path "$videoId.en.srt")) {
            # Try to download auto-generated English captions
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

        # Check if we got any subtitle file (could be .srt or potentially .vtt)
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
```

## Ruta: `get_youtube_transcripts_debug.ps1`

```powershell
$ErrorActionPreference = "Stop"

# Check for yt-dlp
if (-not (Get-Command yt-dlp -ErrorAction SilentlyContinue)) {
    Write-Host "Installing yt-dlp..."
    pip install yt-dlp
}

$outputDir = "D:\projects\RadarTheNewThing\youtube_transcripts_debug"
if (-not (Test-Path $outputDir)) {
    New-Item -ItemType Directory -Path $outputDir
}

$date = (Get-Date).AddDays(-30).ToString("yyyyMMdd")
$channelUrl = "https://www.youtube.com/@TheNextNewThingAI/videos"
$jsonFile = "$outputDir\videos_info.json"

Write-Host "Fetching video list from the last 30 days..."
# Get video IDs and basic info, limit to 5 videos for debugging
yt-dlp --js-runtimes deno --dateafter $date --no-warnings --ignore-errors --print-json --flat-playlist "$channelUrl" | select -first 5 > $jsonFile

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

        Write-Host ("`n=== Processing video {0}/{1}: {2} ===" -f $processedCount, $videoCount, $videoTitle)

        # Try to download English subtitles first
        Write-Host "  Removing any existing subtitle files..."
        Remove-Item -Path "$videoId.en.*" -ErrorAction SilentlyContinue
        
        Write-Host "  Trying regular subtitles..."
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
        
        Write-Host "  Running yt-dlp for regular subs..."
        & yt-dlp @args
        
        if (Test-Path "$videoId.en.srt") {
            Write-Host "  Found regular subtitle file: $videoId.en.srt"
        } else {
            Write-Host "  No regular subtitle file found, trying auto-generated captions..."
            # Try to download auto-generated English captions
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
            Write-Host "  Running yt-dlp for auto-subs..."
            & yt-dlp @argsAuto
        }

        # Check if we got any subtitle file
        Write-Host "  Checking for subtitle files..."
        $subtitleFiles = Get-ChildItem -Path "." -Filter "$videoId.en.*" -ErrorAction SilentlyContinue
        Write-Host ("  Found {0} subtitle files matching pattern" -f $subtitleFiles.Count)
        if ($subtitleFiles) {
            Write-Host "  Subtitle files found:"
            foreach ($sf in $subtitleFiles) {
                Write-Host ("    {0} ({1} bytes)" -f $sf.Name, $sf.Length)
            }
        }
        
        $subtitleFile = $subtitleFiles | Select-Object -First 1
        
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
                Write-Host ("  Successfully processed subtitles for {0}" -f $videoTitle)
            } catch {
                Write-Host ("  Error reading subtitle file for {0}: {1}" -f $videoTitle, $_.Exception.Message)
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
        Write-Host "  Cleaning up subtitle files..."
        Get-ChildItem -Path "." -Filter "$videoId.en.*" -ErrorAction SilentlyContinue | Remove-Item -Force
        Write-Host "  Cleanup complete."
    }
} finally {
    # Restore original directory
    Set-Location $originalDir
}

Write-Host "`n=== Final Summary ==="
Write-Host ("Transcriptions saved to {0}" -f $transcriptionFile)
Write-Host ("Processed {0} videos." -f $processedCount)
```

## Ruta: `get_transcriptions_v2.ps1`

```powershell
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
```

## Ruta: `get_transcriptions.ps1`

```powershell
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
```

