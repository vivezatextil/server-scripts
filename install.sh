#!/bin/bash
# Instalación de Server Scripts
# Versión: 2.0.1
#
# Fecha de creación: 2025-06-19
# Última modificación: 2025-07-02
# Autor: Jacob Palomo

# Variables
USER_NAME=${SUDO_USER:-$(whoami)}
REPO_ALIAS="github-vivezatextil"
REPO_PATH="vivezatextil/server-scripts.git"
HOME_DIR=$(eval echo "~$USER_NAME")
CLONE_DIR="$HOME_DIR/server-scripts"
TARGET_DIR="/opt/server-scripts"
BIN_DIR="/usr/local/bin"

# Verifica si ya existe clonación
if [ -d "$CLONE_DIR" ]; then
  echo "El directorio $CLONE_DIR ya existe. Abortando..."
  exit 1
fi

echo "Clonando repositorio..."
sudo -u "$USER_NAME" git clone git@$REPO_ALIAS:$REPO_PATH "$CLONE_DIR"
if [ $? -ne 0 ]; then
  echo "Error al clonar el repositorio. Verifica tu conexión y permisos."
  exit 1
fi

echo "Moviendo el repositorio a $TARGET_DIR (requiere sudo)..."
sudo mv "$CLONE_DIR" "$TARGET_DIR"
if [ $? -ne 0 ]; then
  echo "Error al mover la carpeta. ¿Tienes permisos sudo?"
  exit 1
fi

echo "Cambiando propietario a $USER_NAME..."
sudo chown -R "$USER_NAME":"$USER_NAME" "$TARGET_DIR"

echo "Asignando permisos de ejecución a scripts .sh..."
sudo find "$TARGET_DIR" -type f -name "*.sh" -exec chmod +x {} \;

# Procesa carpetas de scripts y crea symlinks
SCRIPT_FOLDERS=("backupmgr" "usermgr")

for folder in "${SCRIPT_FOLDERS[@]}"; do
  SCRIPTS_PATH="$TARGET_DIR/$folder"
  if [ -d "$SCRIPTS_PATH" ]; then
    echo "Procesando scripts en $SCRIPTS_PATH"
    for script in "$SCRIPTS_PATH"/*.sh; do
      [ -e "$script" ] || continue
      script_name=$(basename "$script" .sh)
      symlink_path="$BIN_DIR/$script_name"
      echo "Creando symlink $symlink_path -> $script"
      sudo ln -sf "$script" "$symlink_path"
    done
  else
    echo "Carpeta $SCRIPTS_PATH no encontrada, se omite."
  fi
done

echo "Instalación completada correctamente."
echo "Ahora puedes ejecutar los scripts con los comandos globales: backupmgr, usermgr"
