# Privacidad

Impulso Talker está hecho para que **lo que dictas se quede en tu computador**. Este documento dice exactamente qué se guarda, dónde, y qué sale a internet. Si algo de aquí deja de ser cierto en el código, es un error del proyecto: avísanos.

## Lo que se guarda (solo en tu equipo)

| Qué                                   | Dónde                                                      |
| ------------------------------------- | ---------------------------------------------------------- |
| El texto de cada dictado (historial)  | Base de datos local `history.db`                           |
| El audio de cada dictado              | Carpeta `recordings/`, en archivos `.wav`                  |
| Tus ajustes y tu vocabulario personal | `settings_store.json`                                      |
| Los modelos de voz descargados        | Carpeta `models/` y la caché de Hugging Face de tu usuario |

La carpeta de datos es `~/Library/Application Support/cl.agenciaimpulsa.talker` en Mac y `%APPDATA%\cl.agenciaimpulsa.talker` en Windows. Nada de esto vive dentro del repositorio ni se sube a GitHub.

## Lo que sale a internet

Solo estas tres cosas, y ninguna lleva tu voz ni tus textos:

1. **Descarga de modelos.** Cuando eliges un modelo, se baja una vez desde Hugging Face (con un servidor de respaldo si Hugging Face falla). El servidor ve tu dirección IP y qué archivo pides, como cualquier descarga.
2. **Aviso de versión nueva.** Una vez al día la app pregunta a GitHub cuál es la última versión publicada. Sale únicamente tu dirección IP. No descarga ni instala nada por sí sola. Se apaga en _Acerca de → Avisarme de versiones nuevas_.
3. **Limpieza con IA (opcional y apagada de fábrica).** Si la activas y pones tu propia clave de API, el **texto** de lo que dictas (no el audio) se envía al proveedor que elegiste (OpenAI, Anthropic, OpenRouter, etc.) para reescribirlo. Si lo que quieres es que nada salga, déjala apagada o usa un modelo local (por ejemplo Ollama).

No hay cuentas, estadísticas, reportes de errores ni identificadores. La app no sabe quién eres ni cuántas veces la usas.

## Cómo lo comprobamos

- `scripts/check-privacy.sh` corre en cada cambio del proyecto y **falla** si alguien agrega código de red fuera de los tres caminos de arriba, o una dependencia de estadísticas. Puedes correrlo tú: `bun run check:privacy`.
- Los registros de la app (`~/Library/Logs/cl.agenciaimpulsa.talker/`) no contienen el texto de tus dictados: en las versiones publicadas se reemplaza por `[REDACTED]`. Por defecto el registro está en nivel «Info».
- Los instaladores se generan en GitHub Actions desde este mismo código, a la vista de todos.

## Cómo borrar tus datos

- **Un dictado:** en _Historial_, el ícono de papelera de ese dictado.
- **Todo el historial:** _Historial → Borrar todo_. Borra los textos, los audios y compacta la base de datos. No se puede deshacer.
- **No guardar audio:** en _Avanzado_, elige cuánto conservar (nada, los últimos N, días o meses) y cuántos dictados mostrar.
- **Todo, incluida la app:** desinstala la app y borra la carpeta de datos de arriba.

## Si compartes esta app

Cada persona que la instala tiene **su propia carpeta de datos**. Quien publica la app (el repositorio) no recibe nada de lo que dicta cada usuario, porque la app no tiene a dónde enviarlo.
