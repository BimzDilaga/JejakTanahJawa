param([Parameter(Mandatory=$true)][string]$Ffmpeg)
$ErrorActionPreference = 'Stop'
$projectRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..'))
$audioSources = Join-Path $projectRoot 'assets\SFX & Soundtrack'
$audioOutput = Join-Path $projectRoot 'assets\Generated\Audio'
$jobs = @(
    @{ Source='Mechanique game\Parry.mp3'; Target='Combat\parry.wav'; Music=$false },
    @{ Source='Mechanique game\Boss Stance Break.mp3'; Target='Combat\boss-stance-break.wav'; Music=$false },
    @{ Source='Boss Soundtrack\Banaspati\Donkgedank - Fight Fire (Royalty Free Epic Backsound Nusantara).mp3'; Target='Music\banaspati-fight-fire.ogg'; Music=$true },
    @{ Source='Boss Soundtrack\Soundtrack Buto Ijo\Donkgedank - Akusara (Epic Kolosal Backsound) Royalty Free.mp3'; Target='Music\buto-akusara.ogg'; Music=$true }
)
foreach ($job in $jobs) {
    $sourcePath = Join-Path $audioSources $job.Source
    $outputPath = Join-Path $audioOutput $job.Target
    New-Item -ItemType Directory -Force -Path (Split-Path $outputPath) | Out-Null
    $codec = if ($job.Music) { @('-ac','2','-c:a','libvorbis','-q:a','4') } else { @('-ac','1','-c:a','pcm_s16le') }
    & $Ffmpeg -hide_banner -loglevel error -y -i $sourcePath -vn -ar 44100 @codec $outputPath
    if ($LASTEXITCODE -ne 0) { throw "Audio conversion failed: $($job.Source)" }
}
Write-Output 'COMBAT_AUDIO_PREPARED: 2 WAV cues, 2 OGG soundtracks; original files untouched.'
