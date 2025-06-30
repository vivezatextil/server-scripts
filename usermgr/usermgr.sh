#!/bin/bash
set -euo pipefail
IFS=$'\n\t'

# ----------------------------------------------------------------------------------------
# Gestor avanzado de usuarios SSH - Versión 1.7.0 (rama usermgr/007-user-management-enhancements)
#
# Agregado:
# - Función `cambiar_rol_usuario` para modificar rol de usuarios.
#
# Modificado:
# - Función `asignar_rol_usuario` para solo solicitar el rol que le será asignado al usuario (al crearlo o cambiar su rol)
# - Nombre de la función `asignar_rol_usuario` por `solicitar_rol_usuario`.
# 
# ----------------------------------------------------------------------------------------

# Colores para la consola
RED='\033[0;31m'
GREEN='\033[0;32m'
CYAN='\033[38;5;80m'
YELLOW='\033[1;33m'
BOLD='\033[1m'
NC='\033[0m' # sin color (not color)

# Directorios y archivos
LOG_DIR="/var/log/usermgr"
LOG_FILE="$LOG_DIR/usermgr.log"
KEYS_DIR="/var/lib/usermgr/keys"
SSH_CONFIG="/etc/ssh/sshd_config"

# Version del script
VERSION="1.7.0"

# Usuario real que ejecuta el script (si está con sudo, sera SUDO_USER)
RUN_USER="${SUDO_USER:-$USER}"

USUARIO_PROTEGIDO="vivezatextil"

CREATED_USERS=()
BLOCKED_USERS=()

# ----------- FUNCIONES -----------

# Permite imprimir un mensaje en consola
mostrar_mensaje() {
  local mensaje="$1"
  local color="${2:-$NC}" # Color principal, por defecto sin color

  echo -e "${color}${mensaje}${NC}"
  read -rp "Presiona Enter para continuar..."
  clear
}

# Mostrar versión con color
mostrar_version() {
  echo -e "${CYAN}Gestor de Usuarios SSH - Versión ${VERSION}${NC}"
}

# Validar que el script se ejecute con permisos root
validar_root() {
  if [ "$EUID" -ne 0 ]; then
    #echo -e "${RED}Error: Este script debe ejecutarse con sudo o como root.${NC}"
    mostrar_mensaje "Error: Este script debe ejecutarse con sudo o como root." "$RED"
    exit 1
  fi
}

# Validar que el usuario real está en grupo sudo
validar_grupo_sudo() {
  if ! groups "$RUN_USER" | grep -qw "sudo"; then
    mostrar_mensaje "Acceso denegado: solo usuarios del grupo sudo pueden ejecutar este script." "$RED"
    exit 1
  fi
}

# Permite registrar las acciones del usuario que ejecuta el script.
log_accion() {
  local msg="$1"
  local estado="${2:-OK}"
  local pid=$$
  local tty=$(tty)
  local ip="local"

  # Si el usuario está conectado via SSH, extraemos IP
  if [ -n "${SSH_CLIENT:-}" ]; then
    ip=$(echo "$SSH_CLIENT" | awk '{print $1}')
  fi

  local timestamp
  timestamp=$(date '+%Y-%m-%d %H:%M:%S')

  # Registro detallado con campos delimitados para posible análisis posterior
  local log_line="$timestamp | PID:$pid | TTY:$tty | IP:$ip | USER:$RUN_USER | ESTADO:$estado | ACCION:$msg"

  echo "$log_line" >> "$LOG_FILE"
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

# Permite verificar si existe (está instalado) o no un comando en el sistema
require_command() {
  command -v "$1" &>/dev/null
}

# Confirmación de instalación de dependencias necesarias para la ejecución del script
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

# Permite validar las dependencias necesarias antes de ejecutar el script
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
      apt update
      apt install -y "${faltantes[@]}"
      log_accion "Dependencias necesarias instaladas."
    else
      mostrar_mensaje "Instalación cancelada. Debes instalar los paquetes faltantes manualmente para continuar." "$RED"
      exit 1
    fi
  fi
}

cargar_usuarios() {
  mapfile -t existing_users < <(grep "^AllowUsers" "$SSH_CONFIG" 2>/dev/null | sed "s/^AllowUsers//" | tr -s ' ' '\n' | sed '/^$/d')

  for u in "${existing_users[@]}"; do
		if [[ "$u" != "$USUARIO_PROTEGIDO" ]]; then
    	CREATED_USERS+=("$u")
		fi
  done

  mapfile -t system_users < <(awk -F: '$3 >= 1000 && $1 != "nobody" {print $1}' /etc/passwd)

  for u in "${system_users[@]}"; do
    if [[ "$u" != "$USUARIO_PROTEGIDO" ]] && ! [[ " ${CREATED_USERS[*]} " =~ " $u " ]]; then
      BLOCKED_USERS+=("$u")
    fi
  done
}

validar_no_protegido() {
	local usuario="$1"
	if [[ "$usuario" == "$USUARIO_PROTEGIDO" ]]; then
		mostrar_mensaje "Operacion no permitida sobre el usuario '$USUARIO_PROTEGIDO'." "$RED"
		log_accion "Intento bloqueado de operación sobre usuario protegido '$USUARIO_PROTEGIDO'." "ERROR"
		return 1
	fi
	return 0
}

actualizar_sshd_config() {
  echo -e "${CYAN}Actualizando configuración SSH...${NC}"

  local allowed_users
  allowed_users=$(printf '%s ' "${CREATED_USERS[@]}")
  allowed_users=${allowed_users%% }

  sudo cp "$SSH_CONFIG" "${SSH_CONFIG}.backup.$(date +%s)" 2>/dev/null

  TEMP_CONFIG=$(mktemp /tmp/ssh_config.tmp.XXXXXX)
  trap 'rm -f "$TEMP_CONFIG"' EXIT

  grep -v '^AllowUsers' "$SSH_CONFIG" > "$TEMP_CONFIG"

  if [ -z "$allowed_users" ]; then
    echo '# No hay usuarios permitidos configurados (AllowUsers omitido)' >> "$TEMP_CONFIG"
    mostrar_mensaje "Advertencia: No hay usuarios permitidos configurados en SSH." "$YELLOW"
  else
    echo "AllowUsers $allowed_users" >> "$TEMP_CONFIG"
  fi

  cat >> "$TEMP_CONFIG" <<EOF
# Configuración generada por usermgr
PasswordAuthentication no
PermitRootLogin no
ChallengeResponseAuthentication no
UsePAM yes
EOF

  if sshd -t -f "$TEMP_CONFIG"; then
    sudo mv "$TEMP_CONFIG" "$SSH_CONFIG"
    sudo chmod 644 "$SSH_CONFIG"

    echo -e "${GREEN}Configuración SSH actualizada correctamente.${NC}"
    
    if systemctl restart sshd; then
      echo -e "${GREEN}Servicio SSH reiniciado correctamente.${NC}"
    else
      mostrar_mensaje "Error reiniciando SSH." "$RED"
    fi
  else
    mostrar_mensaje "Error: Configuración SSH inválida, no se aplicó." "$RED"
    mostrar_mensaje "Revisa manualmente el archivo temporal: $TEMP_CONFIG" "$RED"
  fi
  trap - EXIT
}

declare -A permisos_funciones=(
  ["Agregar usuario"]="cto gerente_ti coordinador_ti admin_redes"
  ["Cambiar rol usuario"]="cto seguridad_info lider_desarrollo"
  ["Eliminar usuario"]="cto seguridad_info"
  ["Ver usuarios"]="cto gerente_ti coordinador_ti admin_redes seguridad_info soporte_tecnico dba lider_desarrollo project_manager cloud_devops"
  ["Bloquear acceso SSH"]="cto seguridad_info"
  ["Desbloquear acceso SSH"]="cto seguridad_info"
  ["Cambiar contraseña SSH"]="cto soporte_tecnico seguridad_info"
  ["Cambiar contraseña login"]="cto gerente_ti coordinador_ti admin_redes seguridad_info soporte_tecnico dba lider_desarrollo project_manager cloud_devops"
  ["Bloquear acceso login"]="cto seguridad_info"
  ["Desbloquear acceso login"]="cto seguridad_info"
  ["Generar reporte"]="cto gerente_ti coordinador_ti admin_redes seguridad_info soporte_tecnico dba lider_desarrollo project_manager cloud_devops"
  ["Ayuda"]="cto gerente_ti coordinador_ti admin_redes seguridad_info soporte_tecnico dba lider_desarrollo project_manager cloud_devops"
  ["Salir"]="cto gerente_ti coordinador_ti admin_redes seguridad_info soporte_tecnico dba lider_desarrollo project_manager cloud_devops"
)

declare -A max_usuarios_por_rol=(
  ["cto"]=1
  ["gerente_ti"]=2
  ["coordinador_ti"]=3
  ["admin_redes"]=4
  ["admin_sistemas"]=4
  ["seguridad_info"]=5
  ["dba"]=3
  ["lider_desarrollo"]=6
  ["project_manager"]=2
  ["cloud_devops"]=3
  ["soporte_tecnico"]=5
)

roles_disponibles=(
  "cto"
  "gerente_ti"
  "coordinador_ti"
  "admin_redes"
  "admin_sistemas"
  "seguridad_info"
  "dba"
  "lider_desarrollo"
  "project_manager"
  "cloud_devops"
  "soporte_tecnico"
)

roles_admin=(
  "cto"
  "gerente_ti"
  "coordinador_ti"
  "admin_redes"
  "admin_sistemas"
  "seguridad_info"
  "dba"
  "lider_desarrollo"
  "project_manager"
  "cloud_devops"
)

# Función para contar usuarios en un rol
contar_usuarios_rol() {
  local rol="$1"
  local miembros
  miembros=$(getent group "$rol" | awk -F: '{print $4}' | tr ',' '\n' | sed '/^\s*$/d')
  echo "$miembros" | wc -l
}

# Función para obtener el rol más privilegiado del usuario actual
obtener_rol_actual() {
  local usuario="$RUN_USER"
  local grupos_usuario
  grupos_usuario=$(groups "$usuario")

  for rol in "${roles_disponibles[@]}"; do
    if [[ " $grupos_usuario " == *" $rol "* ]]; then
      echo "$rol"
      return
    fi
  done

  # Si no tiene ningún rol asignado
  echo "sin_rol"
}

solicitar_rol_usuario() {
  local usuario="$1"
  local rol_actual
  rol_actual=$(obtener_rol_actual)

  local roles_permitidos=()
  if [[ "$rol_actual" == "soporte_tecnico" ]]; then
    roles_permitidos=("soporte_tecnico")
  else
    roles_permitidos=("${roles_disponibles[@]}")
  fi

  local opciones_menu=("${roles_permitidos[@]}" "Cancelar")

  local rol=""
  while true; do
    rol=$(printf '%s\n' "${opciones_menu[@]}" | fzf --prompt="Rol: " --height=10 --border --ansi --no-multi --cycle)
    rol=$(echo "$rol" | tr -d '\r\n' | xargs)
    
    if [[ -z "$rol" || "$rol" == "Cancelar" ]]; then
      echo "Asignación de rol cancelada."
      rol=""
      break
    fi

    # Validar que el rol seleccionado sea válido
    if ! printf '%s\n' "${roles_permitidos[@]}" | grep -qx "$rol"; then
      mostrar_mensaje "Rol inválido. Por favor seleccione un rol válido." "$RED"
      continue
    fi

    # Validar máximo de usuarios para ese rol
    local max_permitidos=${max_usuarios_por_rol[$rol]:-0}
    local usuarios_actuales
    usuarios_actuales=$(contar_usuarios_rol "$rol")

    if (( usuarios_actuales >= max_permitidos )); then
      mostrar_mensaje "No se puede asignar el rol '$rol'. Límite máximo de $max_permitidos usuarios alcanzado." "$RED"
      continue
    fi

    break
  done

  if [[ -z "$rol" ]]; then
    return 1
  fi

  log_accion "Usuario '$usuario' asignado al rol '$rol'."
  echo "$rol"
  return 0
}

# Permite hacer obligatorio un dato, no continua hasta que haya sido completado
pedir_dato_obligatorio() {
  local prompt_msg="$1"
  local input=""
  while [[ -z "$input" ]]; do
    read -rp "$prompt_msg" input

    # Limpiar saltos de línea y retorno de carro
    input=$(echo "$input" | tr -d '\n\r')
    if [[ -z "$input" ]]; then
      mostrar_mensaje "Este dato es obligatorio, no puede quedar vacío." "$YELLOW"
    fi
  done

  echo "$input"
}

# Permite agregar un nuevo usuario al sistema. (sin acceso por contraseña)
agregar_usuario() {
  read -rp "Nombre de usuario: " username
  log_accion "Inicio creación de usuario '$username'."
  if id "$username" &>/dev/null; then
    echo -e "${RED}El usuario '$username' ya existe.${NC}"
    log_accion "Error al crear usuario, username '$username' existente." "ERROR"
    return
  fi

  # Solicitar rol que será asignado al nuevo usuario
  local role
  role=$(solicitar_rol_usuario "$username") || {
    log_accion "Creación de usuario '$username' cancelada."
    mostrar_mensaje "No se asignó rol. Abortando la creación del usuario." "$RED"
    return
  }

  echo "Ingrese los datos obligatorios para crear el usuario:"

  local gecos_name
  gecos_name=$(pedir_dato_obligatorio "Nombre completo: ")

  local gecos_office
  gecos_office=$(pedir_dato_obligatorio "Oficina / Cubículo: ")

  read -rp "Teléfono de trabajo (opcional): " gecos_workphone

  local gecos_cell
  gecos_cell=$(pedir_dato_obligatorio "Telefono o Celular: ")

  local gecos_string="${gecos_name},${gecos_office},${gecos_workphone},${gecos_cell}"

  adduser --gecos "$gecos_string" --disabled-password "$username"
  if [ $? -ne 0 ]; then
    log_accion "Error al crear el usuario '$username'." "ERROR"
    mostrar_mensaje "Error al crear el usuario." "$RED"
    return
  fi

  # Confirmar que usuario fue creado
  if ! id "$username" &>/dev/null; then
    log_accion "Usuario '$username' no fue creado tras adduser." "ERROR"
    mostrar_mensaje "Error inesperado: el usuario no fue creado." "$RED"
    return
  fi

  clear
  echo "Asigne una contraseña para '$username':"
  if ! passwd "$username"; then
    log_accion "Error asignando contraseña a usuario '$username'." "ERROR"
    mostrar_mensaje "Error al asignar la contraseña." "$RED"
    return
  fi
  log_accion "Contraseña asignada a usuario '$username'."

  clear

  # Bloquear acceso con contraseña (login) al servidor
  if usermod -L "$username"; then
    log_accion "Acceso login bloqueado para usuario '$username'."
  else
    log_accion "Error bloqueando acceso login para usuario '$username'." "ERROR"
    echo "${RED}Error bloqueando acceso login para usuario '$username'."
  fi

  # Asignar rol y grupo(s)
  usermod -aG "$role" "$username"
  if [[ " ${roles_admin[*]} " == *" $role "* ]]; then
    usermod -aG sudo "$username"
  fi
  log_accion "Rol '$role' asignado a '$username'."

  # Preparar carpeta para claves SSH exportables
  local user_key_dir="$KEYS_DIR/$username"
  mkdir -p "$user_key_dir"
  chown vivezatextil:sudo "$user_key_dir"
  chmod 750 "$user_key_dir"

  # Generar claves SSH con usuario vivezatextil
  local key_file="$user_key_dir/id_ed25519_$username"
  sudo -u vivezatextil ssh-keygen -t ed25519 -f "$key_file" -N "" -q

  if [ $? -ne 0 ]; then
    echo -e "${RED}Error generando claves SSH.${NC}"
    log_accion "Error generando claves SSH para usuario '$username'." "ERROR"
    return
  fi
  log_accion "Claves SSH generadas para '$username'."

  # Preparar carpeta .ssh en home del nuevo usuario
  mkdir -p /home/"$username"/.ssh
  chmod 700 /home/"$username"/.ssh

  # Copiar clave pública a authorized_keys
  cp "${key_file}.pub" /home/"$username"/.ssh/authorized_keys
  chmod 600 /home/"$username"/.ssh/authorized_keys
  chown -R "$username":"$username" /home/"$username"/.ssh
  log_accion "Claves SSH configuradas para '$username'."

  cargar_usuarios
  CREATED_USERS+=("$username")
  actualizar_sshd_config

  log_accion "Usuario '$username' creado con el rol '$role'."
  echo -e "\n${GREEN}Usuario '$username' creado con rol '$role' y acceso SSH.${NC}"
  read -rp "Presiona Enter para continuar..."
  clear
  echo -e "${CYAN}Clave privada exportable guardada en: $key_file${NC}"
  echo -e "\n${YELLOW}Para que el nuevo usuario pueda conectarse al servidor es necesario que se encuentre registrado y conectado a la VPN.${NC}"
  echo "Use vpnctl."
  echo
  read -rp "Presiona Enter para continuar..."
  clear
}

# Bloquear acceso login: solo usuarios con login activo (no bloqueados)
bloquear_login() {
  # Obtener usuarios con login activo (no bloqueados)
  mapfile -t usuarios_activos < <(awk -F: '$3 >= 1000 && $1 != "nobody" {print $1}' /etc/passwd)

  usuarios_a_bloquear=()
  for u in "${usuarios_activos[@]}"; do
		if [[ "$u" == "$USUARIO_PROTEGIDO" ]]; then
			continue
		fi
    passwd_status=$(passwd -S "$u" 2>/dev/null || echo "")
    if [[ "$passwd_status" != *" L "* ]] && [[ "$u" != "$USUARIO_PROTEGIDO" ]]; then
      usuarios_a_bloquear+=("$u")
    fi
  done

  if [ ${#usuarios_a_bloquear[@]} -eq 0 ]; then
    mostrar_mensaje "No hay usuarios con acceso login activo para bloquear." "$YELLOW"
    return
  fi

  # Añadir opción cancelar
  opciones=("${usuarios_a_bloquear[@]}" "Cancelar")

  local usuario
  usuario=$(printf '%s\n' "${opciones[@]}" | fzf --prompt="Seleccione usuario para bloquear login: " --height=20 --border --ansi --no-multi --cycle)
  if [[ -z "$usuario" || "$usuario" == "Cancelar" ]]; then
    mostrar_mensaje "Operación cancelada." "$YELLOW"
    return
  fi

	if ! validar_no_protegido "$usuario"; then
		return
	fi

  if usermod -L "$usuario"; then
    log_accion "Acceso login bloqueado para usuario '$usuario'."
    mostrar_mensaje "Acceso login bloqueado para '$usuario'." "$GREEN"
  else
    mostrar_mensaje "Error bloqueando acceso login para '$usuario'." "$RED"
  fi
}

# Desbloquear acceso login: solo usuarios que estén bloqueados
desbloquear_login() {
  mapfile -t usuarios_bloqueados < <(awk -F: '$3 >= 1000 && $1 != "nobody" {print $1}' /etc/passwd)

  usuarios_a_desbloquear=()
  for u in "${usuarios_bloqueados[@]}"; do
    passwd_status=$(passwd -S "$u" 2>/dev/null || echo "")
    if [[ "$passwd_status" == *" L "* ]] && [[ "$u" != "$USUARIO_PROTEGIDO" ]]; then
      usuarios_a_desbloquear+=("$u")
    fi
  done

  if [ ${#usuarios_a_desbloquear[@]} -eq 0 ]; then
    mostrar_mensaje "No hay usuarios bloqueados para desbloquear login." "$YELLOW"
    return
  fi

  opciones=("${usuarios_a_desbloquear[@]}" "Cancelar")

  local usuario
  usuario=$(printf '%s\n' "${opciones[@]}" | fzf --prompt="Seleccione usuario para desbloquear login: " --height=20 --border --ansi --no-multi --cycle)
  if [[ -z "$usuario" || "$usuario" == "Cancelar" ]]; then
    mostrar_mensaje "Operación cancelada." "$YELLOW"
    return
  fi

	if ! validar_no_protegido "$usuario"; then
		return
	fi

  if usermod -U "$usuario"; then
    log_accion "Acceso login desbloqueado para usuario '$usuario'."
    mostrar_mensaje "Acceso login desbloqueado para '$usuario'." "$GREEN"
  else
    mostrar_mensaje "Error desbloqueando acceso login para '$usuario'." "$RED"
  fi
}

# Bloquear acceso SSH: solo usuarios desbloqueados (CREATED_USERS)
bloquear_ssh() {
  if [ ${#CREATED_USERS[@]} -eq 0 ]; then
    mostrar_mensaje "No hay usuarios con acceso SSH para bloquear." "$YELLOW"
    return
  fi

  opciones=("${CREATED_USERS[@]}" "Cancelar")

  local usuario
  usuario=$(printf '%s\n' "${opciones[@]}" | fzf --prompt="Seleccione usuario para bloquear SSH: " --height=20 --border --ansi --no-multi --cycle)
  if [[ -z "$usuario" || "$usuario" == "Cancelar" ]]; then
    mostrar_mensaje "Operación cancelada." "$YELLOW"
    return
  fi

	if ! validar_no_protegido "$usuario"; then
		return
	fi

  CREATED_USERS=($(printf '%s\n' "${CREATED_USERS[@]}" | grep -v "^$usuario$"))
  BLOCKED_USERS+=("$usuario")

  actualizar_sshd_config
  log_accion "Acceso SSH bloqueado para usuario '$usuario'."
  mostrar_mensaje "Acceso SSH bloqueado para '$usuario'." "$GREEN"
}

# Desbloquear acceso SSH: solo usuarios bloqueados (BLOCKED_USERS)
desbloquear_ssh() {
  if [ ${#BLOCKED_USERS[@]} -eq 0 ]; then
    mostrar_mensaje "No hay usuarios bloqueados en SSH para desbloquear." "$YELLOW"
    return
  fi

  opciones=("${BLOCKED_USERS[@]}" "Cancelar")

  local usuario
  usuario=$(printf '%s\n' "${opciones[@]}" | fzf --prompt="Seleccione usuario para desbloquear SSH: " --height=20 --border --ansi --no-multi --cycle)
  if [[ -z "$usuario" || "$usuario" == "Cancelar" ]]; then
    mostrar_mensaje "Operación cancelada." "$YELLOW"
    return
  fi

	if ! validar_no_protegido "$usuario"; then
		return
	fi

  BLOCKED_USERS=($(printf '%s\n' "${BLOCKED_USERS[@]}" | grep -v "^$usuario$"))
  CREATED_USERS+=("$usuario")

  actualizar_sshd_config
  log_accion "Acceso SSH desbloqueado para usuario '$usuario'."
  mostrar_mensaje "Acceso SSH desbloqueado para '$usuario'." "$GREEN"
}

# Función para imprimir una fila con formato y colores
imprimir_fila() {
  local usuario="$1"
  local rol="$2"
  local acceso_login="$3"
  local acceso_ssh="$4"

  local color_login color_ssh

  if [[ "$acceso_login" == "activo" ]]; then
    color_login="$GREEN"
  else
    color_login="$RED"
  fi

  if [[ "$acceso_ssh" == "activo" ]]; then
    color_ssh="$GREEN"
  else
    color_ssh="$RED"
  fi

  printf "%-15s ${CYAN}%-17s${NC} ${color_login}%-13s${NC} ${color_ssh}%-10s${NC}\n" \
    "$usuario" "$rol" "$acceso_login" "$acceso_ssh"
}

# Función para mostrar la tabla completa de usuarios
imprimir_tabla_usuarios() {
  local usuarios=("$@") # Array de usuarios con formato: "usuario|rol|login|ssh"

  # Encabezado
  printf "${BOLD}${YELLOW}%-15s %-17s %-13s %-10s${NC}\n" "Usuario" "Rol" "Acceso Login" "Acceso SSH"
  printf "%-15s %-17s %-13s %-10s\n" "---------------" "-----------------" "-------------" "----------"

  for linea in "${usuarios[@]}"; do
    IFS='|' read -r usuario rol login ssh <<< "$linea"
    imprimir_fila "$usuario" "$rol" "$login" "$ssh"
  done
}

# Obtener rol o "sin_rol" si no tiene asignado ninguno
obtener_rol_usuario() {
  local usuario="$1"
  local grupos_usuario
  grupos_usuario=$(groups "$usuario" 2>/dev/null || echo "")

  for rol in "${roles_disponibles[@]}"; do
    if [[ " $grupos_usuario " == *" $rol "* ]]; then
      echo "$rol"
      return
    fi
  done
  echo "sin_rol"
}

# Función para determinar estado de login activo o bloqueado
estado_login() {
  local usuario="$1"
  local passwd_status
  passwd_status=$(passwd -S "$usuario" 2>/dev/null || echo "")
  if [[ "$passwd_status" == *" L "* ]]; then
    echo "bloqueado"
  else
    echo "activo"
  fi
}

# Función para determinar estado de SSH activo o bloqueado
estado_ssh() {
  local usuario="$1"
  # Si el usuario está en CREATED_USERS => activo
  # Si está en BLOCKED_USERS => bloqueado
  for u in "${CREATED_USERS[@]}"; do
    if [[ "$u" == "$usuario" ]]; then
      echo "activo"
      return
    fi
  done
  for u in "${BLOCKED_USERS[@]}"; do
    if [[ "$u" == "$usuario" ]]; then
      echo "bloqueado"
      return
    fi
  done
  # Por defecto bloqueado si no encontrado
  echo "bloqueado"
}

# Función para listar usuarios en tabla con colores
listar_usuarios() {
  local todos_usuarios=()
  # Unir ambos arrays para no perder ningún usuario
  # Usamos associative array para evitar duplicados
  declare -A seen=()
  for u in "${CREATED_USERS[@]}" "${BLOCKED_USERS[@]}"; do
		if [[ "$u" == "$USUARIO_PROTEGIDO" ]]; then
			continue
		fi
    seen["$u"]=1
  done
  for usuario in "${!seen[@]}"; do
    local rol
    rol=$(obtener_rol_usuario "$usuario")
    local login_estado
    login_estado=$(estado_login "$usuario")
    local ssh_estado
    ssh_estado=$(estado_ssh "$usuario")

    todos_usuarios+=("$usuario|$rol|$login_estado|$ssh_estado")
  done

  imprimir_tabla_usuarios "${todos_usuarios[@]}"

  echo
  read -rp "Presiona Enter para continuar..."
}

# Función para cambiar el rol de un usuario existente (excepto vivezatextil)
cambiar_rol_usuario() {
  cargar_usuarios

  # Combinar arrays y eliminar duplicados con un map asociativo, excluyendo 'vivezatextil'
  declare -A usuarios_map=()
  for u in "${CREATED_USERS[@]}" "${BLOCKED_USERS[@]}"; do
    if [[ "$u" != $USUARIO_PROTEGIDO ]]; then
      usuarios_map["$u"]=1
    fi
  done

  # Convertir mapa a array
  local usuarios_filtrados=()
  for u in "${!usuarios_map[@]}"; do
    usuarios_filtrados+=("$u")
  done

  if [ ${#usuarios_filtrados[@]} -eq 0 ]; then
    mostrar_mensaje "No hay usuarios disponibles para cambiar rol." "$YELLOW"
    return
  fi

  usuarios_filtrados+=("Cancelar")

  local usuario
  usuario=$(printf '%s\n' "${usuarios_filtrados[@]}" | fzf --prompt="Seleccione usuario para cambiar rol: " --height=20 --border --ansi --no-multi --cycle)
  if [[ -z "$usuario" || "$usuario" == "Cancelar" ]]; then
    mostrar_mensaje "Operación cancelada." "$YELLOW"
    return
  fi

  # Solicitar nuevo rol
  local nuevo_rol
  nuevo_rol=$(solicitar_rol_usuario "$usuario") || {
    mostrar_mensaje "No se asignó rol. Abortando operación." "$RED"
    return
  }

  if ! id "$usuario" &>/dev/null; then
    mostrar_mensaje "Usuario '$usuario' no existe." "$RED"
    return
  fi

  # Remover usuario de roles anteriores (excepto sudo)
  for g in "${roles_disponibles[@]}"; do
    gpasswd -d "$usuario" "$g" &>/dev/null || true
  done

  # Agregar nuevo rol
  usermod -aG "$nuevo_rol" "$usuario" &>/dev/null

  # Gestionar sudo según rol admin
  if [[ " ${roles_admin[*]} " == *" $nuevo_rol "* ]]; then
    usermod -aG sudo "$usuario" &>/dev/null
  else
    gpasswd -d "$usuario" sudo &>/dev/null || true
  fi

  log_accion "Usuario '$usuario' cambiado al rol '$nuevo_rol'."
  mostrar_mensaje "Rol de usuario '$usuario' cambiado a '$nuevo_rol'." "$GREEN"
}

# Permite mostrar el menu en consola
mostrar_menu() {
  local rol_actual
  rol_actual=$(obtener_rol_actual)

  if [[ "$rol_actual" == "sin_rol" ]]; then
    echo -e "${RED}Error: No tienes asignado ningún rol válido para usar este script.${NC}"
    exit 1
  fi

  local opciones=(
    "Ver usuarios"
    "Agregar usuario"
    "Cambiar rol usuario"
    "Cambiar contraseña login"
    "Cambiar contraseña SSH"
    "Eliminar usuario"
    "Bloquear acceso SSH"
    "Desbloquear acceso SSH"
    "Bloquear acceso login"
    "Desbloquear acceso login"
    "Generar reporte"
    "Ayuda"
    "Salir"
  )

  local opciones_permitidas=()

  for opcion in "${opciones[@]}"; do
    local roles_permitidos="${permisos_funciones[$opcion]}"
    if [[ " $roles_permitidos " == *" $rol_actual "* ]]; then
      opciones_permitidas+=("$opcion")
    fi
  done

  printf '%s\n' "${opciones_permitidas[@]}" | fzf --prompt="Seleccione opción: " --height=18 --border --header="User Manager v${VERSION}" --cycle --bind 'q:abort'
}

# Ejecución de la opción seleccionada
menu_principal() {
	cargar_usuarios

  while true; do
    local opcion
    opcion=$(mostrar_menu)

    if [[ -z "$opcion" ]]; then
      echo "No seleccionaste ninguna opción valida. Por favor, intenta de nuevo."
      continue
    fi

    case "$opcion" in
      "Ver usuarios") listar_usuarios ;;
      "Agregar usuario") agregar_usuario ;;
      "Cambiar rol usuario") cambiar_rol_usuario ;;
      "Cambiar contraseña login") echo "Función Cambiar contraseña login aún no es implementada.";;
      "Cambiar contraseña SSH") echo "Función cambiar contraseña SSH aún no es implementada." ;;
      "Eliminar usuario") echo "Función Eliminar usuario aún no es implementada." ;;
      "Bloquear acceso SSH") bloquear_ssh ;;
      "Desbloquear acceso SSH") desbloquear_ssh ;;
      "Bloquear acceso login") bloquear_login ;;
      "Desbloquear acceso login") desbloquear_login ;;
      "Generar reporte") echo "Función Generar reporte aún no es implementada." ;;
      "Ayuda") echo "Función Mostrar ayuda aún no es implementada.";;
      "Salir")
	clear
        echo "¡Hasta pronto ${SUDO_USER:-$USER}!"
	exit 0
      ;;
      *)
        echo "Opción inválida."
      ;;
    esac

    clear
  done
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
echo -e "¡Bienvenido al ${BOLD}${CYAN}User Manager v${VERSION}${NC} ${SUDO_USER:-$USER}!"

menu_principal

