<p align="center">
  <img src="branding/icon-azul.svg" width="96" alt="Impulso Talker">
</p>

<h1 align="center">Impulso Talker</h1>

<p align="center">
  Dictado por voz para tu computador. Mantén un atajo, habla y el texto aparece donde está tu cursor.<br>
  Gratis, funciona sin internet y tu voz no sale de tu equipo.
</p>

Impulso Talker es una versión en español de [Handy](https://github.com/cjpais/Handy) (licencia MIT), con marca,
ajustes y guías propias de Agencia Impulsa. Funciona en **macOS** y **Windows**. Es una herramienta de uso personal:
no es un producto comercial ni tiene soporte formal.

## Qué hace

- **Dictas en cualquier app.** Mantienes el atajo (por defecto `Option + Espacio` en Mac y `Ctrl + Espacio` en Windows), hablas y al soltar el texto se escribe donde está el cursor.
- **Todo local.** La transcripción corre en tu computador con modelos abiertos (Whisper, Parakeet). No hace falta cuenta ni clave, y no se manda audio a ningún servicio.
- **Español primero.** Si tu sistema está en español, parte transcribiendo en español. Si no, detecta el idioma solo.
- **Limpia el texto sin costo.** Quita muletillas («eh», «mmm») y corrige nombres con tu lista de palabras personalizadas.
- **Historial** de lo que has dictado, con su audio.
- **Limpieza con IA, opcional.** Si quieres que un modelo de lenguaje ordene y reescriba lo dictado, puedes conectar tu propia clave de API (Anthropic, OpenAI, OpenRouter, Ollama local, etc.). Está apagada de fábrica y es 100 % opcional.

## Instalar

Elige según tu computador. Si usas un agente (Claude, ChatGPT u otro), pásale [`INSTALL.md`](INSTALL.md): ahí están los pasos para que lo instale por ti.

| Tu computador                       | Cómo                                                                                                                                     |
| ----------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------- |
| Mac con chip Apple (M1 o posterior) | Descarga `…aarch64.dmg` desde [Releases](../../releases) y arrástralo a Aplicaciones.                                                    |
| Windows 10/11 (64 bits)             | Descarga el instalador `…x64-setup.exe` desde [Releases](../../releases) y ejecútalo.                                                    |
| Mac con Intel                       | Descarga `…x64.dmg` desde [Releases](../../releases). Si prefieres compilarla tú: `./scripts/install-macos.sh` (~15 min la primera vez). |

> **Estado de las pruebas.** Los instaladores de **Windows**, **Mac con chip Apple** y **Mac con Intel** se probaron en máquinas de
> prueba de GitHub: se instalan, abren con la marca correcta, muestran la guía de bienvenida y (en Windows) se
> desinstalan. Lo que **nadie ha probado todavía en un computador real es el micrófono, el atajo y el pegado**, porque
> necesitan permisos de una persona. El **Mac con Intel** se probó además transcribiendo audios en esta misma máquina.
> Si algo falla en tu computador, cuéntame.

### Avisos de seguridad del sistema (es normal)

La app **no está firmada** con un certificado de desarrollador (cuesta ~US$99 al año), así que el sistema pide confirmación la primera vez:

- **macOS:** si dice que no se puede abrir, ve a _Ajustes del Sistema → Privacidad y seguridad_ y pulsa **Abrir de todos modos**. Alternativa en Terminal: `xattr -dr com.apple.quarantine "/Applications/Impulso Talker.app"`. Si la compilaste tú (Mac Intel), no aparece este aviso.
- **Windows:** en la ventana azul de SmartScreen pulsa **Más información → Ejecutar de todas formas**.

## Primer uso

1. Abre la app. Una guía corta te lleva por los pasos.
2. **Permisos.** En Mac te pedirá dos, que se dan en _Ajustes del Sistema → Privacidad y seguridad_:
   - **Micrófono**, para escucharte.
   - **Accesibilidad**, para escribir el texto en la app donde estás y detectar el atajo.

   En Windows solo pregunta por el micrófono la primera vez.

3. **Elige un modelo.** Se descarga una vez (de unos 200 MB a 1,6 GB según el modelo).
   - Computador lento o Mac Intel: **Whisper Small**.
   - Computador rápido: **Whisper Large v3 Turbo** (el más preciso) o **Parakeet v3** (rápido, 25 idiomas europeos).
4. Abre cualquier campo de texto, mantén el atajo y habla.

Si reinstalas la app en Mac y el atajo deja de responder aunque Accesibilidad aparezca activada: ciérrala, ejecuta
`tccutil reset Accessibility cl.agenciaimpulsa.talker`, ábrela de nuevo y concede el permiso otra vez.

## Privacidad

- La transcripción es **local**: el audio no se envía a ningún lado.
- La app descarga los **modelos** desde Hugging Face (con respaldo en los servidores del proyecto base, Handy). Es lo único que sale a internet por defecto.
- Si activas la **limpieza con IA**, el _texto_ dictado (no el audio) se envía al proveedor que elijas, con tu propia clave. Revisa su política de datos. Sin clave no se envía nada.
- No hay telemetría ni cuentas (no encontré código de analítica en la app al revisarla). Tus datos viven en `~/Library/Application Support/cl.agenciaimpulsa.talker` (Mac) o `%APPDATA%\cl.agenciaimpulsa.talker` (Windows).

## Problemas frecuentes

| Síntoma                                        | Qué hacer                                                                                                                                                                         |
| ---------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Hablo y no aparece nada                        | Revisa que el micrófono correcto esté elegido en Ajustes y que hayas dado el permiso de Micrófono.                                                                                |
| Transcribe pero no escribe el texto            | Falta el permiso de **Accesibilidad**. Después de darlo, ciérrala y ábrela de nuevo.                                                                                              |
| El atajo no hace nada                          | Puede chocar con otra app. Cámbialo en Ajustes → Atajos. En Mac, revisa el permiso de Accesibilidad.                                                                              |
| Tarda mucho                                    | Usa un modelo más chico (Whisper Small) o cierra apps pesadas. En equipos Intel antiguos es lo esperable.                                                                         |
| Quedó en otro idioma                           | En Ajustes → Idioma elige _Español_ en vez de _Automático_.                                                                                                                       |
| Windows Defender o el antivirus bloquea la app | Escribe teclas por ti, y eso a veces alerta a los antivirus. Permítela desde _Seguridad de Windows → Historial de protección_. Si no te fías, compílala tú mismo desde el código. |
| Tengo Handy instalado también                  | Pueden convivir (guardan datos aparte), pero comparten el atajo por defecto: cambia uno de los dos en Ajustes → Atajos.                                                           |

Para un diagnóstico rápido en Mac: `./scripts/doctor.sh`.

## Desinstalar

- **Mac:** borra `Impulso Talker.app` de Aplicaciones y, si quieres, la carpeta de datos de arriba (borra también los modelos).
- **Windows:** _Configuración → Aplicaciones → Impulso Talker → Desinstalar_.

## Para quien quiera tocar el código

Es una app [Tauri 2](https://tauri.app) (Rust + React/TypeScript). La guía de desarrollo está en [`AGENTS.md`](AGENTS.md).
Cómo se relaciona con el proyecto original y qué cambiamos: [`docs/FORK.md`](docs/FORK.md). Los íconos se generan con
[`branding/generate-icons.swift`](branding/generate-icons.swift).

## Créditos y licencia

Construido sobre el trabajo de otros: **Handy** (CJ Pais, MIT), **Whisper** (OpenAI, MIT), **Parakeet** (NVIDIA, CC-BY-4.0),
**ggml** y **Silero VAD**. Detalle en [`NOTICE.md`](NOTICE.md). Impulso Talker se distribuye bajo licencia [MIT](LICENSE).
