#!/bin/bash

# --- Debe ejecutarse como root ---
if [ "$EUID" -ne 0 ]; then
  echo "Por favor, ejecuta este script como root (con sudo) para escribir en /var/log"
  exit 1
fi

# Directorio de logs
LOG_DIR="/var/log"

# Directorio de backup
BACKUP_DIR="/backup/logs"

echo "--- Creando directorio de backup en $BACKUP_DIR ---"
mkdir -p "$BACKUP_DIR"

echo "--- Creando archivos de log falsos en $LOG_DIR ---"

# Crear archivos
touch "$LOG_DIR/app.log"
touch "$LOG_DIR/error.log"
touch "$LOG_DIR/access.log"
touch "$LOG_DIR/nginx.log"
touch "$LOG_DIR/system.log"
touch "$LOG_DIR/old_app.log"
touch "$LOG_DIR/old_error.log"

# Añadir contenido simulado
echo "INFO - Application started successfully" > "$LOG_DIR/app.log"
echo "ERROR - Database connection failed" > "$LOG_DIR/error.log"
echo "GET /index.html 200 OK" > "$LOG_DIR/access.log"
echo "nginx: worker process started" > "$LOG_DIR/nginx.log"
echo "System check OK" > "$LOG_DIR/system.log"
echo "Old app log entry" > "$LOG_DIR/old_app.log"
echo "Old error log entry" > "$LOG_DIR/old_error.log"

# Modificar las fechas para simular antigüedad
echo "--- Simulando antigüedad de 10 días para archivos 'old_' ---"
touch -d "10 days ago" "$LOG_DIR/old_app.log" "$LOG_DIR/old_error.log"

echo "--- Simulando antigüedad de 2 días para archivos 'app', 'error', 'access' ---"
touch -d "2 days ago" "$LOG_DIR/app.log" "$LOG_DIR/error.log" "$LOG_DIR/access.log"

echo "--- Dejando 'nginx.log' y 'system.log' con fecha de hoy ---"

echo "--- Entorno de prueba creado ---"
ls -l "$LOG_DIR" | grep -E "(log$|old_)"
