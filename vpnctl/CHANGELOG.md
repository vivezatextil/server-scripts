# Changelog

Todos los cambios notables en el proyecto VPN Control Script serán documentados en este archivo.

El formato está basado en [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
y este proyecto adhiere a [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.1.0] - 2025-07-03

### ✨ Added
- **Sistema de logging completo** con rotación automática
  - Logs estructurados con timestamp, usuario, IP y acción
  - Rotación automática con `logrotate`
  - Niveles de log: INFO, WARN, ERROR
- **Funcionalidad de auditoría y reportes**
  - Reporte de conexiones con estado en tiempo real
  - Análisis de actividad de los últimos 7 días
  - Reporte de seguridad con conexiones activas
  - Exportación en formato JSON y texto
- **Nueva opción de menú "Auditoría y Reportes"**
  - Acceso centralizado a todas las funciones de monitoreo
  - Interfaz interactiva con `fzf`
- **Validación robusta de entrada de datos**
  - Verificación de caracteres especiales
  - Validación de longitud de nombres
  - Limpieza automática de espacios en blanco
- **Documentación completa**
  - README.md detallado con ejemplos
  - Guía de instalación y solución de problemas

### 🔧 Changed
- **Mejora en la seguridad de logging**
  - Permisos restrictivos (640) para archivos de log
  - Separación de errores con stderr (`>&2`)
  - Escape de caracteres especiales en logs
- **Optimización de funciones de eliminación**
  - Uso de `grep -F` para búsquedas exactas
  - Mejor manejo de caracteres especiales en nombres
- **Interfaz de usuario mejorada**
  - Colores consistentes en toda la aplicación
  - Mensajes de error más informativos
  - Mejor feedback visual

### 🔒 Security
- Protección contra inyección de comandos
- Validación estricta de entrada de datos
- Permisos de archivo seguros para logs
- Logging de acciones sensibles

### 📝 Documentation
- Documentación detallada en README.md
- Ejemplos de uso y configuración
- Guía de solución de problemas
- Información sobre estructura de archivos
- Instrucción para instalación con `curl` y `install.sh`
- Documentación de comando global `vpnctl`
- EXAMPLES.md con casos de uso prácticos
- Script de testing `test_audit.sh`

## [1.0.0] - 2025-07-01

### ✨ Added
- **Funcionalidades básicas de gestión de clientes VPN**
  - Listar clientes con estado de conexión
  - Agregar nuevos clientes con generación automática de claves
  - Eliminar clientes existentes
- **Integración con WireGuard**
  - Generación automática de claves públicas/privadas
  - Configuración automática de peers
  - Sincronización con el servidor WireGuard
- **Interfaz de usuario interactiva**
  - Menú principal con `fzf`
  - Selección visual de opciones
  - Validación básica de entrada
- **Gestión automática de IPs**
  - Asignación secuencial de direcciones IP
  - Detección de IPs disponibles
  - Prevención de conflictos de direcciones

### 🔧 Technical
- Estructura modular con funciones separadas
- Compatibilidad con Bash 4.0+
- Dependencia de `fzf` para interfaz interactiva
- Soporte para Ubuntu/Debian

---

## Formato de entrada

- **✨ Added**: Para nuevas funcionalidades
- **🔧 Changed**: Para cambios en funcionalidades existentes
- **📝 Deprecated**: Para funcionalidades que serán removidas
- **🗑️ Removed**: Para funcionalidades removidas
- **🔧 Fixed**: Para correcciones de bugs
- **🔒 Security**: Para mejoras de seguridad
- **📝 Documentation**: Para cambios en documentación

