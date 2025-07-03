# Ejemplos de Uso - VPN Control Script

Este archivo contiene ejemplos prácticos de cómo usar el script `vpnctl.sh` en diferentes escenarios.

## 🚀 Inicio Rápido

### Instalación y primer uso
```bash
# Instalar con una sola línea
curl -o- https://raw.githubusercontent.com/vivezatextil/server-scripts/main/install.sh | sudo bash

# Ejecutar desde cualquier ubicación (comando global)
sudo vpnctl
```

### Formas de ejecución
```bash
# Método recomendado: Comando global
sudo vpnctl

# Método alternativo: Desde directorio
cd /opt/server-scripts/vpnctl && sudo ./vpnctl.sh

# Método alternativo: Ruta absoluta
sudo /opt/server-scripts/vpnctl/vpnctl.sh
```

## 👥 Gestión de Clientes

### Agregar un nuevo cliente
1. Ejecutar el script: `sudo vpnctl`
2. Seleccionar "Agregar cliente"
3. Introducir nombre del cliente: `Juan Pérez`
4. Introducir dispositivo: `iPhone 15 Pro`
5. El script generará automáticamente:
   - Archivo de configuración: `/etc/wireguard/clients/wg0-client-Juan_Pérez-iPhone_15_Pro.conf`
   - IP asignada: `10.0.0.X/32`
   - Claves públicas/privadas

### Eliminar un cliente existente
1. Ejecutar el script: `sudo vpnctl`
2. Seleccionar "Eliminar cliente"
3. Usar `fzf` para seleccionar el cliente a eliminar
4. Opción "Cancelar" disponible para abortar la operación

### Listar todos los clientes
```
Cliente (Nombre | Dispositivo)        IP Asignada       Última conexión  Clave Pública
----------------------------          ----------        ---------------  -------------
Juan Pérez | iPhone 15 Pro           10.0.0.3/32       Conectado        abc123...
María García | MacBook Pro           10.0.0.4/32       Nunca            def456...
Carlos López | Windows Laptop        10.0.0.5/32       2025-07-03 14:30:15  ghi789...
```

## 📊 Auditoría y Reportes

### Generar reporte de conexiones
```bash
sudo vpnctl
# Seleccionar "Auditoría y Reportes" > "Generar reporte de conexiones"
```

**Output generado:**
- `/var/log/vpnctl/audit/connections_20250703.json` - Datos estructurados
- `/var/log/vpnctl/audit/summary_20250703.txt` - Resumen legible

### Ver logs del sistema
```bash
# Los logs se muestran con colores:
# 🟢 INFO - Operaciones normales
# 🟡 WARN - Advertencias
# 🔴 ERROR - Errores
```

### Análisis de actividad
```
=== ACTIVIDAD POR DÍA ===
2025-07-03  : 15 eventos
2025-07-02  : 8 eventos
2025-07-01  : 12 eventos

=== ACCIONES MÁS FRECUENTES ===
12 ADD_CLIENT
8 LIST_CLIENTS
5 REMOVE_CLIENT
3 AUDIT_REPORT
```

## 🔧 Configuración Personalizada

### Cambiar la red VPN
Editar variables en `vpnctl.sh`:
```bash
VPN_NETWORK="192.168.100"    # Cambiar de 10.0.0 a 192.168.100
VPN_CIDR="24"                # Mantener la máscara
```

### Cambiar el DNS
```bash
DNS="1.1.1.1"               # Cambiar a Cloudflare
# o
DNS="9.9.9.9"               # Cambiar a Quad9
```

## 🚨 Casos de Uso Específicos

### Escenario 1: Empresa pequeña
```
Clientes típicos:
- "Empleado 1 | Laptop Trabajo"
- "Empleado 2 | iPhone Personal"
- "Servidor Backup | Ubuntu Server"
```

### Escenario 2: Familia
```
Clientes típicos:
- "Papá | MacBook Pro"
- "Mamá | iPhone 14"
- "Hijo | Gaming PC"
- "Smart TV | Samsung 55\""
```

### Escenario 3: Desarrollador
```
Clientes típicos:
- "Dev Machine | Ubuntu 22.04"
- "Testing Phone | Android 13"
- "Cloud Server | AWS EC2"
- "Raspberry Pi | Home Lab"
```

## 🔍 Monitoreo y Mantenimiento

### Verificar conexiones activas
```bash
# Desde el script (Auditoría > Reporte de seguridad)
sudo vpnctl

# O manualmente
sudo wg show wg0
```

### Revisar logs en tiempo real
```bash
# Ver logs en vivo
sudo tail -f /var/log/vpnctl/vpnctl.log

# Filtrar solo errores
sudo grep "ERROR" /var/log/vpnctl/vpnctl.log
```

### Estadísticas rápidas
```bash
# Contar clientes totales
sudo grep -c "^# CLIENT:" /etc/wireguard/wg0.conf

# Ver archivos de configuración generados
ls -la /etc/wireguard/clients/
```

## ⚠️ Solución de Problemas Comunes

### Cliente no puede conectar
1. Verificar que WireGuard está ejecutándose:
   ```bash
   sudo systemctl status wg-quick@wg0
   ```

2. Revisar configuración del cliente en `/etc/wireguard/clients/`

3. Verificar logs del script:
   ```bash
   sudo grep "ADD_CLIENT" /var/log/vpnctl/vpnctl.log
   ```

### Problemas de permisos
```bash
# Arreglar permisos de logs
sudo chown -R root:root /var/log/vpnctl
sudo chmod 750 /var/log/vpnctl
sudo chmod 640 /var/log/vpnctl/*.log
```

### Error de red
```bash
# Verificar la configuración de red
sudo wg show wg0
sudo ip route show | grep wg0
```

## 🔄 Automatización

### Script de backup diario
```bash
#!/bin/bash
# backup_vpn_config.sh

DATE=$(date +%Y%m%d)
BACKUP_DIR="/backup/vpn"

# Crear backup de configuración
sudo cp /etc/wireguard/wg0.conf "$BACKUP_DIR/wg0.conf.$DATE"

# Generar reporte automático usando comando global
echo "1" | sudo vpnctl > /dev/null 2>&1  # Generar reporte silencioso
```

### Monitoreo con cron
```bash
# Agregar a crontab usando el comando global
# m h  dom mon dow   command
0 */6 * * * echo "4" | sudo vpnctl > /dev/null 2>&1  # Auditoría automática cada 6 horas
```

## 📝 Formatos de Exportación

### JSON (para análisis automatizado)
```json
[
  {
    "client": "Juan Pérez | iPhone 15 Pro",
    "ip": "10.0.0.3/32",
    "public_key": "abc123...",
    "status": "connected",
    "last_seen": "2025-07-03 15:13:14",
    "transfer": "1024 2048",
    "audit_time": "2025-07-03 15:13:14"
  }
]
```

### Texto (para informes)
```
=== REPORTE DE CONEXIONES VPN ===
Fecha: 2025-07-03 15:13:14
Generado por: admin

Total de clientes: 5
Conectados actualmente: 2
Nunca conectados: 1
Desconectados: 2
```

---

¿Necesitas más ejemplos específicos para tu caso de uso? ¡Consulta la documentación o crea un issue en el repositorio!
