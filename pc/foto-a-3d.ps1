# Dentro de la foto — versión local (tu GPU NVIDIA)
# Convierte fotos en escenas 3D (Gaussian splat) con Apple ML Sharp.
#
# Uso:
#   - Doble clic en "foto-a-3d.bat": convierte las fotos nuevas de la carpeta "fotos"
#     (en Google Drive si tienes Drive para escritorio; si no, en el Escritorio).
#   - O arrastra fotos encima de "foto-a-3d.bat" para convertir solo esas.
# La primera vez instala todo (~5 GB, 10-20 min). Después tarda segundos por foto.

param([Parameter(ValueFromRemainingArguments = $true)] [string[]] $Fotos)
$ErrorActionPreference = "Stop"
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$Base = Join-Path $env:USERPROFILE "dentro-de-la-foto"
$Repo = Join-Path $Base "ml-sharp"
$Venv = Join-Path $Repo ".venv"
$Aqui = Split-Path -Parent $MyInvocation.MyCommand.Path
$Ext  = @(".jpg", ".jpeg", ".png", ".heic", ".heif", ".webp")

function Paso($t) { Write-Host "`n==> $t" -ForegroundColor Yellow }
function Salir($msg, $color = "Red") { Write-Host "`n$msg" -ForegroundColor $color; Read-Host "Enter para cerrar"; exit }

# ---------- 0) ¿Dónde guardar? Google Drive para escritorio si existe ----------
$DriveRoot = $null
$candidatos = @()
foreach ($d in Get-PSDrive -PSProvider FileSystem) {
  $candidatos += (Join-Path $d.Root "Mi unidad"), (Join-Path $d.Root "My Drive")
}
$candidatos += (Join-Path $env:USERPROFILE "Google Drive\Mi unidad"), (Join-Path $env:USERPROFILE "Google Drive\My Drive"),
               (Join-Path $env:USERPROFILE "Mi unidad"), (Join-Path $env:USERPROFILE "My Drive"),
               (Join-Path $env:USERPROFILE "Google Drive")
foreach ($c in $candidatos) { if (Test-Path $c) { $DriveRoot = $c; break } }

if ($DriveRoot) {
  $Salida = Join-Path $DriveRoot "Dentro de la foto"
  Write-Host "Google Drive encontrado: $Salida" -ForegroundColor Green
} else {
  $Salida = Join-Path ([Environment]::GetFolderPath("Desktop")) "Dentro de la foto"
  Write-Host "No encontré Google Drive para escritorio. Uso: $Salida" -ForegroundColor DarkYellow
}
$CarpetaFotos = Join-Path $Salida "fotos"
New-Item -ItemType Directory -Force -Path $Base, $Salida, $CarpetaFotos | Out-Null

# ---------- 1) uv (gestor de Python, sin admin) ----------
if (-not (Get-Command uv -ErrorAction SilentlyContinue)) {
  Paso "Instalando uv"
  powershell -ExecutionPolicy Bypass -NoProfile -Command "irm https://astral.sh/uv/install.ps1 | iex"
  $env:Path = (Join-Path $env:USERPROFILE ".local\bin") + ";" + $env:Path
}

# ---------- 2) Código de ML Sharp ----------
if (-not (Test-Path (Join-Path $Repo "pyproject.toml"))) {
  Paso "Descargando ML Sharp de GitHub"
  $zip = Join-Path $Base "ml-sharp.zip"
  Invoke-WebRequest "https://github.com/apple/ml-sharp/archive/refs/heads/main.zip" -OutFile $zip
  Expand-Archive $zip -DestinationPath $Base -Force
  if (Test-Path $Repo) { Remove-Item $Repo -Recurse -Force }
  Rename-Item (Join-Path $Base "ml-sharp-main") "ml-sharp"
  Remove-Item $zip
}

# ---------- 3) Python 3.13 + PyTorch con CUDA ----------
$Py    = Join-Path $Venv "Scripts\python.exe"
$Sharp = Join-Path $Venv "Scripts\sharp.exe"
if (-not (Test-Path $Sharp)) {
  Paso "Creando entorno Python e instalando PyTorch con CUDA (tarda un rato)"
  Push-Location $Repo
  uv venv --python 3.13 $Venv
  uv pip install --python $Py torch==2.8.0 torchvision==0.23.0 --index-url https://download.pytorch.org/whl/cu128
  uv pip install --python $Py -e .
  Pop-Location
  if (-not (Test-Path $Sharp)) { Salir "La instalación falló. Mándale captura de esta ventana a Claude." }
}
& $Py -c "import torch; print('GPU:', torch.cuda.get_device_name(0) if torch.cuda.is_available() else 'NO DETECTADA (va a usar CPU, MUY lento)')"

# ---------- 4) ¿Qué fotos convertir? ----------
$lista = @()
if ($Fotos -and $Fotos.Count -gt 0) {
  $lista = $Fotos | Where-Object { Test-Path $_ } | ForEach-Object { Get-Item $_ }
} else {
  $lista = Get-ChildItem $CarpetaFotos -File | Where-Object { $Ext -contains $_.Extension.ToLower() } | Where-Object {
    -not (Test-Path (Join-Path $Salida (($_.BaseName -replace ' ', '_') + "-quest.ply")))
  }
}
if (-not $lista -or $lista.Count -eq 0) {
  explorer.exe $CarpetaFotos
  Salir "No hay fotos nuevas. Pon tus fotos en:`n  $CarpetaFotos`ny vuelve a abrir foto-a-3d.bat" "Cyan"
}

# ---------- 5) Convertir ----------
$Tmp    = Join-Path $Base "entrada"
$TmpOut = Join-Path $Base "salida"
foreach ($f in $lista) {
  $nombre = $f.BaseName -replace ' ', '_'
  Paso "Convirtiendo $($f.Name)"
  foreach ($p in $Tmp, $TmpOut) { if (Test-Path $p) { Remove-Item $p -Recurse -Force }; New-Item -ItemType Directory -Path $p | Out-Null }
  Copy-Item $f.FullName (Join-Path $Tmp ($nombre + $f.Extension.ToLower()))
  & $Sharp predict -i $Tmp -o $TmpOut
  $ply = Join-Path $TmpOut "$nombre.ply"
  if (-not (Test-Path $ply)) { Write-Host "No salió el .ply de $($f.Name)" -ForegroundColor Red; continue }
  & $Py (Join-Path $Aqui "optimizar_quest.py") $ply (Join-Path $Salida "$nombre-quest.ply")
  Copy-Item $ply (Join-Path $Base "$nombre-completo.ply") -Force   # versión completa se queda en la PC
}

Paso "Listo"
Write-Host "Escenas para el Quest en: $Salida" -ForegroundColor Green
if ($DriveRoot) { Write-Host "En el Quest: drive.google.com > Dentro de la foto > descarga el -quest.ply" -ForegroundColor Green }
explorer.exe $Salida
Read-Host "Enter para cerrar"
