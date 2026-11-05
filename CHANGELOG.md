# Cambios

## 0.2.0 — marca propia, Inicio, Modos y privacidad

- Sonidos de inicio y fin propios, sintetizados desde cero (`branding/generate-sounds.py`): **Cápsula** (por defecto), **Micro** y **Burbuja**. Reemplazan a Marimba y Pop; quien los tenía guardados oye Cápsula y conserva el resto de sus ajustes.
- Tipografía de marca (Plus Jakarta Sans) y nombre «Impulso Talker» en dos líneas junto al ícono.
- Marca neutra: ícono claro con barras azul Impulso y cursor ámbar, interfaz blanca y plata (o negra) y azul Impulso solo para lo activo; cápsula de grabación negra; menú de secciones arriba.
- **Inicio**: pantalla nueva con el atajo, palabras de hoy y de los últimos 7 días, buscador y dictados recientes.
- **Modos por app**: Correo, Mensajes, Código y Notas retocan mayúscula inicial, punto final y saltos de línea según la app donde se pega (macOS y Windows), sin IA. Se pueden editar, agregar apps con «Detectar app» y apagar.
- **Privacidad**: _Historial → Borrar todo_ (textos, audios y restos de la base), `PRIVACY.md`, texto de privacidad en Acerca de y un control automático (`bun run check:privacy`) que falla si el código abre conexiones fuera de las tres permitidas. El registro parte en nivel Info.
- **Avisos de versión nueva** en lugar del actualizador automático: una vez al día pregunta a GitHub y, si hay una versión mayor, lo dice abajo a la izquierda y abre la página de descargas. No descarga ni instala nada solo. Se apaga en Acerca de. Se quitó el complemento de actualización automática.
- El selector de sonido pasó a _General → Sonido_.
- Se quitó el bloque «Basado en Handy» de Acerca de y las menciones del README; el aviso de derechos de autor sigue en `LICENSE` y `NOTICE.md`.

## 0.1.0 — primera versión de Impulso Talker

Basada en Handy 0.10.0 (commit `82dfab9f`).

- Marca propia: nombre, ícono (tres barras de sonido y cursor amarillo), íconos de bandeja con estados, colores azul Impulso.
- Español por defecto cuando el sistema está en español; muletilla «eh» quitada en español.
- Actualizador de Handy apagado; sin firma de desarrollador.
- «Acerca de» sin donaciones ni notas de versión de Handy; créditos de Handy, Whisper y Parakeet.
- Guía de instalación para agentes (`INSTALL.md`), instalador para macOS (`scripts/install-macos.sh`), instalador para Windows sin probar
  (`scripts/install-windows.ps1`), diagnóstico (`scripts/doctor.sh`).
- Publicación automática de instaladores para Apple Silicon, Mac Intel (experimental) y Windows al empujar una etiqueta `v*`.

- Instaladores de Windows (`.exe` y `.msi`), de Mac con chip Apple y de Mac con Intel (`.dmg`) generados por GitHub Actions el 4-nov-2026 y probados en máquinas de prueba (instalar, abrir con la marca correcta, desinstalar en Windows). Sin prueba con micrófono real.
