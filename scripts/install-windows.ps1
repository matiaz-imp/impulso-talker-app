<#
.SYNOPSIS
  Instala Impulso Talker en Windows 10/11 (64 bits) desde el instalador publicado en GitHub Releases.

.DESCRIPTION
  Probado en un Windows de pruebas de GitHub Actions (workflow «Smoke de instaladores»); todavía no en el
  computador de una persona. Si algo falla, descarga el instalador `*x64-setup.exe` a mano desde la página
  de Releases y ejecútalo.

  No requiere permisos de administrador: el instalador de la app es por usuario.
  El instalador no está firmado: SmartScreen mostrará un aviso («Más información → Ejecutar de todas formas»).

  Para repositorios privados necesita un token: tener GitHub CLI con sesión iniciada (`gh auth login`) o la
  variable GH_TOKEN.

.PARAMETER Repo
  Repositorio con las releases, en formato dueño/nombre. También se lee de la variable IMPULSO_TALKER_REPO.

.PARAMETER Silencioso
  Instala sin ventanas (parámetro /S del instalador NSIS).

.PARAMETER IncluirBorrador
  Permite instalar desde una release en borrador (solo para pruebas).

.EXAMPLE
  .\scripts\install-windows.ps1 -Repo matiaz-imp/impulso-talker-app
#>
param(
  [string]$Repo = $env:IMPULSO_TALKER_REPO,
  [switch]$Silencioso,
  [switch]$IncluirBorrador
)

$ErrorActionPreference = "Stop"

if ($env:OS -ne "Windows_NT") { throw "Este script es solo para Windows." }
if ($env:PROCESSOR_ARCHITECTURE -ne "AMD64") {
  throw "Arquitectura no soportada ($env:PROCESSOR_ARCHITECTURE). Impulso Talker solo publica instalador para Windows de 64 bits (AMD64)."
}
if (-not $Repo) { throw "Indica el repositorio: -Repo dueño/impulso-talker (o define IMPULSO_TALKER_REPO)." }

# Token (opcional): sirve para repositorios privados y borradores
$token = $env:GH_TOKEN
if (-not $token -and (Get-Command gh -ErrorAction SilentlyContinue)) {
  try { $token = (gh auth token 2>$null) } catch { $token = $null }
}
$cabeceras = @{ "User-Agent" = "impulso-talker-installer"; "Accept" = "application/vnd.github+json" }
if ($token) { $cabeceras["Authorization"] = "Bearer $token" }

Write-Host "==> Buscando la última release de $Repo"
try {
  $releases = Invoke-RestMethod "https://api.github.com/repos/$Repo/releases" -Headers $cabeceras
} catch {
  throw "No pude leer las releases de $Repo. Si el repositorio es privado, ejecuta 'gh auth login' (GitHub CLI) o define GH_TOKEN y repite."
}
# La primera release (la más nueva) que traiga un instalador de Windows
$release = $releases | Where-Object {
  -not $_.prerelease -and ($IncluirBorrador -or -not $_.draft) -and ($_.assets | Where-Object { $_.name -like "*x64-setup.exe" })
} | Select-Object -First 1
if (-not $release) { throw "No hay ninguna release publicada en $Repo con un instalador *x64-setup.exe (¿está en borrador? usa -IncluirBorrador)." }
$asset = $release.assets | Where-Object { $_.name -like "*x64-setup.exe" } | Select-Object -First 1

$destino = Join-Path $env:TEMP "impulso-talker-instalador"
New-Item -ItemType Directory -Force -Path $destino | Out-Null
$ruta = Join-Path $destino $asset.name
Write-Host "==> Descargando $($asset.name) ($([math]::Round($asset.size / 1MB, 1)) MB) de la release $($release.tag_name)"
$cabDescarga = $cabeceras.Clone(); $cabDescarga["Accept"] = "application/octet-stream"
Invoke-WebRequest "https://api.github.com/repos/$Repo/releases/assets/$($asset.id)" -Headers $cabDescarga -OutFile $ruta

if ($Silencioso) {
  Write-Host "==> Instalando en silencio"
  Start-Process -FilePath $ruta -ArgumentList "/S" -Wait
} else {
  Write-Host "==> Abriendo el instalador. Si aparece una ventana azul de SmartScreen: Más información → Ejecutar de todas formas."
  Start-Process -FilePath $ruta -Wait
}

$exe = Join-Path $env:LOCALAPPDATA "Impulso Talker\handy.exe"
if (Test-Path $exe) { Write-Host "==> Instalado en $exe" }
else { Write-Host "==> El instalador terminó, pero no encontré $exe (¿lo instalaste en otra carpeta?)." }

Write-Host ""
Write-Host "Listo. Lo que sigue lo hace la persona:"
Write-Host "  1. Abrir Impulso Talker desde el menú Inicio y seguir la guía de bienvenida (acepta el permiso de micrófono)."
Write-Host "  2. Elegir y descargar un modelo (Whisper Small si el equipo es lento)."
Write-Host "  3. Probar: mantener Ctrl + Espacio y hablar en un campo de texto."
