# Dentro de la foto — convierte fotos en escenas 3D (Gaussian splat) con Apple ML Sharp.
# Uso: arrastra una o varias fotos encima de "foto-a-3d.bat".
# La primera vez instala todo (~5 GB, 10-20 min). Después tarda segundos por foto.

param([Parameter(ValueFromRemainingArguments = $true)] [string[]] $Fotos)
$ErrorActionPreference = "Stop"
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8

$Base   = Join-Path $env:USERPROFILE "dentro-de-la-foto"
$Repo   = Join-Path $Base "ml-sharp"
$Venv   = Join-Path $Repo ".venv"
$Salida = Join-Path ([Environment]::GetFolderPath("Desktop")) "Dentro de la foto"
$Aqui   = Split-Path -Parent $MyInvocation.MyCommand.Path

function Paso($t) { Write-Host "`n==> $t" -ForegroundColor Yellow }

if (-not $Fotos -or $Fotos.Count -eq 0) {
  Write-Host "Arrastra una o varias fotos encima de foto-a-3d.bat" -ForegroundColor Red
  Read-Host "Enter para salir"; exit 1
}
New-Item -ItemType Directory -Force -Path $Base, $Salida | Out-Null

# 1) uv (gestor de Python, se instala en tu usuario, sin admin)
if (-not (Get-Command uv -ErrorAction SilentlyContinue)) {
  Paso "Instalando uv"
  powershell -ExecutionPolicy Bypass -NoProfile -Command "irm https://astral.sh/uv/install.ps1 | iex"
  $env:Path = (Join-Path $env:USERPROFILE ".local\bin") + ";" + $env:Path
}

# 2) Código de ML Sharp
if (-not (Test-Path (Join-Path $Repo "pyproject.toml"))) {
  Paso "Descargando ML Sharp de GitHub"
  $zip = Join-Path $Base "ml-sharp.zip"
  Invoke-WebRequest "https://github.com/apple/ml-sharp/archive/refs/heads/main.zip" -OutFile $zip
  Expand-Archive $zip -DestinationPath $Base -Force
  if (Test-Path $Repo) { Remove-Item $Repo -Recurse -Force }
  Rename-Item (Join-Path $Base "ml-sharp-main") "ml-sharp"
  Remove-Item $zip
}

# 3) Entorno de Python con PyTorch para tu GPU NVIDIA (CUDA 12.8)
$Py = Join-Path $Venv "Scripts\python.exe"
$Sharp = Join-Path $Venv "Scripts\sharp.exe"
if (-not (Test-Path $Sharp)) {
  Paso "Creando entorno Python 3.13 e instalando PyTorch con CUDA (tarda un rato)"
  Push-Location $Repo
  uv venv --python 3.13 $Venv
  uv pip install --python $Py torch==2.8.0 torchvision==0.23.0 --index-url https://download.pytorch.org/whl/cu128
  uv pip install --python $Py -e .
  Pop-Location
}

& $Py -c "import torch; print('GPU:', torch.cuda.get_device_name(0) if torch.cuda.is_available() else 'NO DETECTADA (va a usar CPU, mas lento)')"

# 4) Convertir cada foto
$Tmp = Join-Path $Base "entrada"
foreach ($f in $Fotos) {
  if (-not (Test-Path $f)) { continue }
  $nombre = [IO.Path]::GetFileNameWithoutExtension($f)
  Paso "Convirtiendo $nombre"
  if (Test-Path $Tmp) { Remove-Item $Tmp -Recurse -Force }
  New-Item -ItemType Directory -Path $Tmp | Out-Null
  Copy-Item $f $Tmp
  & $Sharp predict -i $Tmp -o $Salida
  $ply = Join-Path $Salida "$nombre.ply"
  if (Test-Path $ply) {
    & $Py (Join-Path $Aqui "optimizar_quest.py") $ply (Join-Path $Salida "$nombre-quest.ply")
  } else {
    Write-Host "No salio el .ply de $nombre" -ForegroundColor Red
  }
}

Paso "Listo. Tus escenas estan en: $Salida"
Write-Host "Usa el archivo que termina en -quest.ply para el Quest." -ForegroundColor Green
explorer.exe $Salida
Read-Host "Enter para cerrar"
