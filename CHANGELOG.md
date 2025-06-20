# Changelog

Todos los cambios importantes en este proyecto serán documentados en este archivo.

El formato está basado en [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
y este proyecto se adhiere a [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [2.0.0] - 2025-06-21

> **Importante:** Este cambio rompe compatibilidad con versiones anteriores y puede requerir ajustes en scripts o configuraciones que dependían de los siguientes nombres y rutas.

### Changed
- Renombrado el script `backup_server.sh` y su carpeta a `backupmgr` para mayor claridad y profesionalismo.
- Actualizado el script de instalación `install.sh` para reflejar los nuevos nombres y rutas de los scripts.

## [1.0.0] - 2025-06-20

### Added
- Carpeta con el script `backups_server.sh`.
- Documentación del script `backups_server.sh`.
- Archivo de registro de cambios (`CHANGELOG.md`) para `backups_server.sh`
- Script de instalación `install.sh` que clona el repositorio y lo mueve a `/opt/server-scripts`.
- Documentación completa del script `install.sh`.
- Archivo de registro de cambios (`CHANGELOG.md`).

### Changed
- Modificado el script `install.sh` para crear symlinks además de clonar y mover el repositorio.

### Fixed
- Corregido error en `install.sh` relacionado con el uso del alias SSH para clonar con credenciales de usuario (se instalaba con root, que no tenía dichas credenciales).
- Corregido error en `install.sh` donde intentaba clonar en `/root/server-scripts` sin permisos; ahora clona en el `$HOME` del usuario instalador y luego mueve el repo.
