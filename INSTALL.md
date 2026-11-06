# Guía de instalación para agentes (Claude, ChatGPT u otro)

Esta guía es para que un agente instale **Impulso Talker** en el computador de una persona. Si eres una persona leyendo esto,
mira mejor el [README](README.md).

## Reglas para el agente

1. **Avisa antes de descargar** y di qué, de dónde y cuánto pesa. Este proyecto descarga herramientas de compilación
   (cientos de MB) y modelos de voz (hasta 1,6 GB).
2. **Nunca pidas ni escribas contraseñas, claves ni tokens** por la persona. Los permisos del sistema los da ella.
3. **No uses `sudo`** ni toques ajustes de seguridad del sistema. Todo se instala en la carpeta del usuario.
4. **No publiques nada** (repositorios, releases) sin que la persona lo pida.
5. Si un paso falla, **dilo tal cual**, con el error, y no lo des por hecho. No hay ninguna prueba que cuente sin haber corrido.

## Paso 0: detectar el sistema

- macOS o Linux: `uname -sm` → `Darwin arm64` (chip Apple) o `Darwin x86_64` (Intel).
- Windows (PowerShell): `$env:PROCESSOR_ARCHITECTURE` → `AMD64` o `ARM64`.

Linux y Windows con ARM **no están soportados**.

## Camino A: instalador ya compilado (recomendado: Apple Silicon y Windows)

Descarga el último instalador desde la página de _Releases_ del repositorio (es público: no hace falta cuenta de GitHub;
el comando `gh` de abajo solo es una comodidad, también sirve el enlace directo desde el navegador).

```bash
# Sin GitHub CLI (recomendado): enlace directo, no pide cuenta
curl -fL -o ~/Downloads/ImpulsoTalker.dmg https://github.com/matiaz-imp/impulso-talker-app/releases/latest/download/Impulso.Talker_0.2.0_aarch64.dmg   # Intel: ..._x64.dmg
```

```bash
# macOS: *aarch64.dmg = chip Apple (M1 o posterior), *x64.dmg = Intel. Se ve con: uname -m (arm64 / x86_64)
gh release download --repo matiaz-imp/impulso-talker-app --pattern "*aarch64.dmg" --dir ~/Downloads   # o "*x64.dmg"
open ~/Downloads/*.dmg               # la persona arrastra la app a Aplicaciones
```

```powershell
# Windows 64 bits
gh release download --repo matiaz-imp/impulso-talker-app --pattern "*x64-setup.exe" --dir $HOME\Downloads
# o: .\scripts\install-windows.ps1 -Repo matiaz-imp/impulso-talker-app
```

Como la app **no está firmada**, el sistema avisa la primera vez (ver el README: «Avisos de seguridad del sistema»).
Explícaselo a la persona antes de que lo vea.

> Estado: los instaladores los genera GitHub Actions (pestaña _Actions → Release → Run workflow_, o al empujar una etiqueta `v*`).
> El de Windows y el de Apple Silicon se probaron en máquinas de prueba de GitHub (instalan, abren y, en Windows, desinstalan).
> Para Mac con Intel hay `*x64.dmg`; si falla, usa el Camino B.

## Camino B: compilar en el equipo (Mac con Intel, o cuando no hay release)

Requisitos: macOS 13 o superior y las _Command Line Tools_ (`xcode-select --install`). No hace falta Xcode.

```bash
git clone https://github.com/matiaz-imp/impulso-talker-app.git
cd impulso-talker-app
./scripts/install-macos.sh
```

El script, que no usa `sudo`:

1. Instala **Rust**, **Bun** y **CMake** en `~/.impulso-talker/tools` si no existen, verificando la suma SHA-256 de cada descarga.
2. Instala las dependencias y compila (≈ 12–20 minutos la primera vez).
3. Copia `Impulso Talker.app` a `~/Applications` y la abre.

Opciones: `--solo-herramientas` (instala las herramientas y se detiene), `--sin-abrir`.

En Windows, compilar desde el código fuente requiere Visual Studio Build Tools, CMake y Vulkan SDK; la guía
está en [`docs/compilar.md`](docs/compilar.md). Para personas normales, usa el Camino A.

## Paso final: lo que debe hacer la persona (el agente no puede)

1. Abrir la app y seguir la guía de bienvenida.
2. **Mac:** conceder **Micrófono** y **Accesibilidad** (_Ajustes del Sistema → Privacidad y seguridad_). Después de dar
   Accesibilidad, cerrar la app y abrirla de nuevo.
3. Elegir y descargar un **modelo**: _Whisper Small_ si el equipo es lento o Intel; _Whisper Large v3 Turbo_ o _Parakeet v3_ si es rápido.
4. Probar: abrir un campo de texto, mantener el atajo (`Option + Espacio` en Mac, `Ctrl + Espacio` en Windows) y hablar.

## Verificación (macOS)

```bash
./scripts/doctor.sh
```

Revisa que la app esté instalada y abierta, que haya un modelo descargado, el idioma configurado y errores recientes
en el registro. Lo que depende de permisos (micrófono, accesibilidad) no se puede comprobar desde un script: se comprueba
dictando una frase.

## Personalización opcional

- **Palabras propias** (nombres, marcas, términos técnicos): _Ajustes → Avanzado → Palabras personalizadas_.
- **Limpieza con IA**: _Ajustes → Posprocesamiento_. Requiere la clave de API de un proveedor (Anthropic, OpenAI, OpenRouter,
  Ollama local…) que **la persona** escribe. Una suscripción de claude.ai o de ChatGPT **no** sirve como clave de API. Sin clave, no pasa nada.

## Problemas frecuentes

Ver la tabla del [README](README.md#problemas-frecuentes). Para actualizar: `git pull && ./scripts/install-macos.sh`
(Camino B) o descargar la nueva release (Camino A). La app no se actualiza sola, a propósito.
