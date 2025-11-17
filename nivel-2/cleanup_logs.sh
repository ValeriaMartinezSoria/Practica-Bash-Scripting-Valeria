#!/bin/bash

# --- Configuración ---
SOURCE_DIR="/var/log"
BACKUP_DIR="/backup/logs"
DAYS_TO_KEEP=7
SCRIPT_LOG_FILE="/var/log/cleanup_script.log"

# --- Verificación de Root ---
if [ "$EUID" -ne 0 ]; then
  echo "Error: Este script debe ejecutarse como root para leer/escribir en /var/log"
  exit 1
fi

# --- Función de Logging ---
# Registra un mensaje tanto en la consola como en el archivo de log
log_action() {
  local mensaje="$1"
  echo "$(date '+%Y-%m-%d %H:%M:%S') - $mensaje" | tee -a "$SCRIPT_LOG_FILE"
}

# --- Inicio del Script ---
log_action "--- INICIO: Script de limpieza de logs ---"

# 1. Asegurarse de que el directorio de backup existe
if [ ! -d "$BACKUP_DIR" ]; then
  log_action "Directorio $BACKUP_DIR no encontrado. Creándolo..."
  mkdir -p "$BACKUP_DIR"
  if [ $? -ne 0 ]; then
    log_action "ERROR: No se pudo crear el directorio $BACKUP_DIR. Saliendo."
    exit 1
  fi
fi

# 2. Generar nombre único para el archivo de backup
TIMESTAMP=$(date '+%Y%m%d_%H%M%S')
BACKUP_FILENAME="logs_antiguos_$TIMESTAMP.tar.gz"
BACKUP_FILE_PATH="$BACKUP_DIR/$BACKUP_FILENAME"

# 3. Requisito 1: Buscar archivos con más de 7 días
# Usamos -mtime +$DAYS_TO_KEEP (más de 7 días)
# Usamos -type f (solo archivos, no directorios)
# Usamos -name "*.log" para ser específicos (opcional pero recomendado)
log_action "Buscando archivos en $SOURCE_DIR más antiguos de $DAYS_TO_KEEP días..."

# Almacenamos los archivos encontrados en una variable.
# Usar 'find ... -print0' y 'xargs -0' es la forma más segura de manejar
# archivos con espacios en sus nombres, aunque en /var/log no es común.
FILES_TO_ARCHIVE=$(find "$SOURCE_DIR" -type f -name "*.log" -mtime +$DAYS_TO_KEEP)

if [ -z "$FILES_TO_ARCHIVE" ]; then
  log_action "No se encontraron archivos para comprimir. Saliendo."
  log_action "--- FIN: Script de limpieza de logs ---"
  exit 0
fi

log_action "Archivos encontrados para comprimir:"
log_action "$FILES_TO_ARCHIVE"

# 4. Requisito 2: Comprimir y mover
log_action "Comprimiendo archivos en $BACKUP_FILE_PATH..."
# Usamos 'tar' con los archivos encontrados.
# c = crear, z = gzip, f = archivo, v = verbose (opcional)
tar -czf "$BACKUP_FILE_PATH" $FILES_TO_ARCHIVE

# 5. Requisito 3: Eliminar archivos originales (CON VERIFICACIÓN)
# Verificamos el código de salida ($?) del comando 'tar'. 0 = éxito.
if [ $? -eq 0 ]; then
  log_action "Compresión exitosa. Eliminando archivos originales..."
  # -v = verbose (muestra lo que borra), -f = forzar (ignora si no existe)
  rm -vf $FILES_TO_ARCHIVE >> "$SCRIPT_LOG_FILE" 2>&1
  log_action "Archivos originales eliminados."
else
  log_action "ERROR: La compresión falló. No se eliminarán los archivos originales."
  log_action "--- FIN: Script de limpieza de logs ---"
  exit 1
fi

log_action "--- FIN: Script de limpieza de logs ---"
