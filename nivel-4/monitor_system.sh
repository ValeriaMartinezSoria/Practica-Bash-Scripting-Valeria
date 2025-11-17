#!/bin/bash

# ==========================
#   CONFIGURACIÓN GENERAL
# ==========================
CPU_MAX=80
RAM_MAX=10
DISK_MAX=10

WEBHOOK=""
EMAIL="tu_email@gmail.com"

LOG_ALERTS="alerts.log"
LOG_METRICS="metrics_$(date '+%Y%m%d').log"

# Colores
C_RED="\033[0;31m"
C_GREEN="\033[0;32m"
C_NONE="\033[0m"

# ==========================
#   CAPTURA DE MÉTRICAS
# ==========================
CPU_NOW=$(printf "%.0f" "$(mpstat 1 1 | awk '/Average:/ {print 100 - $NF}')")
RAM_NOW=$(free -m | awk '/Mem:/ {printf "%.0f", ($3/$2)*100}')
DISK_NOW=$(df / | awk 'NR==2 {gsub("%","",$5); print $5}')

TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
METRIC_LINE="$TIMESTAMP | CPU ${CPU_NOW}% | RAM ${RAM_NOW}% | DISK ${DISK_NOW}%"
echo "$METRIC_LINE" >> "$LOG_METRICS"

# ==========================
#   VERIFICACIÓN DE LÍMITES
# ==========================
ALERT=""
TRIGGER=0

check_limit() {
    local value=$1
    local max=$2
    local label=$3

    if [ "$value" -gt "$max" ]; then
        ALERT+="$label: ${value}% (Límite ${max}%) | "
        TRIGGER=1
    fi
}

check_limit "$CPU_NOW"  "$CPU_MAX"  "CPU ALTA"
check_limit "$RAM_NOW"  "$RAM_MAX"  "RAM ALTA"
check_limit "$DISK_NOW" "$DISK_MAX" "DISCO ALTO"

# ==========================
#   ACCIONES SEGÚN ESTADO
# ==========================
if [ "$TRIGGER" -eq 1 ]; then
    echo -e "${C_RED}ALERTA: $ALERT${C_NONE}"
    echo "$TIMESTAMP - ALERTA: $ALERT" >> "$LOG_ALERTS"

    # Notificación webhook
    [ -n "$WEBHOOK" ] && curl -X POST -H 'Content-Type: application/json' \
        --data "{\"content\":\" **ALERTA DE SERVIDOR:** $ALERT\"}" "$WEBHOOK"

    # Correo
    [ -n "$EMAIL" ] && echo "ALERTA: $ALERT" | mail -s " Alerta del Servidor" "$EMAIL"

else
    echo -e "${C_GREEN}OK: $METRIC_LINE${C_NONE}"
fi

exit 0

