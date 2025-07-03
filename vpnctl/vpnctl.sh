#!/bin/bash

VERSION="1.1.0"

WG_CONF="/etc/wireguard/wg0.conf"
CLIENTS_DIR="/etc/wireguard/clients"
WG_INTERFACE="wg0"
VPN_NETWORK="10.0.0"
VPN_CIDR="24"
DNS="8.8.8.8"

# Configuración de logging
LOG_DIR="/var/log/vpnctl"
LOG_FILE="$LOG_DIR/vpnctl.log"
AUDIT_DIR="$LOG_DIR/audit"
MAX_LOG_SIZE="10M"
MAX_LOG_FILES=5

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

if [[ $EUID -ne 0 ]]; then
  echo -e "${RED}Este script debe ejecutarse con sudo.${NC}"
  exit 1
fi

if ! command -v fzf &>/dev/null; then
  echo -e "${RED}fzf no está instalado. Instálalo para usar este script.${NC}"
  exit 1
fi

mkdir -p "$CLIENTS_DIR"
mkdir -p "$LOG_DIR" "$AUDIT_DIR"

# Inicializar logging
init_logging() {
  if [[ ! -f "$LOG_FILE" ]]; then
    touch "$LOG_FILE"
    chmod 640 "$LOG_FILE"
  fi
}

# Función de logging
write_log() {
  local level="$1"
  local action="$2"
  local details="$3"
  local user=$(who am i 2>/dev/null | awk '{print $1}' || echo "unknown")
  local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
  local ip_address=${SSH_CLIENT%% *}
  
  # Rotación de logs si es necesario
  if [[ -f "$LOG_FILE" ]] && [[ $(stat -f%z "$LOG_FILE" 2>/dev/null || stat -c%s "$LOG_FILE") -gt 10485760 ]]; then
    rotate_logs
  fi
  
  echo "[$timestamp] [$level] [User: $user] [IP: ${ip_address:-local}] [Action: $action] $details" >> "$LOG_FILE"
}

# Rotación de logs
rotate_logs() {
  for ((i=$MAX_LOG_FILES; i>=1; i--)); do
    if [[ -f "$LOG_FILE.$i" ]]; then
      if [[ $i -eq $MAX_LOG_FILES ]]; then
        rm -f "$LOG_FILE.$i"
      else
        mv "$LOG_FILE.$i" "$LOG_FILE.$((i+1))"
      fi
    fi
  done
  
  if [[ -f "$LOG_FILE" ]]; then
    mv "$LOG_FILE" "$LOG_FILE.1"
    touch "$LOG_FILE"
    chmod 640 "$LOG_FILE"
  fi
}

# Función para auditoría de conexiones
audit_connections() {
  local audit_file="$AUDIT_DIR/connections_$(date +%Y%m%d).json"
  local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
  
  echo "[" > "$audit_file"
  
  mapfile -t clients < <(grep -E "^# CLIENT:" "$WG_CONF" | cut -d ':' -f2- | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
  
  for i in "${!clients[@]}"; do
    local client_full="${clients[$i]}"
    local peer_block=$(awk "/# CLIENT: $client_full/{flag=1;next}/^$/{flag=0}flag" "$WG_CONF")
    local public_key=$(echo "$peer_block" | grep "PublicKey" | cut -d '=' -f2 | xargs)
    local allowed_ip=$(echo "$peer_block" | grep "AllowedIPs" | cut -d '=' -f2 | xargs)
    local last_handshake=$(wg show "$WG_INTERFACE" latest-handshake "$public_key" 2>/dev/null || echo "0")
    local transfer=$(wg show "$WG_INTERFACE" transfer "$public_key" 2>/dev/null || echo "0 0")
    
    local status="disconnected"
    local last_seen="never"
    
    if [[ -n "$last_handshake" ]] && [[ "$last_handshake" != "0" ]]; then
      local now=$(date +%s)
      local diff=$((now - last_handshake))
      if (( diff < 300 )); then
        status="connected"
      fi
      last_seen=$(date -d "@$last_handshake" '+%Y-%m-%d %H:%M:%S')
    fi
    
    cat >> "$audit_file" <<EOF
  {
    "client": "$client_full",
    "ip": "$allowed_ip",
    "public_key": "$public_key",
    "status": "$status",
    "last_seen": "$last_seen",
    "transfer": "$transfer",
    "audit_time": "$timestamp"
  }$([ $i -lt $((${#clients[@]} - 1)) ] && echo ",")
EOF
  done
  
  echo "]" >> "$audit_file"
}

init_logging

get_next_ip() {
  mapfile -t used_ips < <(grep "AllowedIPs" "$WG_CONF" | sed -n 's/AllowedIPs = //p' | cut -d '.' -f4 | cut -d '/' -f1 | sort -n)
  last_ip=2
  for ip in "${used_ips[@]}"; do
    if [[ $ip -eq $last_ip ]]; then
      last_ip=$((last_ip+1))
    else
      break
    fi
  done
  echo "$VPN_NETWORK.$last_ip"
}

is_connected() {
  local pubkey=$1
  local last_handshake
  last_handshake=$(wg show "$WG_INTERFACE" latest-handshake "$pubkey" 2>/dev/null)
  if [[ -z "$last_handshake" ]] || [[ "$last_handshake" == "0" ]]; then
    echo "Nunca"
    return
  fi
  local now
  now=$(date +%s)
  local diff=$(( now - last_handshake ))
  if (( diff < 300 )); then
    echo "Conectado"
  else
    local date_str
    date_str=$(date -d "@$last_handshake" +"%Y-%m-%d %H:%M:%S")
    local minutes_ago=$(( diff / 60 ))
    echo "$date_str ($minutes_ago min ago)"
  fi
}

list_clients() {
  mapfile -t clients < <(grep -E "^# CLIENT:" "$WG_CONF" | cut -d ':' -f2-)

  if [ ${#clients[@]} -eq 0 ]; then
    echo -e "${YELLOW}No hay clientes registrados.${NC}"
    sleep 3
    return
  fi

  YELLOW_BOLD="\033[1;33m"
  RESET_FORMAT="\033[0m"
  CYAN_COLOR="\033[0;36m"

  printf "${YELLOW_BOLD}%-35s %-18s %-15s %-44s${RESET_FORMAT}\n" \
    "Cliente (Nombre | Dispositivo)" "IP Asignada" "Última conexión" "Clave Pública"
  printf "${YELLOW_BOLD}%-35s %-18s %-15s %-44s${RESET_FORMAT}\n" \
    "----------------------------" "----------" "---------------" "-------------"

  for client_full in "${clients[@]}"; do
    peer_block=$(awk "/# CLIENT: $client_full/{flag=1;next}/^$/{flag=0}flag" "$WG_CONF")
    public_key=$(echo "$peer_block" | grep "PublicKey" | cut -d '=' -f2 | xargs)
    allowed_ip=$(echo "$peer_block" | grep "AllowedIPs" | cut -d '=' -f2 | xargs)

    estado=$(is_connected "$public_key")
    if [[ "$estado" == "Conectado" ]]; then
      color=$GREEN
    elif [[ "$estado" == "Nunca" ]]; then
      color=$RED
    else
      color=$YELLOW
    fi

    printf "%-35s ${CYAN_COLOR}%-18s${RESET_FORMAT} ${color}%-15s${RESET_FORMAT} %-44s\n" \
      "$client_full" "$allowed_ip" "$estado" "$public_key"
  done
  echo
  read -rp "Presiona Enter para volver al menú..."
}

# Función que solicita y valida el nombre del cliente
ask_client_name() {
    local client_name=""
    
    while true; do
        read -p "Introduce el nombre del cliente: " client_name
        
        # Eliminar espacios en blanco al inicio y final
        client_name=$(echo "$client_name" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
        
        # Verificar si está vacío
        if [[ -z "$client_name" ]]; then
            printf "${RED}Error: El nombre del cliente es obligatorio.${NC}\n" >&2
            sleep 2
            continue
        fi
        
        # Validar que no sea solo espacios
        if [[ "$client_name" =~ ^[[:space:]]+$ ]]; then
            printf "${RED}Error: El nombre del cliente no puede contener solo espacios.${NC}\n" >&2
            sleep 2
            continue
        fi
        
        # Validar caracteres permitidos (letras, números, espacios, guiones)
        if [[ ! "$client_name" =~ ^[a-zA-Z0-9[:space:]._-]+$ ]]; then
            printf "${RED}Error: El nombre del cliente solo puede contener letras, números, espacios, puntos, guiones y guiones bajos.${NC}\n" >&2
            sleep 3
            continue
        fi
        
        # Validar longitud mínima
        if [[ ${#client_name} -lt 2 ]]; then
            printf "${RED}Error: El nombre del cliente debe tener al menos 2 caracteres.${NC}\n" >&2
            sleep 2
            continue
        fi
        
        # Si llegamos aquí, el nombre es válido - RETORNAR EL VALOR
        echo "$client_name"
        return 0
    done
}

# Función que solicita y valida el nombre de dispositivo
ask_device_name() {
    local device_name=""
    
    while true; do
        read -p "Introduce el nombre del dispositivo: " device_name
        
        # Eliminar espacios en blanco al inicio y final
        device_name=$(echo "$device_name" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
        
        # Verificar si está vacío
        if [[ -z "$device_name" ]]; then
            printf "${RED}Error: El nombre del dispositivo es obligatorio.${NC}\n" >&2
            sleep 2
            continue
        fi
        
        # Validar que no sea solo espacios
        if [[ "$device_name" =~ ^[[:space:]]+$ ]]; then
            printf "${RED}Error: El nombre del dispositivo no puede contener solo espacios.${NC}\n" >&2
            sleep 2
            continue
        fi
        
        # Validar caracteres permitidos (AHORA CON ESPACIOS)
        if [[ ! "$device_name" =~ ^[a-zA-Z0-9[:space:]._-]+$ ]]; then
            printf "${RED}Error: El nombre del dispositivo solo puede contener letras, números, espacios, puntos, guiones y guiones bajos.${NC}\n" >&2
            sleep 3
            continue
        fi
        
        # Validar longitud mínima
        if [[ ${#device_name} -lt 2 ]]; then
            printf "${RED}Error: El nombre del dispositivo debe tener al menos 2 caracteres.${NC}\n" >&2
            sleep 2
            continue
        fi
        
        # Validar longitud máxima (opcional)
        if [[ ${#device_name} -gt 30 ]]; then
            printf "${RED}Error: El nombre del dispositivo no puede tener más de 30 caracteres.${NC}\n" >&2
            sleep 2
            continue
        fi
        
        # Si llegamos aquí, el nombre es válido - RETORNAR EL VALOR
        echo "$device_name"
        return 0
    done
}

add_client() {
	write_log "INFO" "ADD_CLIENT_START" "Iniciando proceso de agregar cliente"
	client_name=$(ask_client_name)
  if [[ -z "$client_name" ]]; then
    echo -e "${RED}El nombre no puede estar vacío.${NC}"
    write_log "ERROR" "ADD_CLIENT_FAILED" "Nombre de cliente vacío"
    sleep 2
    return
  fi
	device_name=$(ask_device_name)
  if [[ -z "$device_name" ]]; then
    echo -e "${RED}El dispositivo no puede estar vacío.${NC}"
    write_log "ERROR" "ADD_CLIENT_FAILED" "Nombre de dispositivo vacío"
    sleep 2
    return
  fi

  local client_full="${client_name} | ${device_name}"

  if grep -q "# CLIENT: $client_full" "$WG_CONF"; then
    echo -e "${RED}El cliente '$client_full' ya existe.${NC}"
    write_log "WARN" "ADD_CLIENT_DUPLICATE" "Cliente ya existe: $client_full"
    sleep 2
    return
  fi

  local client_ip_base client_ip
  client_ip_base=$(get_next_ip)
	client_ip="${client_ip_base}/${VPN_CIDR}"

  local private_key public_key preshared_key
  private_key=$(wg genkey)
  public_key=$(echo "$private_key" | wg pubkey)
  preshared_key=$(wg genpsk)

  safe_name="wg0-client-${client_name// /_}-${device_name// /_}.conf"

  cat > "$CLIENTS_DIR/$safe_name" <<EOF
[Interface]
PrivateKey = $private_key
Address = $client_ip
DNS = $DNS

[Peer]
PublicKey = $(wg show $WG_INTERFACE public-key)
PresharedKey = $preshared_key
Endpoint = vivezatextil.duckdns.org:51820
AllowedIPs = 0.0.0.0/0, ::/0
EOF

  cat >> "$WG_CONF" <<EOF

# CLIENT: $client_full
[Peer]
PublicKey = $public_key
PresharedKey = $preshared_key
AllowedIPs = $client_ip_base/32
EOF

  wg syncconf "$WG_INTERFACE" <(wg-quick strip "$WG_INTERFACE")
  
  write_log "INFO" "ADD_CLIENT_SUCCESS" "Cliente agregado: $client_full | IP: $client_ip_base | Archivo: $safe_name"

  echo -e "${GREEN}Cliente '$client_full' agregado con IP $client_ip${NC}"
  echo "Archivo de configuración: $CLIENTS_DIR/$safe_name"
  read -rp "Presiona Enter para continuar..."
}

remove_client() {
  write_log "INFO" "REMOVE_CLIENT_START" "Iniciando proceso de eliminar cliente"
  # Obtener clientes y limpiar espacios extra
  mapfile -t clients < <(grep -E "^# CLIENT:" "$WG_CONF" | cut -d ':' -f2- | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')

  if [ ${#clients[@]} -eq 0 ]; then
    echo -e "${YELLOW}No hay clientes para eliminar.${NC}"
    write_log "INFO" "REMOVE_CLIENT_EMPTY" "No hay clientes para eliminar"
    sleep 2
    return
  fi

	clients+=("Cancelar")

  selected=$(printf '%s\n' "${clients[@]}" | fzf --prompt="Cliente: " --height 40% --border --cycle --header="Eliminar cliente | VPN Control v${VERSION}" --color header:italic)

  if [ -z "$selected" ]; then
    echo "Operación cancelada"
    write_log "INFO" "REMOVE_CLIENT_CANCELLED" "Usuario canceló la operación"
    sleep 2
    return
  fi

	if [ "$selected" == "Cancelar" ]; then
		write_log "INFO" "REMOVE_CLIENT_CANCELLED" "Usuario seleccionó cancelar"
		return
	fi

  # Verificar que el cliente existe
  if ! grep -qF "# CLIENT: $selected" "$WG_CONF"; then
    echo -e "${RED}Cliente no encontrado.${NC}"
    read -rp "Presiona Enter para continuar..."
    return
  fi

  # Usar grep -n con -F (fixed strings) para obtener el número de línea exacto
  line_num=$(grep -nF "# CLIENT: $selected" "$WG_CONF" | cut -d: -f1)
  if [[ -n "$line_num" ]]; then
    # Eliminar exactamente 5 líneas: la línea del comentario + 4 líneas del peer
    sed -i "${line_num},+4d" "$WG_CONF"
  fi
  sed -i '/^$/N;/^\n$/D' "$WG_CONF"

  wg syncconf "$WG_INTERFACE" <(wg-quick strip "$WG_INTERFACE")

  nombre=$(echo "$selected" | cut -d '|' -f1 | xargs)
  dispositivo=$(echo "$selected" | cut -d '|' -f2 | xargs)
  safe_name="wg0-client-${nombre// /_}-${dispositivo// /_}.conf"
  rm -f "$CLIENTS_DIR/$safe_name"
  
  write_log "INFO" "REMOVE_CLIENT_SUCCESS" "Cliente eliminado: $selected | Archivo: $safe_name"

  echo -e "${GREEN}Cliente '$selected' eliminado.${NC}"
  read -rp "Presiona Enter para continuar..."
}

# Función para mostrar reportes de auditoría
show_audit_menu() {
  while true; do
    clear
    audit_options=("Generar reporte de conexiones" "Ver logs del sistema" "Análisis de actividad" "Reporte de seguridad" "Volver al menú principal")
    audit_choice=$(printf '%s\n' "${audit_options[@]}" | fzf --prompt="Auditoría: " --height 40% --border --cycle --header="Auditoría y Reportes | VPN Control v${VERSION}" --color header:italic)

    case "$audit_choice" in
      "Generar reporte de conexiones")
        clear
        generate_connections_report
        ;;
      "Ver logs del sistema")
        clear
        view_system_logs
        ;;
      "Análisis de actividad")
        clear
        activity_analysis
        ;;
      "Reporte de seguridad")
        clear
        security_report
        ;;
      "Volver al menú principal")
        break
        ;;
      *)
        echo "Opción no válida."
        sleep 2
        ;;
    esac
  done
}

# Generar reporte de conexiones
generate_connections_report() {
  echo -e "${CYAN}=== Generando reporte de conexiones ===${NC}"
  audit_connections
  
  local report_file="$AUDIT_DIR/connections_$(date +%Y%m%d).json"
  local summary_file="$AUDIT_DIR/summary_$(date +%Y%m%d).txt"
  
  # Generar resumen legible
  {
    echo "=== REPORTE DE CONEXIONES VPN ==="
    echo "Fecha: $(date '+%Y-%m-%d %H:%M:%S')"
    echo "Generado por: $(who am i 2>/dev/null | awk '{print $1}' || echo 'unknown')"
    echo ""
    echo "=== RESUMEN DE CLIENTES ==="
    
    local total=0
    local connected=0
    local never_connected=0
    
    mapfile -t clients < <(grep -E "^# CLIENT:" "$WG_CONF" | cut -d ':' -f2- | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
    
    for client_full in "${clients[@]}"; do
      total=$((total + 1))
      peer_block=$(awk "/# CLIENT: $client_full/{flag=1;next}/^$/{flag=0}flag" "$WG_CONF")
      public_key=$(echo "$peer_block" | grep "PublicKey" | cut -d '=' -f2 | xargs)
      allowed_ip=$(echo "$peer_block" | grep "AllowedIPs" | cut -d '=' -f2 | xargs)
      
      last_handshake=$(wg show "$WG_INTERFACE" latest-handshake "$public_key" 2>/dev/null || echo "0")
      
      if [[ "$last_handshake" == "0" ]]; then
        status="Nunca conectado"
        never_connected=$((never_connected + 1))
      else
        local now=$(date +%s)
        local diff=$((now - last_handshake))
        if (( diff < 300 )); then
          status="Conectado"
          connected=$((connected + 1))
        else
          status="Desconectado ($(date -d "@$last_handshake" '+%Y-%m-%d %H:%M:%S'))"
        fi
      fi
      
      printf "%-35s %-18s %s\n" "$client_full" "$allowed_ip" "$status"
    done
    
    echo ""
    echo "=== ESTADÍSTICAS ==="
    echo "Total de clientes: $total"
    echo "Conectados actualmente: $connected"
    echo "Nunca conectados: $never_connected"
    echo "Desconectados: $((total - connected - never_connected))"
    
  } > "$summary_file"
  
  echo -e "${GREEN}Reporte generado:${NC}"
  echo "  - JSON: $report_file"
  echo "  - Resumen: $summary_file"
  echo ""
  echo "=== VISTA PREVIA DEL RESUMEN ==="
  cat "$summary_file"
  
  write_log "INFO" "AUDIT_REPORT" "Reporte de conexiones generado: $report_file"
  
  read -rp "Presiona Enter para continuar..."
}

# Ver logs del sistema
view_system_logs() {
  echo -e "${CYAN}=== Logs del Sistema VPN ===${NC}"
  
  if [[ ! -f "$LOG_FILE" ]]; then
    echo -e "${YELLOW}No hay logs disponibles.${NC}"
    read -rp "Presiona Enter para continuar..."
    return
  fi
  
  echo "Últimas 50 entradas del log:"
  echo ""
  tail -50 "$LOG_FILE" | while IFS= read -r line; do
    if [[ "$line" =~ \[ERROR\] ]]; then
      echo -e "${RED}$line${NC}"
    elif [[ "$line" =~ \[WARN\] ]]; then
      echo -e "${YELLOW}$line${NC}"
    elif [[ "$line" =~ \[INFO\] ]]; then
      echo -e "${GREEN}$line${NC}"
    else
      echo "$line"
    fi
  done
  
  echo ""
  echo "Archivo de log: $LOG_FILE"
  
  read -rp "Presiona Enter para continuar..."
}

# Análisis de actividad
activity_analysis() {
  echo -e "${CYAN}=== Análisis de Actividad ===${NC}"
  
  if [[ ! -f "$LOG_FILE" ]]; then
    echo -e "${YELLOW}No hay logs disponibles para analizar.${NC}"
    read -rp "Presiona Enter para continuar..."
    return
  fi
  
  echo "Actividad de los últimos 7 días:"
  echo ""
  
  # Análisis por día
  echo "=== ACTIVIDAD POR DÍA ==="
  for i in {6..0}; do
    local date=$(date -d "$i days ago" '+%Y-%m-%d')
    local count=$(grep "$date" "$LOG_FILE" 2>/dev/null | wc -l)
    printf "%-12s: %d eventos\n" "$date" "$count"
  done
  
  echo ""
  echo "=== ACCIONES MÁS FRECUENTES ==="
  grep -o '\[Action: [^]]*\]' "$LOG_FILE" 2>/dev/null | \
    sed 's/\[Action: //; s/\]//' | \
    sort | uniq -c | sort -nr | head -10
  
  echo ""
  echo "=== USUARIOS MÁS ACTIVOS ==="
  grep -o '\[User: [^]]*\]' "$LOG_FILE" 2>/dev/null | \
    sed 's/\[User: //; s/\]//' | \
    sort | uniq -c | sort -nr | head -5
  
  read -rp "Presiona Enter para continuar..."
}

# Reporte de seguridad
security_report() {
  echo -e "${CYAN}=== Reporte de Seguridad ===${NC}"
  
  echo "=== CONEXIONES ACTIVAS ==="
  wg show "$WG_INTERFACE" | grep -E "peer:|latest handshake:|transfer:" | \
  while read -r line; do
    if [[ "$line" =~ ^peer ]]; then
      echo -e "${YELLOW}$line${NC}"
    else
      echo "  $line"
    fi
  done
  
  echo ""
  echo "=== ERRORES RECIENTES ==="
  if [[ -f "$LOG_FILE" ]]; then
    grep "\[ERROR\]" "$LOG_FILE" | tail -5 | while IFS= read -r line; do
      echo -e "${RED}$line${NC}"
    done
  fi
  
  echo ""
  echo "=== CONFIGURACIÓN DE RED ==="
  echo "Interface: $WG_INTERFACE"
  echo "Red VPN: $VPN_NETWORK.0/$VPN_CIDR"
  echo "Puerto: $(grep ListenPort "$WG_CONF" | cut -d '=' -f2 | xargs)"
  
  echo ""
  echo "=== IPs ASIGNADAS ==="
  grep "AllowedIPs" "$WG_CONF" | sed 's/AllowedIPs = //' | sort
  
  write_log "INFO" "SECURITY_REPORT" "Reporte de seguridad consultado"
  
  read -rp "Presiona Enter para continuar..."
}

main_menu() {
  write_log "INFO" "SCRIPT_START" "VPN Control iniciado"
  while true; do
    clear
    options=("Listar clientes" "Agregar cliente" "Eliminar cliente" "Auditoría y Reportes" "Salir")
    choice=$(printf '%s\n' "${options[@]}" | fzf --prompt="Selecciona una opción: " --height 40% --border --cycle --header="VPN Control v${VERSION}" --color header:italic)

    case "$choice" in
      "Listar clientes")
        clear
        write_log "INFO" "LIST_CLIENTS" "Consultando lista de clientes"
        list_clients
        ;;
      "Agregar cliente")
        clear
        add_client
        ;;
      "Eliminar cliente")
        clear
        remove_client
        ;;
      "Auditoría y Reportes")
        show_audit_menu
        ;;
      "Salir")
        write_log "INFO" "SCRIPT_END" "VPN Control finalizado"
        exit 0
        ;;
      *)
        echo "Opción no válida."
        write_log "WARN" "INVALID_OPTION" "Opción inválida seleccionada: $choice"
        sleep 2
        ;;
    esac
  done
}

main_menu

