# VPN Control Script 🚀

[![Version](https://img.shields.io/badge/version-1.1.0-blue.svg)](./CHANGELOG.md)
[![License](https://img.shields.io/badge/license-Proprietary-red.svg)](./LICENSE)
[![Shell](https://img.shields.io/badge/shell-bash-yellow.svg)](#)

## 📖 Descripción

Script profesional de administración VPN que permite gestionar configuraciones de WireGuard de manera eficiente y segura. Incluye un sistema completo de logging, auditoría y reportes para el monitoreo en tiempo real de la infraestructura VPN.

### ✨ Características principales

- 🔐 **Gestión completa de clientes VPN**
- 📊 **Sistema de auditoría y reportes avanzados**
- 📝 **Logging detallado con rotación automática**
- 🎨 **Interfaz interactiva con `fzf`**
- 🛡️ **Validación robusta de entrada de datos**
- 📈 **Análisis de actividad y estadísticas**
- 🔍 **Monitoreo de conexiones en tiempo real**

## 🔧 Requerimientos

### Sistema operativo
- Linux (Ubuntu/Debian recomendado)
- Acceso root (`sudo`)

### Dependencias
- **WireGuard**: Para la funcionalidad VPN
- **fzf**: Para la interfaz interactiva
- **Bash 4.0+**: Shell compatible

## 📦 Instalación

### Método 1: Instalación automática (Recomendado)

Este script forma parte del repositorio **server-scripts**. Para instalar todos los scripts del repositorio:

```bash
# Instalación con una sola línea
curl -o- https://raw.githubusercontent.com/vivezatextil/server-scripts/main/install.sh | sudo bash
```

Esto automáticamente:
- 🔄 Clona el repositorio a `/opt/server-scripts`
- ⚡ Crea symlinks para `backupmgr`, `usermgr` y `vpnctl` en `/usr/local/bin`
- 📝 Hace ejecutables todos los scripts `.sh`
- 🌐 Permite ejecutar los scripts desde cualquier ubicación

### Método 2: Instalación manual

#### 1. Instalar dependencias
```bash
# Ubuntu/Debian
sudo apt update
sudo apt install fzf wireguard wireguard-tools

# CentOS/RHEL
sudo yum install epel-release
sudo yum install fzf wireguard-tools
```

#### 2. Clonar repositorio manualmente
```bash
# Clonar el repositorio
git clone https://github.com/vivezatextil/server-scripts.git
cd server-scripts

# Ejecutar instalador
sudo ./install.sh
```

### 3. Configuración inicial de WireGuard

Asegúrate de que WireGuard esté configurado y funcionando:
```bash
# Verificar estado
sudo wg show

# Verificar configuración
sudo cat /etc/wireguard/wg0.conf
```

## 🎮 Uso

### Ejecución

Después de la instalación con `install.sh`, el script está disponible globalmente:

```bash
# Ejecutar desde cualquier ubicación (recomendado)
sudo vpnctl
```

### Formas alternativas de ejecución

```bash
# Opción 1: Comando global (post-instalación)
sudo vpnctl

# Opción 2: Desde el directorio de instalación
cd /opt/server-scripts/vpnctl
sudo ./vpnctl.sh

# Opción 3: Ruta absoluta
sudo /opt/server-scripts/vpnctl/vpnctl.sh
```

### ✨ Ventajas del comando global

- 🚀 **Acceso instantáneo**: Ejecuta `sudo vpnctl` desde cualquier directorio
- 🔄 **Consistencia**: Mismo comportamiento que `backupmgr` y `usermgr`
- 📝 **Simplicidad**: No necesitas recordar rutas largas

### Menú principal
```
┌─────────────────────────────────────────┐
│              VPN Control v1.1.0        │
├─────────────────────────────────────────┤
│ > Listar clientes                      │
│   Agregar cliente                      │
│   Eliminar cliente                     │
│   Auditoría y Reportes                 │
│   Salir                                │
└─────────────────────────────────────────┘
```

## 📋 Funcionalidades

### 👥 Gestión de Clientes

#### Listar Clientes
- Muestra todos los clientes configurados
- Estado de conexión en tiempo real
- Información de IP asignada
- Última conexión registrada

#### Agregar Cliente
- Validación robusta de nombres
- Generación automática de claves
- Asignación automática de IPs
- Creación de archivos de configuración

#### Eliminar Cliente
- Selección interactiva con `fzf`
- Opción de cancelar operación
- Limpieza completa de configuraciones
- Sincronización automática con WireGuard

### 📊 Auditoría y Reportes

#### Reporte de Conexiones
```bash
=== REPORTE DE CONEXIONES VPN ===
Fecha: 2025-07-03 15:13:14
Generado por: admin

=== RESUMEN DE CLIENTES ===
John Doe | Laptop Windows         10.0.0.3/32    Conectado
Jane Smith | iPhone                10.0.0.4/32    Nunca conectado
Bob Wilson | MacBook Pro           10.0.0.6/32    Desconectado (2025-07-03 12:30:15)

=== ESTADÍSTICAS ===
Total de clientes: 3
Conectados actualmente: 1
Nunca conectados: 1
Desconectados: 1
```

#### Ver Logs del Sistema
- Últimas 50 entradas del log
- Colores por nivel de log (INFO/WARN/ERROR)
- Filtrado automático por tipos

#### Análisis de Actividad
- Actividad por día (últimos 7 días)
- Acciones más frecuentes
- Usuarios más activos
- Estadísticas de uso

#### Reporte de Seguridad
- Conexiones activas de WireGuard
- Errores recientes del sistema
- Configuración de red actual
- IPs asignadas y disponibles

## 📁 Estructura de Archivos

### Repositorio server-scripts
```
server-scripts/
├── install.sh                  # Instalador automático
├── README.md                   # Documentación general
├── CHANGELOG.md                # Cambios del repositorio
├── backupmgr/                  # Scripts de backup
├── usermgr/                    # Scripts de gestión de usuarios
└── vpnctl/                     # Scripts de VPN (este directorio)
    ├── vpnctl.sh               # Script principal
    ├── README.md               # Este archivo
    ├── CHANGELOG.md            # Historial de cambios
    └── test_audit.sh          # Script de pruebas
```

### Archivos generados en el sistema
```
/etc/wireguard/
├── wg0.conf                    # Configuración del servidor
└── clients/                    # Configuraciones de clientes
    ├── wg0-client-John_Doe-Laptop_Windows.conf
    └── wg0-client-Jane_Smith-iPhone.conf

/var/log/vpnctl/
├── vpnctl.log                  # Log principal
├── vpnctl.log.1.gz            # Logs rotados
└── audit/                      # Reportes de auditoría
    ├── connections_20250703.json
    └── summary_20250703.txt

/etc/logrotate.d/
└── vpnctl                      # Configuración de rotación

/opt/server-scripts/            # Ubicación después de install.sh
└── vpnctl/
    └── vpnctl.sh               # Script ejecutable
```

## 📝 Sistema de Logging

### Ubicación de logs
- **Archivo principal**: `/var/log/vpnctl/vpnctl.log`
- **Archivos de auditoría**: `/var/log/vpnctl/audit/`
- **Rotación**: Automática (diaria para logs, semanal para auditoría)

### Niveles de log
- **INFO**: Operaciones normales
- **WARN**: Advertencias y situaciones no críticas
- **ERROR**: Errores que requieren atención

### Formato de log
```
[2025-07-03 15:13:14] [INFO] [User: admin] [IP: 192.168.1.100] [Action: ADD_CLIENT] Cliente agregado: John Doe | Laptop Windows
```

## 🔒 Seguridad

### Permisos de archivos
- Logs: `640` (rw-r-----)
- Directorio de logs: `750` (rwxr-x---)
- Script: `755` (rwxr-xr-x)

### Validaciones implementadas
- Verificación de caracteres permitidos
- Validación de longitud de nombres
- Escape de caracteres especiales
- Protección contra inyección de comandos

## 🛠️ Configuración

### Variables principales
```bash
VERSION="1.1.0"
WG_CONF="/etc/wireguard/wg0.conf"
CLIENTS_DIR="/etc/wireguard/clients"
WG_INTERFACE="wg0"
VPN_NETWORK="10.0.0"
VPN_CIDR="24"
DNS="8.8.8.8"
```

### Personalización
Puedes modificar estas variables al inicio del script para adaptarlo a tu configuración.

## 🐛 Solución de Problemas

### Problemas comunes

1. **Error: "fzf no está instalado"**
   ```bash
   sudo apt install fzf
   ```

2. **Error: "Permission denied"**
   ```bash
   sudo ./vpnctl.sh
   ```

3. **WireGuard no responde**
   ```bash
   sudo systemctl status wg-quick@wg0
   sudo systemctl restart wg-quick@wg0
   ```

4. **Logs no se crean**
   ```bash
   sudo mkdir -p /var/log/vpnctl/audit
   sudo chown root:root /var/log/vpnctl
   sudo chmod 750 /var/log/vpnctl
   ```

## 📄 Licencia

Este software es propiedad privada de **Viveza Textil** y está destinado únicamente para uso interno de la empresa. Consulta el archivo [LICENSE](LICENSE) para más detalles.

## 👨‍💻 Autor

- **Viveza Textil** - Desarrollo inicial

## 📞 Soporte

Si tienes problemas o preguntas:

1. Revisa la sección de [Solución de Problemas](#-solución-de-problemas)
2. Consulta los logs en `/var/log/vpnctl/vpnctl.log`
3. Crea un issue en el repositorio

---

⭐ **¡Si este proyecto te ha sido útil, considera darle una estrella!** ⭐

