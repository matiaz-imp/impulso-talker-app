<#
.SYNOPSIS
  Instala Impulso Talker en Windows 10/11 (64 bits) desde el instalador publicado en GitHub Releases.

.DESCRIPTION
  ESTADO: SIN PROBAR en un equipo Windows real (el proyecto se desarrolló en un Mac). Si algo falla,
  descarga el instalador `*x64-setup.exe` a mano desde la página de Releases y ejecútalo.

  No requiere permisos de administrador: el instalador de la app es por usuario.
  El instalador no está firmado: SmartScreen mostrará un aviso («Más información → Ejecutar de todas formas»).

.PARAMETER Repo
  Repositorio con las releases, en formato dueño/nombre. También se lee de la variable IMPULSO_TALKER_REPO.

.PARAMETER Silencioso
  Instala sin ventanas (parámetro /S del instalador NSIS).

.EXAMPLE
  .\scripts\install-windows.ps1 -Repo agenciaimpulsa/impulso-talker
#>
param(
  [string]$Repo = $env:IMPULSO_TALKER_REPO,
  [switch]$Silencioso
)

$ErrorActionPreference = "Stop"

if ($env:OS -ne "Windows_NT") { throw "Este script es solo para Windows." }
if ($env:PROCESSOR_ARCHITECTURE -ne "AMD64") {
  throw "Arquitectura no soportada ($env:PROCESSOR_ARCHITECTURE). Impulso Talker solo publica instalador para Windows de 64 bits (AMD64)."
}
if (-not $Repo) { throw "Indica el repositorio: -Repo dueño/impulso-talker (o define IMPULSO_TALKER_REPO)." }

$destino = Join-Path $env:TEMP "impulso-talker-instalador"
New-Item -ItemType Directory -Force -Path $destino | Out-Null
$exe = $null

if (Get-Command gh -ErrorAction SilentlyContinue) {
  Write-Host "==> Descargando el último instalador con gh (sirve también para repositorios privados)"
  gh release download --repo $Repo --pattern "*x64-setup.exe" --dir $destino --clobber
  $exe = Get-ChildItem $destino -Filter "*x64-setup.exe" | Sort-Object LastWriteTime -Descending | Select-Object -First 1
} else {
  Write-Host "==> Descargando el último instalador desde la API pública de GitHub"
  try {
    $release = Invoke-RestMethod "https://api.github.com/repos/$Repo/releases/latest" -Headers @{ "User-Agent" = "impulso-talker-installer" }
  } catch {
    throw "No pude leer las releases de $Repo. Si el repositorio es privado, instala GitHub CLI (winget install GitHub.cli), ejecuta 'gh auth login' y repite."
  }
  $asset = $release.assets | Where-Object { $_.name -like "*x64-setup.exe" } | Select-Object -First 1
  if (-not $asset) { throw "La release $($release.tag_name) no tiene un instalador *x64-setup.exe." }
  $ruta = Join-Path $destino $asset.name
  Invoke-WebRequest $asset.browser_download_url -OutFile $ruta
  $exe = Get-Item $ruta
}

if (-not $exe) { throw "No se descargó ningún instalador." }
Write-Host "==> Instalador: $($exe.FullName) ($([math]::Round($exe.Length / 1MB, 1)) MB)"

if ($Silencioso) {
  Start-Process -FilePath $exe.FullName -ArgumentList "/S" -Wait
  Write-Host "==> Instalado."
} else {
  Write-Host "==> Abriendo el instalador. Si aparece una ventana azul de SmartScreen: Más información → Ejecutar de todas formas."
  Start-Process -FilePath $exe.FullName -Wait
}

Write-Host ""
Write-Host "Listo. Lo que sigue lo hace la persona:"
Write-Host "  1. Abrir Impulso Talker desde el menú Inicio y seguir la guía de bienvenida (acepta el permiso de micrófono)."
Write-Host "  2. Elegir y descargar un modelo (Whisper Small si el equipo es lento)."
Write-Host "  3. Probar: mantener Ctrl + Espacio y hablar en un campo de texto."
