#!/usr/bin/env bash
# Control de privacidad: falla si el código empieza a hablar con internet por
# un camino que no está en la lista de abajo, o si entra una dependencia de
# estadísticas. Corre en la integración continua (code-quality.yml).
#
#   bash scripts/check-privacy.sh
set -u
cd "$(dirname "$0")/.."
fallos=0
falla() { echo "✗ $1"; fallos=1; }

# 1. Rust: solo estos archivos pueden abrir conexiones.
#    llm_client.rs      → limpieza con IA (opcional, con la clave de la persona)
#    model/download.rs  → descarga de modelos (Hugging Face y su respaldo)
PERMITIDOS_RUST='^src-tauri/src/(llm_client\.rs|managers/model/download(/tests)?\.rs)$'
while IFS= read -r archivo; do
  [[ "$archivo" =~ $PERMITIDOS_RUST ]] || falla "$archivo usa red y no está en la lista de permitidos"
done < <(grep -rlE "reqwest|ureq|isahc|hyper::|TcpStream::connect|UdpSocket" src-tauri/src || true)

# 2. Interfaz: solo el aviso de versión nueva puede hacer peticiones.
PERMITIDOS_TS='^src/components/update-checker/UpdateChecker\.tsx$'
while IFS= read -r archivo; do
  [[ "$archivo" =~ $PERMITIDOS_TS ]] || falla "$archivo hace peticiones y no está en la lista de permitidos"
done < <(grep -rlE "fetch\(|XMLHttpRequest|new WebSocket|sendBeacon|plugin-http" src --include='*.ts' --include='*.tsx' | grep -v '\.test\.' || true)

# 3. Dependencias de estadísticas o reporte de errores.
if grep -qiE "sentry|posthog|mixpanel|amplitude|segment|datadog|bugsnag|telemetry|analytics|plugin-updater" src-tauri/Cargo.toml package.json; then
  falla "Cargo.toml o package.json nombran una dependencia de estadísticas, telemetría o actualización automática"
fi

# 4. El único servidor de la interfaz es el de GitHub; nada de scripts externos.
if grep -qE "<script[^>]+src=\"https?://|<link[^>]+href=\"https?://" index.html src/overlay/index.html; then
  falla "una página carga recursos desde internet"
fi

if [ "$fallos" = 0 ]; then
  echo "✓ Privacidad: la red solo se usa para modelos, limpieza con IA opcional y el aviso de versión nueva."
fi
exit "$fallos"
