#!/bin/bash

# === Verificación de permisos ===
if [[ $EUID -ne 0 ]]; then
    echo "Este script requiere permisos de root."
    exit 1
fi

# === Directorios ===
DIR_LOGS="/var/log"
DIR_BACKUP="/backup/logs"

echo ">> Preparando entorno de logs..."

# Crear carpeta de backup
mkdir -p "$DIR_BACKUP"
echo "✓ Carpeta de backup creada en $DIR_BACKUP"

# Crear lista de logs
LOGS=(
    "app.log"
    "error.log"
    "access.log"
    "nginx.log"
    "system.log"
    "old_app.log"
    "old_error.log"
)

echo ">> Generando archivos de log falsos..."

for archivo in "${LOGS[@]}"; do
    touch "$DIR_LOGS/$archivo"
done

# Agregar contenido de ejemplo
echo "INFO: App init" > "$DIR_LOGS/app.log"
echo "ERROR: DB connection refused" > "$DIR_LOGS/error.log"
echo "GET /home 200 OK" > "$DIR_LOGS/access.log"
echo "nginx worker online" > "$DIR_LOGS/nginx.log"
echo "System nominal" > "$DIR_LOGS/system.log"
echo "Old app entry" > "$DIR_LOGS/old_app.log"
echo "Old error entry" > "$DIR_LOGS/old_error.log"

# Fechas simuladas
echo ">> Ajustando fechas para simular antigüedad..."

# 10 días atrás → logs antiguos
touch -d "10 days ago" "$DIR_LOGS/old_app.log" "$DIR_LOGS/old_error.log"

# 2 días atrás → logs recientes
touch -d "2 days ago" "$DIR_LOGS/app.log" "$DIR_LOGS/error.log" "$DIR_LOGS/access.log"

# nginx.log y system.log → hoy

echo ">> Entorno listo. Archivos generados:"
ls -l "$DIR_LOGS" | grep -E "log$|old_"

