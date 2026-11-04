# Relación con Handy y cómo mantenerse al día

Impulso Talker nació como una copia (fork) de [Handy](https://github.com/cjpais/Handy) en su versión 0.10.0
(commit `82dfab9f`, 2 de noviembre de 2026). El remoto `upstream` de este repositorio apunta a Handy.

## Qué cambiamos (para que sea fácil volver a unir)

Se mantuvo el cambio lo más chico posible; casi todo es marca y valores por defecto.

| Qué                                                                                          | Dónde                                                                                          |
| -------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------- |
| Nombre, versión (0.1.0), identificador `cl.agenciaimpulsa.talker`, sin firma ni actualizador | `src-tauri/tauri.conf.json`, `package.json`, `src-tauri/Cargo.toml`                            |
| Actualizador de Handy **apagado siempre** (para no instalar por error una versión de Handy)  | `src-tauri/src/settings.rs` (`update_checks_forced_disabled`, `default_update_checks_enabled`) |
| Idioma de transcripción por defecto: español si el sistema está en español                   | `src-tauri/src/settings.rs` (`default_selected_language`)                                      |
| Muletilla «eh» en español                                                                    | `src-tauri/src/audio_toolkit/text.rs`                                                          |
| Textos de la ventana, bandeja y cliente de IA                                                | `src-tauri/src/lib.rs`, `tray.rs`, `cli.rs`, `llm_client.rs`                                   |
| Colores y logos                                                                              | `src/styles/theme.css`, `src/components/icons/*`                                               |
| Íconos de app y de bandeja                                                                   | `src-tauri/icons/`, `src-tauri/resources/*.png` (generados desde `branding/`)                  |
| «Handy» → «Impulso Talker» en las 25 traducciones; pantalla «Acerca de» sin donaciones       | `src/i18n/locales/*/translation.json`, `AboutSettings.tsx`                                     |
| Publicación de versiones solo para Mac y Windows, sin firma                                  | `.github/workflows/release.yml`                                                                |
| Quitado: notas de versión, donaciones, Nix, plantillas de issues                             | varios                                                                                         |

## Traer mejoras de Handy

```bash
git fetch upstream
git merge upstream/main     # habrá conflictos en los archivos de la tabla; se resuelven conservando nuestra marca
```

Después de unir: `bun run lint`, `bun run check:translations` y una compilación completa (`bun run tauri build --bundles app`).
Si Handy agrega textos con «Handy», hay que cambiarlos otra vez:
`perl -pi -e 's/\bHandy(?![A-Za-z])/Impulso Talker/g' src/i18n/locales/*/translation.json`.

## Qué no se puede heredar sin cuidado

- El **nombre y el logo** de Handy. No se usan en ningún lugar visible.
- Los **modelos**: son de terceros con licencias propias (ver `NOTICE.md`).
