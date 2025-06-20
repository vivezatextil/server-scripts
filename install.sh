# !/bin/bash
# Instalación de Server Scripts
# Versión: 2.0.0
#
# Fecha de creación: 2025-06-19
# Autor: Jacob Palomo
#
# Última modificación: 2025-06-20

# Variables
USER_NAME=${SUDO_USER:-$(whoami)}
REPO_ALIAS="github-vivezatextil"
REPO_PATH="vivezatextil/server-scripts.git"
HOME_DIR=$(eval echo "~$USER_NAME")
CLONE_DIR="$HOME_DIR/server-scripts"
TARGET_DIR="/opt/server-scripts"
BIN_DIR="/usr/local/bin"

# Clona en home si no existe
if [ -d "$CLONE_DIR" ]; then
  echo "El directorio $CLONE_DIR ya eciste. Abortando..."
  exit 1
fi

echo "Clonando repositorio..."
sudo -u "$USER_NAME" git clone git@$REPO_ALIAS:$REPO_PATH $CLONE_DIR
if [ $? -ne 0 ]; then
  echo "Error al clonar el repositorio. Verifica tu conxión y permisos."
  exit 1
fi

# Mueve a /opt (requiere sudo)
echo "Moviendo el repositorio a $TARGET_DIR (requiere sudo)..."
sudo mv "$CLONE_DIR" "$TARGET_DIR"
if [ $? -ne 0 ]; then
  echo "Error al mover la carpeta. ¿Tienes permisos sudo?"
  exit 1
fi

# Cambia el propietario para que el usuario actual tenga acceso
sudo chown -R "$USER_NAME":"$USER_NAME" "$TARGET_DIR"

# Dá permisos de ejecución a todos los scripts .sh dentro del repo
echo "Asignando permisos de ejecución..."
sudo find "$TARGET_DIR" -type f -name "*.sh" -exec chmod +x {} \;

# Crea symlinks para los scripts en /usr/local/bin
SCRIPT_FOLDERS=("backupmgr")

for folder in "${SCRIPT_FOLDERS[@]}"; do
  SCRIPTS_PATH="$TARGET_DIR/$folder"
  if [ -d "$SCRIPTS_PATH" ]; then
    echo "Procesando scripts en $SCRIPTS_PATH"
    for script in "$SCRIPTS_PATH"/*.sh; do
      # Verifica que exista algún archivo .sh
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

echo "Instalación de server-scripts para Viveza Textil completada correctamente."
