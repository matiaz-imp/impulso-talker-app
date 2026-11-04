# Créditos y licencias de terceros

Impulso Talker se distribuye bajo licencia MIT (ver `LICENSE`). Reúne y usa el trabajo de otros proyectos.
La licencia MIT de Handy exige conservar su aviso de derechos de autor, y por eso `LICENSE` lo mantiene.

## Código

| Proyecto | Autor | Licencia | Uso |
|---|---|---|---|
| [Handy](https://github.com/cjpais/Handy) | CJ Pais | MIT | Base de esta aplicación (el nombre y el logo de Handy **no** forman parte de la licencia y no se usan aquí) |
| [transcribe.cpp](https://crates.io/crates/transcribe-cpp) / ggml | Georgi Gerganov y colaboradores; paquete de Handy | MIT | Motor de transcripción local |
| [Tauri](https://tauri.app) | Tauri Contributors | MIT / Apache-2.0 | Marco de la aplicación de escritorio |
| handy-keys | CJ Pais | MIT | Atajos de teclado globales |

Las demás dependencias de Rust y de JavaScript conservan sus propias licencias (ver `src-tauri/Cargo.lock` y `bun.lock`).

## Modelos que la app puede descargar

Los modelos **no** se incluyen en este repositorio: cada persona los descarga desde la app y cada uno trae su licencia.

| Modelo | Autor | Licencia | Obligación |
|---|---|---|---|
| Whisper (small, medium, large, large v3 turbo) | OpenAI | MIT | Conservar el aviso de licencia |
| Parakeet TDT 0.6B v3 | NVIDIA | CC-BY-4.0 | **Dar crédito a NVIDIA** (este archivo y la pantalla «Acerca de» lo hacen) |
| Silero VAD | Silero Team | MIT | Detecta silencios; viene incluido en la app |
| Otros modelos del catálogo (Qwen3-ASR, Canary, Moonshine, etc.) | Varios | Varias | Revisar la ficha de cada modelo antes de usarlo fuera de un uso personal |

Algunos modelos del catálogo tienen licencia de **uso no comercial** (por ejemplo, Granite Speech 5.0 «Non-Commercial»).
Impulso Talker es de uso personal, pero si algún día se usa con fines comerciales hay que revisar cada licencia.

## Marcas

«Handy» es marca de su autor. «Impulso» e «Impulso Creator» pertenecen a Agencia Impulsa. Los íconos de Impulso Talker
(`branding/`) son propios y no reutilizan el logo de Impulso Creator.
