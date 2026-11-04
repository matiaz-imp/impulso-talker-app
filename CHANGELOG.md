# Cambios

## 0.1.0 — primera versión de Impulso Talker

Basada en Handy 0.10.0 (commit `82dfab9f`).

- Marca propia: nombre, ícono (tres barras de sonido y cursor amarillo), íconos de bandeja con estados, colores azul Impulso.
- Español por defecto cuando el sistema está en español; muletilla «eh» quitada en español.
- Actualizador de Handy apagado; sin firma de desarrollador.
- «Acerca de» sin donaciones ni notas de versión de Handy; créditos de Handy, Whisper y Parakeet.
- Guía de instalación para agentes (`INSTALL.md`), instalador para macOS (`scripts/install-macos.sh`), instalador para Windows sin probar
  (`scripts/install-windows.ps1`), diagnóstico (`scripts/doctor.sh`).
- Publicación automática de instaladores para Apple Silicon, Mac Intel (experimental) y Windows al empujar una etiqueta `v*`.

- Instaladores de Windows (`.exe` y `.msi`) y de Mac con chip Apple (`.dmg`) generados por GitHub Actions el 4-nov-2026 y probados en máquinas de prueba (instalar, abrir con la marca correcta, desinstalar en Windows). Sin prueba con micrófono real.
