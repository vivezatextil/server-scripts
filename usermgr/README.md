
# Gestor Avanzado de Usuarios SSH (`usermgr`)

## Descripción

El **Gestor Avanzado de Usuarios SSH** (`usermgr`) es una herramienta integral y segura para la administración avanzada de usuarios y acceso SSH en servidores Linux. Facilita la gestión centralizada de usuarios, claves, roles personalizados y reportes profesionales de auditoría, todo desde una interfaz de consola interactiva y auditable.

Pensado para equipos de TI que requieren control, trazabilidad y seguridad avanzada.

---

## Instalación

> **¡NO es necesario copiar ni editar manualmente el script!**

1. Se instala automaticamente con el script `install.sh`. [Ver documentación](https://github.com/vivezatextil/server-scripts/blob/main/README.md).

## Ejecución

A partir de la instalación, ejecuta en cualquier momento:

```bash
sudo usermgr
```

¡Eso es todo!  
Aparecerá el menú interactivo con todas las opciones según tu rol.

---

## Características

- **Gestión centralizada:** Alta, baja, edición y roles personalizados.
- **SSH seguro:** Bloqueo/desbloqueo de acceso SSH y login por usuario.
- **Generación/rotación automática de claves SSH y exportables.**
- **Control y límites por tipo de rol (CTO, DBA, Soporte, etc).**
- **Auditoría y reportes profesionales:**  
    - Fecha de creación, última conexión, duración de sesión, intentos fallidos.
    - Exportación a consola (tabla) o CSV.
    - Opción de anonimizar datos.
    - Filtros por rol y estado.
- **Logs detallados:** Todo queda registrado para cumplimiento y auditoría interna.
- **Usuario protegido:** No es posible modificar o eliminar el usuario principal del sistema.
- **Menús interactivos (fzf):** Sin necesidad de recordar comandos.

---

## Preguntas frecuentes

- **¿Dónde se instalan los archivos y logs?**
    - Logs: `/var/log/usermgr/usermgr.log`
    - Claves SSH exportables: `/var/lib/usermgr/keys/`

- **¿Cómo actualizo el script?**
    - Simplemente actualiza el repo y vuelve a ejecutar `sudo ./install.sh`.

- **¿Debo ser root o sudo?**
    - Sí, solo usuarios del grupo `sudo` pueden operar `usermgr`.

- **¿Puedo correrlo desde cualquier carpeta?**
    - Sí, solo escribe `sudo usermgr` en cualquier terminal.

- **¿Se modifica la configuración de SSH?**
    - Sí, el script gestiona la directiva `AllowUsers` y reinicia SSH para máxima seguridad.

---

## Ejemplo de flujo típico

```bash
sudo usermgr
# Selecciona una opción del menú (ej: Agregar usuario)
# Sigue las instrucciones, asigna rol y comparte la clave SSH privada generada
# Usa "Ver usuarios" y "Generar reporte" para consultar el estado y exportar auditoría
```

---

## Seguridad y recomendaciones

- **No edites manualmente los archivos generados ni los logs.**
- Los cambios de usuarios se aplican al instante, con logs y backup de configuración.
- La clave privada generada para nuevos usuarios debe transferirse manualmente y nunca por canales inseguros.

---

## Créditos y licencia

**Autor:** Viveza Textil - Área de TI  
**Repositorio:** [https://github.com/vivezatextil/server-scripts/](https://github.com/vivezatextil/server-scripts/)  
**Licencia:** Uso interno y privado.

