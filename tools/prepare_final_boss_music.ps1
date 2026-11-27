param([Parameter(Mandatory=$true)][string]$Ffmpeg)
$ErrorActionPreference = 'Stop'
$projectRoot = Split-Path -Parent $PSScriptRoot
$sourceFile = Join-Path $projectRoot "assets/SFX & Soundtrack/Boss Soundtrack/Final Boss/National Anthem of the Netherlands but it's a boss theme.mp3"
$outputFile = Join-Path $projectRoot 'assets/Generated/Audio/Music/commander-final-theme.ogg'
& $Ffmpeg -hide_banner -nostdin -y -i $sourceFile -map 0:a:0 -vn -map_metadata -1 -c:a libvorbis -q:a 4 -ar 44100 -ac 2 $outputFile
if ($LASTEXITCODE -ne 0) { throw 'Final boss music conversion failed.' }
Write-Output 'FINAL_BOSS_MUSIC_PREPARED: supplied soundtrack; original source preserved.'
