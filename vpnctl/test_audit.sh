#!/bin/bash

# Script de prueba para las funciones de auditoría de vpnctl.sh
# Parte del repositorio server-scripts

echo "=== TESTING VPNCTL AUDIT FUNCTIONS ==="
echo "Version: 1.1.0"
echo "Repositorio: server-scripts/vpnctl"
echo ""

# Verificar la estructura del repositorio
echo "1. Verificando estructura del repositorio..."
if [ -f "../install.sh" ]; then
    echo "   ✅ install.sh encontrado en directorio padre"
else
    echo "   ❌ install.sh NO encontrado"
fi

if [ -f "../README.md" ]; then
    echo "   ✅ README.md del repositorio encontrado"
else
    echo "   ❌ README.md del repositorio NO encontrado"
fi

# Verificar el script principal
echo ""
echo "2. Verificando script principal..."
if [ -f "vpnctl.sh" ]; then
    echo "   ✅ vpnctl.sh encontrado"
    if [ -x "vpnctl.sh" ]; then
        echo "   ✅ vpnctl.sh es ejecutable"
    else
        echo "   ❌ vpnctl.sh NO es ejecutable"
    fi
else
    echo "   ❌ vpnctl.sh NO encontrado"
fi

# Verificar dependencias
echo ""
echo "3. Verificando dependencias..."
if command -v fzf &> /dev/null; then
    echo "   ✅ fzf está instalado"
else
    echo "   ❌ fzf NO está instalado"
fi

if command -v wg &> /dev/null; then
    echo "   ✅ WireGuard está instalado"
else
    echo "   ❌ WireGuard NO está instalado"
fi

# Verificar que los directorios de log existen (si se ha ejecutado)
echo ""
echo "4. Verificando directorios de logging..."
if [ -d "/var/log/vpnctl" ]; then
    echo "   ✅ Directorio de logs existe"
    sudo ls -la /var/log/vpnctl/
else
    echo "   ❓ Directorio de logs no existe (normal si no se ha ejecutado el script)"
fi

# Verificar configuración de WireGuard
echo ""
echo "5. Verificando configuración WireGuard..."
if [ -f "/etc/wireguard/wg0.conf" ]; then
    echo "   ✅ Configuración WireGuard encontrada"
    echo "   Clientes configurados:"
    sudo grep -c "^# CLIENT:" /etc/wireguard/wg0.conf 2>/dev/null || echo "   0 clientes"
else
    echo "   ❌ Configuración WireGuard NO encontrada"
fi

# Mostrar logs si existen
if [ -f "/var/log/vpnctl/vpnctl.log" ]; then
    echo ""
    echo "6. Contenido del log actual (últimas 5 líneas):"
    sudo tail -5 /var/log/vpnctl/vpnctl.log
fi

echo ""
# Verificar symlink global
echo ""
echo "7. Verificando comando global..."
if command -v vpnctl &> /dev/null; then
    echo "   ✅ Comando 'vpnctl' disponible globalmente"
    echo "   Ubicación: $(which vpnctl)"
else
    echo "   ❌ Comando 'vpnctl' NO disponible globalmente"
    echo "   💡 Ejecutar: sudo /opt/server-scripts/install.sh"
fi

echo ""
echo "=== TESTING COMPLETED ==="
echo "Para ejecutar el script:"
echo "  - Comando global: sudo vpnctl"
echo "  - Ruta directa: sudo ./vpnctl.sh"
