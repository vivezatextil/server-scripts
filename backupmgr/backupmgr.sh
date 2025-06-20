# !/bin/bash
# Server Backup Manager - backupmgr.sh
# Versión: 2.0.0
#
# Script para generar los respaldos automáticos del servidor.
# Fecha de creación: 19/06/2025
# Autor: Jacob Palomo

set -euo pipefail

# Variables
BACKUP_DIR="/tmp/server-backup"
TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
ARCHIVO="backup_${TIMESTAMP}.tar.gz"
ORIGENES=("/opt/server-scripts" "/etc/wireguard" "/var/lib/postgresql/data") # Ajusta según tu sistema

# Preparar directorio temporal
rm -rf "$BACKUP_DIR"
mkdir -p "$BACKUP_DIR"

# Crear backup comprimido
tar -czf "$BACKUP_DIR/$ARCHIVO" "${ORIGENES[@]}"

# Subir backup cifrado a Google Drive usando rclone
rclone copy "$BACKUP_DIR/$ARCHIVO" gdrive_enc:

# Limpiar backup local
rm -rf "$BACKUP_DIR"

# Rotación: eliminar backups en la nube más viejos de 7 días
rclone delete --min-age 7d --rmdirs gdrive_enc:

echo "Backup $ARCHIVO completado y sincronizado."

