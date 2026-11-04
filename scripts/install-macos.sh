#!/usr/bin/env bash
# Instala Impulso Talker en macOS compilándolo desde el código fuente. No usa sudo.
#
#   ./scripts/install-macos.sh                  instala herramientas, compila, copia a ~/Applications y abre
#   ./scripts/install-macos.sh --solo-herramientas   instala Rust, Bun y CMake y se detiene
#   ./scripts/install-macos.sh --sin-abrir      no abre la app al terminar
#
# Variables opcionales: IMPULSO_TALKER_TOOLS (carpeta de herramientas, por defecto ~/.impulso-talker/tools)
set -euo pipefail

SOLO_HERRAMIENTAS=0
ABRIR=1
for arg in "$@"; do
  case "$arg" in
    --solo-herramientas) SOLO_HERRAMIENTAS=1 ;;
    --sin-abrir) ABRIR=0 ;;
    -h|--help) sed -n '2,9p' "$0"; exit 0 ;;
    *) echo "Opción desconocida: $arg" >&2; exit 2 ;;
  esac
done

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
TOOLS="${IMPULSO_TALKER_TOOLS:-$HOME/.impulso-talker/tools}"
CMAKE_VERSION="4.4.5"
APP_NAME="Impulso Talker"

paso() { printf '\n==> %s\n' "$*"; }
falla() { printf '\nERROR: %s\n' "$*" >&2; exit 1; }

[ "$(uname -s)" = "Darwin" ] || falla "Este script es solo para macOS."
case "$(uname -m)" in
  arm64)  RUST_TRIPLE="aarch64-apple-darwin"; BUN_ZIP="bun-darwin-aarch64.zip" ;;
  x86_64) RUST_TRIPLE="x86_64-apple-darwin";  BUN_ZIP="bun-darwin-x64.zip" ;;
  *) falla "Arquitectura no soportada: $(uname -m)" ;;
esac

paso "Comprobando las herramientas de línea de comandos de Apple"
if ! xcode-select -p >/dev/null 2>&1; then
  echo "Faltan las Command Line Tools. Se abrirá el instalador de Apple:"
  xcode-select --install || true
  falla "Termina esa instalación y vuelve a ejecutar este script."
fi
command -v git >/dev/null || falla "No se encontró git."
command -v curl >/dev/null || falla "No se encontró curl."

mkdir -p "$TOOLS" "$TOOLS/dl"
export PATH="$HOME/.cargo/bin:$TOOLS/bun:$TOOLS/cmake/CMake.app/Contents/bin:$PATH"

# Descarga $1 a $2 y comprueba que su SHA-256 sea $3
descargar_verificado() {
  local url="$1" destino="$2" esperado="$3"
  curl -fL --progress-bar -o "$destino" "$url"
  local real; real="$(shasum -a 256 "$destino" | awk '{print $1}')"
  [ "$real" = "$esperado" ] || falla "La suma SHA-256 de $(basename "$destino") no coincide (esperada $esperado, real $real). Se canceló por seguridad."
}

# --- Rust ---------------------------------------------------------------
if ! command -v cargo >/dev/null; then
  paso "Instalando Rust (rustup; en total ocupa cerca de 1 GB en disco)"
  base="https://static.rust-lang.org/rustup/dist/$RUST_TRIPLE"
  esperado="$(curl -fsSL "$base/rustup-init.sha256" | awk '{print $1}')"
  descargar_verificado "$base/rustup-init" "$TOOLS/dl/rustup-init" "$esperado"
  chmod +x "$TOOLS/dl/rustup-init"
  "$TOOLS/dl/rustup-init" -y --profile minimal --no-modify-path
else
  echo "Rust ya está instalado: $(cargo --version)"
fi

# --- Bun ----------------------------------------------------------------
if ! command -v bun >/dev/null; then
  paso "Instalando Bun (~45 MB)"
  base="https://github.com/oven-sh/bun/releases/latest/download"
  curl -fsSL -o "$TOOLS/dl/SHASUMS256.txt" "$base/SHASUMS256.txt"
  esperado="$(awk -v f="$BUN_ZIP" '$2==f {print $1}' "$TOOLS/dl/SHASUMS256.txt")"
  [ -n "$esperado" ] || falla "No se encontró la suma de $BUN_ZIP."
  descargar_verificado "$base/$BUN_ZIP" "$TOOLS/dl/$BUN_ZIP" "$esperado"
  rm -rf "$TOOLS/dl/bun-x" && mkdir -p "$TOOLS/dl/bun-x" "$TOOLS/bun"
  unzip -qo "$TOOLS/dl/$BUN_ZIP" -d "$TOOLS/dl/bun-x"
  cp "$TOOLS/dl/bun-x"/*/bun "$TOOLS/bun/bun" && chmod +x "$TOOLS/bun/bun"
else
  echo "Bun ya está instalado: $(bun --version)"
fi

# --- CMake --------------------------------------------------------------
if ! command -v cmake >/dev/null; then
  paso "Instalando CMake $CMAKE_VERSION (~90 MB)"
  base="https://github.com/Kitware/CMake/releases/download/v$CMAKE_VERSION"
  tar_name="cmake-$CMAKE_VERSION-macos-universal.tar.gz"
  curl -fsSL -o "$TOOLS/dl/cmake-sha.txt" "$base/cmake-$CMAKE_VERSION-SHA-256.txt"
  esperado="$(awk -v f="$tar_name" '$2==f {print $1}' "$TOOLS/dl/cmake-sha.txt")"
  [ -n "$esperado" ] || falla "No se encontró la suma de $tar_name."
  descargar_verificado "$base/$tar_name" "$TOOLS/dl/$tar_name" "$esperado"
  rm -rf "$TOOLS/cmake" && mkdir -p "$TOOLS/cmake"
  tar -xzf "$TOOLS/dl/$tar_name" -C "$TOOLS/cmake" --strip-components=1
else
  echo "CMake ya está instalado: $(cmake --version | head -1)"
fi

paso "Versiones"
cargo --version; bun --version; cmake --version | head -1

if [ "$SOLO_HERRAMIENTAS" = "1" ]; then
  echo; echo "Herramientas listas en $TOOLS (y Rust en ~/.cargo). Fin."
  exit 0
fi

# --- Compilación ----------------------------------------------------------
cd "$ROOT"
paso "Instalando dependencias de la interfaz"
bun install --frozen-lockfile

paso "Compilando $APP_NAME (la primera vez tarda 12-20 minutos; el equipo se pondrá a trabajar)"
export CMAKE_POLICY_VERSION_MINIMUM=3.5
bun run tauri build --bundles app
APP="$ROOT/src-tauri/target/release/bundle/macos/$APP_NAME.app"
[ -d "$APP" ] || falla "La compilación terminó sin generar $APP."

# --- Instalación ------------------------------------------------------------
paso "Copiando a ~/Applications"
mkdir -p "$HOME/Applications"
osascript -e "tell application \"$APP_NAME\" to quit" >/dev/null 2>&1 || true
rm -rf "$HOME/Applications/$APP_NAME.app"
cp -R "$APP" "$HOME/Applications/"
echo "Instalada en $HOME/Applications/$APP_NAME.app"

cat <<'FIN'

Listo. Lo que sigue lo hace la persona (el sistema no deja hacerlo por ella):
  1. Abrir la app y seguir la guía de bienvenida.
  2. Conceder Micrófono y Accesibilidad en Ajustes del Sistema → Privacidad y seguridad.
  3. Elegir y descargar un modelo (Whisper Small si el Mac es Intel o lento).
  4. Probar: mantener Option + Espacio y hablar en un campo de texto.
Diagnóstico: ./scripts/doctor.sh
FIN

[ "$ABRIR" = "1" ] && open "$HOME/Applications/$APP_NAME.app"
exit 0
