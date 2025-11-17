#!/bin/bash

# === Parámetros del script ===
ORIGEN="/var/log"
DESTINO="/backup/logs"
DIAS=7
LOG="/var/log/cleaner.log"

# === Función para registrar mensajes ===
registrar() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" | tee -a "$LOG"
}

# === Comprobación de permisos ===
if [[ $EUID -ne 0 ]]; then
    echo "Este script necesita permisos de root."
    exit 1
fi

registrar "== Inicio del limpiador de logs =="

# Crear destino si no existe
if [[ ! -d "$DESTINO" ]]; then
    registrar "Creando carpeta destino: $DESTINO"
    mkdir -p "$DESTINO" || { registrar "ERROR: No se pudo crear $DESTINO"; exit 1; }
fi

# Archivo final de backup
FECHA=$(date +"%Y%m%d_%H%M%S")
ARCHIVO="$DESTINO/backup_logs_$FECHA.tar.gz"

# Encontrar logs viejos
registrar "Buscando archivos mayores a $DIAS días..."
ARCHIVOS=$(find "$ORIGEN" -type f -name "*.log" -mtime +$DIAS)

if [[ -z "$ARCHIVOS" ]]; then
    registrar "No se encontraron logs antiguos. Saliendo."
    registrar "== Fin del limpiador =="
    exit 0
fi

registrar "Archivos encontrados:"
registrar "$ARCHIVOS"

# Comprimir
registrar "Comprimiendo en: $ARCHIVO"
tar -czf "$ARCHIVO" $ARCHIVOS

if [[ $? -ne 0 ]]; then
    registrar "ERROR al comprimir. No se eliminarán los originales."
    registrar "== Fin del limpiador =="
    exit 1
fi

# Eliminar originales
registrar "Eliminando archivos originales..."
rm -f $ARCHIVOS

registrar "Limpieza completada."
registrar "== Fin del limpiador =="

