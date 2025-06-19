# !/bin/bash
# Script para generar los respaldos automáticos del servidor.
# Fecha de creación: 19/06/2025
# Autor: Jacob Palomo

set -euo pipefail

# Variables
BACKUP_DIR="/tmp/backup_servidor"
TIMESTAMP=$(date +"%Y-%m-%d_%H-%M-%S")
ARCHIVO="backup_${TIMESTAMP}.tar.gz"
ORIGENES=("/opt/scripts-servidor" "/etc/wireguard" "/var/lib/postgresql/data") # Ajusta según tu sistema

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

