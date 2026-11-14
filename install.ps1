# Video Studio: instala todas las skills de video para Claude Code (Windows).
# Uso:  irm https://raw.githubusercontent.com/Macc961112/video-studio/main/install.ps1 | iex
$ErrorActionPreference = 'Stop'

$Repo   = 'Macc961112/video-studio'
$Dest   = Join-Path $HOME '.claude\skills'
$Backup = Join-Path $HOME ('.claude\skills-backup\' + (Get-Date -Format 'yyyyMMdd-HHmmss'))
$Tmp    = Join-Path ([IO.Path]::GetTempPath()) ('vs-' + [guid]::NewGuid().ToString('N').Substring(0, 8))

# Repos que traen varias skills dentro de una carpeta skills/
$Packs = @(
  $Repo,
  'charlie947/motion-graphics-skills',
  'remotion-dev/skills',
  '0xS4N4TG/papercut-explainer'
)
# Repos que son una sola skill (se instalan enteros para poder hacer git pull)
$Singles = [ordered]@{
  'ffmpeg-skill'  = 'kajisho5/ffmpeg-skill'
  'ghost-editor'  = 'kurbaitaev/ghost-editor'
  'claude-shorts' = 'agricidaniel/claude-shorts'
}

if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
  throw 'Necesitas Git. Descargalo en https://git-scm.com/download/win y vuelve a ejecutar este comando.'
}

function Get-Repo($repo, $dir) {
  git -c core.longpaths=true clone -q --depth 1 "https://github.com/$repo.git" $dir
  if ($LASTEXITCODE) { throw "No se pudo descargar $repo" }
}

# Nunca borra: si la skill ya existe, la mueve a la copia de seguridad.
function Set-Skill($src, $name) {
  $target = Join-Path $Dest $name
  if (Test-Path $target) {
    New-Item -ItemType Directory -Force $Backup | Out-Null
    Move-Item $target (Join-Path $Backup $name)
  }
  Move-Item $src $target
  Write-Host "  + $name" -ForegroundColor Green
}

New-Item -ItemType Directory -Force $Dest, $Tmp | Out-Null
$count = 0
try {
  Write-Host "`nVideo Studio: instalando skills en $Dest`n" -ForegroundColor Cyan
  $i = 0
  foreach ($r in $Packs) {
    $i++; $dir = Join-Path $Tmp "p$i"
    Write-Host "Descargando $r ..."
    Get-Repo $r $dir
    foreach ($s in Get-ChildItem (Join-Path $dir 'skills') -Directory) { Set-Skill $s.FullName $s.Name; $count++ }
  }
  foreach ($name in $Singles.Keys) {
    Write-Host "Descargando $($Singles[$name]) ..."
    Get-Repo $Singles[$name] (Join-Path $Tmp $name)
    Set-Skill (Join-Path $Tmp $name) $name; $count++
  }
}
finally {
  Remove-Item $Tmp -Recurse -Force -ErrorAction SilentlyContinue
}

# lemo-opuscar es un plugin, no una skill suelta.
$plugin = $false
if (Get-Command claude -ErrorAction SilentlyContinue) {
  claude plugin marketplace add lemomo-ai/lemo-opuscar
  claude plugin install lemo-opuscar@lemolab
  $plugin = ($LASTEXITCODE -eq 0)
}

Write-Host "`nListo: $count skills instaladas." -ForegroundColor Cyan
if (Test-Path $Backup) { Write-Host "Las versiones anteriores se guardaron en $Backup" }
if (-not $plugin) {
  Write-Host "`nPara el plugin lemo-opuscar, escribe esto dentro de Claude Code:"
  Write-Host '  /plugin marketplace add lemomo-ai/lemo-opuscar'
  Write-Host '  /plugin install lemo-opuscar@lemolab'
}
Write-Host "`nReinicia Claude Code y escribe /video-studio para empezar."
Write-Host 'Algunas skills necesitan programas extra (FFmpeg, Python, Node). Cada una te lo pedira la primera vez.'
