param(
    [Parameter(Mandatory=$true)][string]$Ffmpeg,
    [string]$NightSource = ''
)
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$musicRoot = Join-Path $projectRoot 'assets/Generated/Audio/Music'
New-Item -ItemType Directory -Force -Path $musicRoot | Out-Null
$musicSources = [ordered]@{ 'day' = (Join-Path $projectRoot 'assets/SFX & Soundtrack/Theme song/Theme song siang.mpeg') }
if ($NightSource) { $musicSources['night'] = (Resolve-Path -LiteralPath $NightSource).Path }
foreach ($period in $musicSources.Keys) {
    $sourceFile = $musicSources[$period]
    $outputFile = Join-Path $musicRoot ("world-$period.ogg")
    & $Ffmpeg -hide_banner -nostdin -y -i $sourceFile -map 0:a:0 -vn -map_metadata -1 -c:a libvorbis -q:a 4 -ar 44100 -ac 2 $outputFile
    if ($LASTEXITCODE -ne 0) { throw "Failed to prepare world soundtrack: $period" }
}
if ($NightSource) {
    $settingsPath = Join-Path $projectRoot 'data/world_audio.json'
    $settings = Get-Content -LiteralPath $settingsPath -Raw | ConvertFrom-Json
    $settings.night_music = 'res://assets/Generated/Audio/Music/world-night.ogg'
    $settings.note = 'Soundtrack siang dan malam disiapkan dari berkas sumber pengguna.'
    $settings | ConvertTo-Json -Depth 4 | Set-Content -LiteralPath $settingsPath -Encoding utf8
}
Write-Output 'WORLD_SOUNDTRACKS_PREPARED'
