#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

# ----------------------------------------------------------------------------------------
# Gestor avanzado de usuarios SSH - Versión 1.1.0 (rama usermgr/002-check-dependencies)
#
# Agregado:
# - Validación de dependencias críticas
# - Pregunta interactiva para instalar dependencias faltantes (fzf, ssh-keygen, etc)
# ----------------------------------------------------------------------------------------

# Colores para la consola
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m' # sin color (not color)

# Directorios y archivos
LOG_DIR="/var/log/usermgr"
LOG_FILE="$LOG_DIR/usermgr.log"
KEYS_DIR="/var/lib/usermgr/keys"

# Version del script
VERSION="1.1.0"

# Usuario real que ejecuta el script (si está con sudo, sera SUDO_USER)
RUN_USER="${SUDO_USER:-$USER}"

# ----------- FUNCIONES -----------

# Mostrar versión con color
mostrar_version() {
  echo -e "${CYAN}Gestor de Usuarios SSH - Versión $VERSION${NC}"
}

# Validar que el script se ejecute con permisos root
validar_root() {
  if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}Error: Este script debe ejecutarse con sudo o como root.${NC}"
    exit 1
  fi
}

# Validar que el usuario real está en grupo sudo
validar_grupo_sudo() {
  if ! groups "$RUN_USER" | grep -qw "sudo"; then
    echo -e "${RED}Acceso denegado: solo usuarios del grupo sudo pueden ejecutar este script.${NC}"
    exit 1
  fi
}

# Preparar directorios y permisos para logs y claves SSH exportables
preparar_directorios() {
  mkdir -p "$LOG_DIR" "$KEYS_DIR"
  chown root:sudo "$LOG_DIR" "$KEYS_DIR"
  chmod 750 "$LOG_DIR" "$KEYS_DIR"

  if [ ! -f "$LOG_FILE" ]; then
    touch "$LOG_FILE"
    chown root:sudo "$LOG_FILE"
    chmod 640 "$LOG_FILE"
    # Intentar poner append-only para seguridad, pero no obligatorio
    chattr +a "$LOG_FILE" 2>/dev/null || echo "Advertencia: no se pudo establecer atributo append-only en $LOG_FILE"
  fi
}

require_command() {
  command -v "$1" &>/dev/null
}

confirmar() {
  local prompt="${1:-¿Confirmas? [Y/n]: }"
  local respuesta
  read -rp "$prompt" respuesta
  respuesta="${respuesta:-Y}" # Si presiona Enter, asumimos Y
  if [[ "$respuesta" =~ ^[Yy]$ ]]; then
    return 0 # Sí
  else
    return 1 # No
  fi
}

validar_e_instalar_dependencias() {
  local deps=(fzf ssh-keygen passwd usermod gpasswd awk grep chage last)
  local faltantes=()

  for cmd in "${deps[@]}"; do
    if ! require_command "$cmd"; then
      faltantes+=("$cmd")
    fi
  done

  if [ ${#faltantes[@]} -ne 0 ]; then
    echo -e "\n${YELLOW}Faltan las siguientes dependencias necesarias:${NC}"
    printf '  - %s\n' "${faltantes[@]}"
    if confirmar "¿Deseas instalar estos paquetes ahora? [Y/n]: "; then
      echo "Instalando paquetes faltantes..."
      sudo apt update
      sudo apt install -y "${faltantes[@]}"
    else
      echo -e "${RED}Instalación cancelada. Debes instalar los paquetes faltantes manualmente para continuar.${NC}"
      exit 1
    fi
  fi
}

# ----------- SCRIPT PRINCIPAL -----------

clear
mostrar_version

validar_root
validar_grupo_sudo
preparar_directorios
validar_e_instalar_dependencias
clear

echo "Directorio de logs: $LOG_DIR"
echo "Archivo de log: $LOG_FILE"
echo "Directorio de claves SSH exportables: $KEYS_DIR"

echo
echo "Aquí empezaremos a construir las funcionalidades paso a paso..."

# Aquí se construiran las funcionalidades paso a paso...
