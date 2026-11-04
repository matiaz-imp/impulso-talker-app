#!/usr/bin/env bash
# Diagnóstico rápido de Impulso Talker en macOS. Solo lee: no cambia nada.
#   ./scripts/doctor.sh           revisa instalación, modelo, ajustes y registro
#   ./scripts/doctor.sh --probar  además genera una frase con la voz del sistema y la transcribe (sin micrófono)
APP_NAME="Impulso Talker"
ID="cl.agenciaimpulsa.talker"
DATA="$HOME/Library/Application Support/$ID"
LOGS="$HOME/Library/Logs/$ID"
problemas=0
PROBAR=0
[ "${1:-}" = "--probar" ] && PROBAR=1

ok()      { printf '  OK        %s\n' "$*"; }
revisar() { printf '  REVISAR   %s\n' "$*"; problemas=$((problemas + 1)); }
info()    { printf '  ·         %s\n' "$*"; }

[ "$(uname -s)" = "Darwin" ] || { echo "doctor.sh es solo para macOS."; exit 2; }

echo "Impulso Talker: diagnóstico"
echo
echo "Sistema"
info "macOS $(sw_vers -productVersion), $(uname -m)"

echo
echo "Aplicación"
APP=""
for c in "/Applications/$APP_NAME.app" "$HOME/Applications/$APP_NAME.app"; do [ -d "$c" ] && APP="$c" && break; done
if [ -n "$APP" ]; then
  ver="$(defaults read "$APP/Contents/Info" CFBundleShortVersionString 2>/dev/null || echo '?')"
  ok "instalada en $APP (versión $ver)"
else
  revisar "no está instalada en /Applications ni en ~/Applications (ver INSTALL.md)"
fi
if pgrep -f "$APP_NAME.app/Contents/MacOS" >/dev/null; then ok "está abierta (ícono en la barra de menú)"
else info "no está abierta ahora"; fi

echo
echo "Datos y modelos"
if [ -d "$DATA" ]; then
  ok "carpeta de datos: $DATA"
  store="$DATA/settings_store.json"
  # El modelo elegido puede estar en la carpeta de la app o en la caché de Hugging Face (org/repo/archivo)
  modelo="$(python3 - "$store" <<'PY' 2>/dev/null
import json,sys
try:
    d=json.load(open(sys.argv[1])); print(d.get("settings",d).get("selected_model",""))
except Exception:
    print("")
PY
)"
  hf="${HF_HOME:-$HOME/.cache/huggingface}/hub"
  encontrado=0
  if [ -n "$modelo" ]; then
    archivo="$(basename "$modelo")"
    carpeta="models--$(echo "$modelo" | awk -F/ 'NF>=3 {print $1"--"$2}')"
    if [ -e "$DATA/models/$archivo" ] || ls "$hf/$carpeta"/snapshots/*/"$archivo" >/dev/null 2>&1; then encontrado=1; fi
  fi
  if [ "$encontrado" = "1" ]; then
    ok "modelo seleccionado y descargado: $modelo"
  elif find "$DATA/models" -type f \( -name '*.bin' -o -name '*.gguf' \) 2>/dev/null | grep -q .; then
    ok "hay modelos descargados en la carpeta de la app (pero ninguno está seleccionado: elige uno en Ajustes → Modelos)"
  else
    revisar "no hay un modelo descargado y seleccionado: ábrela y elige uno en Ajustes → Modelos"
  fi
  if [ -f "$store" ]; then
    idioma="$(python3 - "$store" <<'PY' 2>/dev/null
import json,sys
d=json.load(open(sys.argv[1])); s=d.get("settings",d)
print(s.get("selected_language","?"), "|", s.get("selected_model","?"))
PY
)"
    info "idioma | modelo seleccionado: ${idioma:-no se pudo leer}"
  else
    info "todavía no hay ajustes guardados (primer arranque pendiente)"
  fi
else
  info "sin carpeta de datos todavía: la app no se ha abierto nunca"
fi

echo
echo "Registro"
ult="$(ls -t "$LOGS"/*.log 2>/dev/null | head -1)"
if [ -n "$ult" ]; then
  errores="$(grep -E "\[(ERROR)\]" "$ult" 2>/dev/null | tail -5)"
  if [ -n "$errores" ]; then revisar "errores recientes en $ult:"; printf '%s\n' "$errores" | cut -c1-160 | sed 's/^/            /'
  else ok "sin errores en el último registro"; fi
else
  info "no hay registros todavía"
fi

if [ "$PROBAR" = "1" ]; then
  echo
  echo "Prueba de transcripción (sin micrófono)"
  voz="$(say -v '?' 2>/dev/null | grep -E '[[:space:]]es_(CL|MX|ES|AR|CO)[[:space:]]' | head -1 | sed -E 's/[[:space:]]+es_.*//')"
  if [ -z "$APP" ]; then revisar "no se puede probar: la app no está instalada"
  elif ! command -v say >/dev/null || ! command -v afconvert >/dev/null; then info "faltan 'say' o 'afconvert': prueba omitida"
  else
    tmp="$(mktemp -d)"
    say ${voz:+-v "$voz"} -o "$tmp/frase.aiff" "Hola, estoy probando el dictado. Mañana tenemos una reunión a las tres de la tarde." 2>/dev/null
    afconvert -f WAVE -d LEI16@16000 -c 1 "$tmp/frase.aiff" "$tmp/frase.wav" 2>/dev/null
    salida="$("$APP/Contents/MacOS/handy" --transcribe-file "$tmp/frase.wav" 2>&1 | grep -E "^(text:|model=)" )"
    if printf '%s' "$salida" | grep -q "^text: ."; then
      ok "transcribió una frase de prueba${voz:+ (voz $voz)}:"; printf '%s\n' "$salida" | cut -c1-200 | sed 's/^/            /'
    else
      revisar "la transcripción de prueba no devolvió texto (¿modelo sin descargar?)"
    fi
    rm -rf "$tmp"
  fi
fi

echo
echo "Lo que este script no puede comprobar (se prueba dictando una frase):"
echo "  · permiso de Micrófono y de Accesibilidad (Ajustes del Sistema → Privacidad y seguridad)"
echo "  · que el atajo (Option + Espacio) no choque con otra app"
echo
if [ "$problemas" -eq 0 ]; then echo "Resultado: todo en orden."; else echo "Resultado: $problemas punto(s) por revisar."; fi
exit 0
