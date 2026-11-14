# Video Studio: instala todas las skills de video para Claude Code (Windows).
# Uso:  irm https://raw.githubusercontent.com/Macc961112/video-studio/main/install.ps1 | iex
$ErrorActionPreference = 'Stop'

$Repo   = 'Macc961112/video-studio'
$Dest   = Join-Path $HOME '.claude\skills'
$Backup = Join-Path $HOME ('.claude\skills-backup\' + (Get-Date -Format 'yyyyMMdd-HHmmss'))
$Tmp    = Join-Path ([IO.Path]::GetTempPath()) ('vs-' + [guid]::NewGuid().ToString('N').Substring(0, 8))

# Repos que traen varias skills: repo = carpeta donde estan (solo se descarga esa carpeta)
$Packs = [ordered]@{
  $Repo                               = 'skills'
  'charlie947/motion-graphics-skills' = 'skills'
  'remotion-dev/skills'               = 'skills'
  '0xS4N4TG/papercut-explainer'       = 'skills'
  'lemomo-ai/lemo-opuscar'            = 'plugin/skills'
}
# Repos que son una sola skill (se instalan enteros para poder hacer git pull)
$Singles = [ordered]@{
  'ffmpeg-skill'  = 'kajisho5/ffmpeg-skill'
  'ghost-editor'  = 'kurbaitaev/ghost-editor'
  'claude-shorts' = 'agricidaniel/claude-shorts'
}

if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
  throw 'Necesitas Git. Descargalo en https://git-scm.com/download/win y vuelve a ejecutar este comando.'
}

function Get-Repo($repo, $dir, $only) {
  if ($only) {
    git -c core.longpaths=true clone -q --depth 1 --filter=blob:none --sparse "https://github.com/$repo.git" $dir
    if (-not $LASTEXITCODE) { git -C $dir -c core.longpaths=true sparse-checkout set $only }
  } else {
    git -c core.longpaths=true clone -q --depth 1 "https://github.com/$repo.git" $dir
  }
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
  foreach ($r in $Packs.Keys) {
    $i++; $dir = Join-Path $Tmp "p$i"
    Write-Host "Descargando $r ..."
    Get-Repo $r $dir $Packs[$r]
    foreach ($s in Get-ChildItem (Join-Path $dir $Packs[$r]) -Directory) { Set-Skill $s.FullName $s.Name; $count++ }
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

Write-Host "`n$count skills instaladas." -ForegroundColor Cyan

# ---------- Librerias y dependencias basicas (las voces se instalan al usarlas) ----------
Write-Host "`nInstalando librerias y dependencias. Puede tardar 10-20 minutos...`n" -ForegroundColor Cyan
$Fails = @()
$env:PYTHONUTF8 = '1'                                  # sin esto la consola de Windows falla con emojis
$env:PLAYWRIGHT_DOWNLOAD_CONNECTION_TIMEOUT = '600000' # el navegador de render pesa ~100 MB
# Un paso que falla se apunta y se sigue con el siguiente.
function Step($name, [scriptblock]$run) {
  Write-Host "> $name"
  try { & $run } catch { Write-Host "  ! fallo: $name ($_)" -ForegroundColor Yellow; $script:Fails += $name }
}
function Run {
  $exe, $rest = $args
  $rest = @($rest)  # con un solo argumento, @rest partiria el texto letra a letra
  & $exe @rest
  if ($LASTEXITCODE) { throw "$(Split-Path $exe -Leaf) termino con codigo $LASTEXITCODE" }
}
function Find-Cmd($names) {
  foreach ($n in $names) {
    $c = Get-Command $n -ErrorAction SilentlyContinue | Select-Object -First 1
    if ($c -and $c.Source -notlike '*WindowsApps*') { return $c.Source }  # el "python" de la Store es un atajo vacio
  }
}
function To-Bash($p) { $p.Replace('\', '/') }
# Las herramientas de estas skills buscan Python en bin/ (como en Mac/Linux); en Windows esta en Scripts/.
function Add-BinShim($venv) {
  $bin = Join-Path $venv 'bin'
  if (-not (Test-Path (Join-Path $bin 'python.exe'))) {
    New-Item -ItemType Directory -Force $bin | Out-Null
    Copy-Item (Join-Path $venv 'Scripts\*') $bin -Recurse -Force
  }
  $exe = To-Bash (Join-Path $venv 'Scripts\python.exe')
  [IO.File]::WriteAllText((Join-Path $bin 'python'), "#!/bin/sh`nexport PYTHONUTF8=1`nexec `"$exe`" `"`$@`"`n")
}
# Plan B: en algunos Windows el descargador de Playwright falla aunque la red va bien; se baja con curl.
function Install-PlaywrightBrowsers($lib) {
  $out = & node (Join-Path $lib 'node_modules\playwright-core\cli.js') install --dry-run chromium-headless-shell
  $loc = $null
  foreach ($line in $out) {
    if ($line -match 'Install location:\s+(.+)$') { $loc = $Matches[1].Trim() }
    elseif ($loc -and $line -match 'Download url:\s+(.+)$') {
      if (-not (Test-Path (Join-Path $loc 'INSTALLATION_COMPLETE'))) {
        $zip = Join-Path ([IO.Path]::GetTempPath()) ('pw-' + [guid]::NewGuid().ToString('N') + '.zip')
        Run curl.exe -fsSL -o $zip $Matches[1].Trim()
        New-Item -ItemType Directory -Force $loc | Out-Null
        Expand-Archive $zip $loc -Force
        Remove-Item $zip
        'INSTALLATION_COMPLETE', 'DEPENDENCIES_VALIDATED' | ForEach-Object { New-Item -ItemType File -Force (Join-Path $loc $_) | Out-Null }
      }
      $loc = $null
    }
  }
}
function New-Venv($venv) {
  if (-not (Test-Path (Join-Path $venv 'Scripts\python.exe'))) { Run $PyExe -m venv $venv }
  Join-Path $venv 'Scripts\python.exe'
}

$GitDir = Split-Path (Get-Command git).Source
$Bash = 'bin\bash.exe', '..\bin\bash.exe', '..\..\bin\bash.exe' | ForEach-Object { Join-Path $GitDir $_ } | Where-Object { Test-Path $_ } | Select-Object -First 1
$Py = Find-Cmd 'py', 'python'
$PyExe = if ($Py) { (& $Py -c 'import sys; print(sys.executable)').Trim() }
$Npm = Find-Cmd 'npm.cmd'
$Missing = @()
if (-not $PyExe) { $Missing += 'Python 3.11+ (python.org)' }
if (-not $Npm) { $Missing += 'Node 20+ (nodejs.org)' }
if (-not (Find-Cmd 'ffmpeg')) { $Missing += 'FFmpeg (winget install Gyan.FFmpeg)' }
if (-not $Bash) { $Missing += 'Git Bash (viene con Git para Windows)' }
if ($Missing) { Write-Host "Faltan programas: $($Missing -join ', '). Los pasos que los necesitan se saltaran." -ForegroundColor Yellow }

$Lib   = Join-Path $HOME 'lemo-opuscar'
$Paper = Join-Path $HOME 'papercut-explainer'
$Opus  = To-Bash (Join-Path $Dest 'lemo-opuscar\scripts\setup.sh')

if ($Bash) { Step 'lemo-opuscar: libreria de estilos' { Run $Bash $Opus } }
if (Test-Path (Join-Path $Paper '.git')) { Step 'papercut: actualizar libreria' { Run git -C $Paper pull -q --ff-only } }
else { Step 'papercut: libreria' { Run git -c core.longpaths=true clone -q --depth 1 https://github.com/0xS4N4TG/papercut-explainer.git $Paper } }

if ($PyExe) {
  Step 'python3 para Git Bash' {
    $shim = Join-Path $HOME 'bin\python3'
    if (-not (Test-Path $shim)) {
      New-Item -ItemType Directory -Force (Split-Path $shim) | Out-Null
      [IO.File]::WriteAllText($shim, "#!/bin/sh`nexport PYTHONUTF8=1`nexec `"$(To-Bash $PyExe)`" `"`$@`"`n")
    }
  }
  Step 'ghost-editor: paquetes Python' { Run $PyExe -m pip install --user --quiet --disable-pip-version-check --no-warn-script-location openai-whisper numpy opencv-python pillow }
  # library_restore lanza emoji_fetch con -I, que ignora PYTHONUTF8 y falla en Windows: los emojis van aparte con -X utf8.
  Step 'ghost-editor: emojis' { Run $PyExe -X utf8 -I (Join-Path $Dest 'ghost-editor\scripts\emoji_fetch.py') }
  Step 'ghost-editor: sonidos y musica' {
    $restore = Join-Path $Dest 'ghost-editor\scripts\library_restore.py'
    foreach ($part in '--music-only', '--sfx-only', '--memes-only') { Run $PyExe -X utf8 $restore $part }
  }
  Step 'papercut: herramientas Python' {
    $v = Join-Path $HOME '.local\share\papercut-explainer\tools-venv'
    $vp = New-Venv $v
    Run $vp -m pip install --quiet --disable-pip-version-check -U pip numpy pillow soundfile
    Add-BinShim $v
    $cfg = Join-Path $HOME '.config\papercut-explainer\config.env'
    if (-not (Test-Path $cfg)) {
      New-Item -ItemType Directory -Force (Split-Path $cfg) | Out-Null
      [IO.File]::WriteAllText($cfg, "PAPERCUT_HOME=$(To-Bash $Paper)`nPAPERCUT_LIB=$(To-Bash $Paper)/library`nPAPERCUT_PY=$(To-Bash $v)/bin/python`nPYTHONUTF8=1`n")
    }
  }
  if (-not (Test-Path (Join-Path $HOME '.video-skill'))) {
    Step 'claude-shorts: Python (Whisper, PyTorch)' {
      $v = Join-Path $HOME '.shorts-skill'
      $vp = New-Venv $v
      $index = if (Get-Command nvidia-smi -ErrorAction SilentlyContinue) { 'https://download.pytorch.org/whl/cu128' } else { 'https://download.pytorch.org/whl/cpu' }
      Run $vp -m pip install --quiet --disable-pip-version-check torch torchvision torchaudio --index-url $index
      Run $vp -m pip install --quiet --disable-pip-version-check faster-whisper mediapipe numpy opencv-python
      Add-BinShim $v
    }
  }
}
if ($PyExe -and $Npm -and $Bash) {
  Step 'lemo-opuscar: dependencias' {
    $v = Join-Path $Lib '.venv'
    New-Venv $v | Out-Null
    Add-BinShim $v
    try { Run $Bash $Opus deps }
    catch {
      Write-Host '  reintentando el navegador de render con curl...'
      Install-PlaywrightBrowsers $Lib
      Run $Bash $Opus deps
    }
  }
}
if ($Npm) {
  Step 'claude-shorts: Remotion' {
    Push-Location (Join-Path $Dest 'claude-shorts\remotion')
    try { Run $Npm install --silent --no-audit --no-fund } finally { Pop-Location }
  }
}

Write-Host "`nListo." -ForegroundColor Cyan
if (Test-Path $Backup) { Write-Host "Las versiones anteriores de las skills se guardaron en $Backup" }
if ($Fails -or $Missing) {
  Write-Host 'Pendiente:' -ForegroundColor Yellow
  foreach ($m in $Missing) { Write-Host "  - instala $m y vuelve a ejecutar este comando" }
  foreach ($f in $Fails) { Write-Host "  - $f (la skill lo reintentara la primera vez que la uses)" }
}
Write-Host 'papercut renderiza en Mac/Linux; en Windows usa WSL para el render final.'
Write-Host "`nReinicia Claude Code y escribe /video-studio para empezar."
