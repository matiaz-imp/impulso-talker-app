#!/usr/bin/env bash
# Diagnóstico rápido de Impulso Talker en macOS. Solo lee: no cambia nada.
APP_NAME="Impulso Talker"
ID="cl.agenciaimpulsa.talker"
DATA="$HOME/Library/Application Support/$ID"
LOGS="$HOME/Library/Logs/$ID"
problemas=0

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
  modelos="$(find "$DATA/models" -type f \( -name '*.bin' -o -name '*.gguf' \) ! -iname '*silero*' 2>/dev/null | head -20)"
  if [ -n "$modelos" ]; then
    n="$(printf '%s\n' "$modelos" | wc -l | tr -d ' ')"
    ok "$n archivo(s) de modelo descargado(s)"
  else
    revisar "no hay ningún modelo descargado: ábrela y elige uno en Ajustes → Modelos"
  fi
  store="$DATA/settings_store.json"
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

echo
echo "Lo que este script no puede comprobar (se prueba dictando una frase):"
echo "  · permiso de Micrófono y de Accesibilidad (Ajustes del Sistema → Privacidad y seguridad)"
echo "  · que el atajo (Option + Espacio) no choque con otra app"
echo
if [ "$problemas" -eq 0 ]; then echo "Resultado: todo en orden."; else echo "Resultado: $problemas punto(s) por revisar."; fi
exit 0
