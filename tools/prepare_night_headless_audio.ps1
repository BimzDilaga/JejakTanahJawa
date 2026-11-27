param([Parameter(Mandatory=$true)][string]$Ffmpeg)
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$sourceRoot = Join-Path $projectRoot 'assets/SFX & Soundtrack'
$musicRoot = Join-Path $projectRoot 'assets/Generated/Audio/Music'
New-Item -ItemType Directory -Force -Path $musicRoot | Out-Null
$tracks = @(
    @{ Source = 'Theme song/malam.mp3'; Target = 'world-night.ogg' },
    @{ Source = 'Boss Soundtrack/Headless Swordsman/Halloween Music – The Headless Horseman.mp3'; Target = 'headless-horseman.ogg' }
)
foreach ($track in $tracks) {
    $sourceFile = Join-Path $sourceRoot $track.Source
    $outputFile = Join-Path $musicRoot $track.Target
    & $Ffmpeg -hide_banner -nostdin -y -i $sourceFile -map 0:a:0 -vn -map_metadata -1 -c:a libvorbis -q:a 4 -ar 44100 -ac 2 $outputFile
    if ($LASTEXITCODE -ne 0) { throw "Soundtrack conversion failed: $($track.Source)" }
}
Write-Output 'NIGHT_HEADLESS_AUDIO_PREPARED: 2 supplied soundtracks; source files preserved.'
