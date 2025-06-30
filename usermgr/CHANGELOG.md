# Changelog

Todos los cambios importantes en este proyecto serán documentados en este archivo.

El formato está basado en [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
y este proyecto se adhiere a [Semantic Versioning](https://semver.org/spec/v2.0.0.html).


## [1.7.0] - 2025-06-30

### Añadido
- Función `cambiar_rol_usuario` para modifivar el rol de los usuarios.
- Función para cambiar contraseña de login a usuarios existentes, con exclusión del usuario protegido 'vivezatextil'.
- Función para cambiar contraseña SSH (regenerar claves) para usuarios con acceso SSH activo, excluyendo 'vivezatextil'.
- Función para eliminar usuarios con confirmación previa y limpieza completa de datos.
- Eliminación segura excluyendo al usuario protegido `vivezatextil`.
- Actualización automática de la configuración SSH luego de eliminar usuarios.
- Registro detallado de acciones en el log.
- Función para generar reportes de usuarios con detalles de roles y accesos.
- Exportación de reportes a archivo CSV.
- Visualización formateada de reportes en consola.

### Modificado
- Función `asignar_rol_usuario` para que solo solicite el rol que le será asignado a un usuario (al crearlo o modificar su rol)
- Nombre de la función `asignar_rol_usuario` por `solicitar_rol_usuario`.
- Refactorización en la gestión de listas de usuarios para evitar duplicados al mostrar usuarios en cambio de contraseña login y SSH.
- Validación para impedir operaciones de cambio de contraseña sobre el usuario protegido.
- Refactorización general para mejorar manejo de usuarios y roles.

---

## [1.5.0] - 2025-06-20

### Añadido
- Función para listar usuarios (`listar_usuarios`) que muestra una tabla con el usuario, rol asignado, estado de acceso login y acceso SSH, con colores para diferenciar estados activos y bloqueados.
- Funciones auxiliares para obtener rol de usuario y estado de acceso.
- Interfaz de menú actualizada para incluir la opción "Ver usuarios".
- La navegación en las listas ahora es ciclica, si llega al final (arriba) vuelve a empezar y visceversa.

### Arreglado
- Corrección en `cargar_usuarios`: se reinician los arrays `CREATED_USERS` Y `BLOCKED_USERS` al cargar usuarios, evitando acumulación de datos y errores.

---

## [1.4.0] - 2025-06-20

### Añadido
- Funcionalidad para bloquear y desbloquear acceso login del servidor, mostrando solo usuarios activos o bloqueados respectivamente.
- Funcionalidad para bloquear y desbloquear acceso SSH, mostrando solo usuarios con acceso habilitado o bloqueado respectivamente.
- Opción para cancelar operaciones en los menús de bloqueo y desbloqueo (login y SSH) con selección interactiva mediante `fzf`.
- Manejo correcto y declaración explícita de arrays `CREATED_USERS` y `BLOCKED_USERS` para evitar errores.
- Mejoras en mensajes de confirmación, error y éxito para una mejor experiencia de usuario.
- Validaciones y seguridad reforzadas en las funciones de bloqueo y desbloqueo.

### Cambios
- Refactorización para mostrar solo usuarios válidos en operaciones de bloqueo/desbloqueo.
- Limpieza y optimización en manejo de usuarios bloqueados y desbloqueados.

---

## [1.3.0] - 2025-06-18

### Añadido
- Solicitud y validación de rol antes de crear usuario, con opción para cancelar la asignación.
- Bloqueo automático del acceso login por defecto al crear un usuario nuevo.
- Creación de claves SSH con tipo ed25519, almacenadas en directorio seguro con permisos adecuados.
- Implementación de límite máximo de usuarios por rol, validado antes de asignar.
- Función `mostrar_mensaje` para pausar mensajes importantes y evitar que se borren rápidamente.
- Mejora en mensajes con colores y estructura para mayor claridad y usabilidad.
- Validación y control de acceso a funciones según rol del usuario.
- Manejo de arrays `CREATED_USERS` y `BLOCKED_USERS` para seguimiento de acceso SSH.

---

## [1.2.0] - 2025-06-15

### Añadido
- Uso de archivos temporales seguros con `mktemp` para manipular configuración SSH.
- Validación y reinstalación de dependencias necesarias (`fzf`, `ssh-keygen`, etc.) con confirmación del usuario.
- Confirmación de ejecución con permisos root y pertenencia al grupo sudo.
- Validaciones y mejoras en manejo de errores.

---

## [1.1.0] - 2025-06-12

### Añadido
- Activación del modo estricto con `set -euo pipefail` y ajuste de `IFS` para robustez del script.
- Validación que el script se ejecuta como root (sudo).
- Preparación de directorios de logs y claves SSH con permisos seguros.
- Registro de acciones y auditoría básica en archivo de log centralizado.
- Integración de `fzf` para selección interactiva de usuarios y opciones.

---

## [1.0.0] - 2025-06-10

### Inicial
- Script base para administración avanzada de usuarios SSH.
- Gestión de roles y grupos, creación y eliminación de usuarios.
- Generación y manejo seguro de claves SSH para cada usuario.
- Configuración segura del archivo `sshd_config` con reinicio automático.
- Menú interactivo con selección mediante `fzf`.
- Registro de auditoría en log con detalles de usuario, IP y acción.

---
