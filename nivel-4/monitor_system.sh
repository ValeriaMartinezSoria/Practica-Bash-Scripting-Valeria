#!/bin/bash

# --- Configuración de Límites ---
CPU_LIMIT=80
RAM_LIMIT=10
DISK_LIMIT=10

# --- Configuración de Notificaciones ---
WEBHOOK_URL=""

EMAIL_TO="tu_email@gmail.com"

# --- Configuración de Logs ---
ALERT_LOG_FILE="alerts.log"
# Histórico de Métricas
METRICS_LOG_FILE="metrics_$(date '+%Y%m%d').log"

# --- Colores ---
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # Sin Color

# --- 1. Medición de Métricas ---

CPU_USAGE=$(printf "%.0f" $(mpstat 1 1 | awk '/Average:/ {print 100 - $NF}'))
RAM_USAGE=$(free -m | awk '/Mem:/ {printf "%.0f", $3 / $2 * 100}')
DISK_USAGE=$(df / | awk 'NR==2 {print $5}' | tr -d '%')

# --- Guardar Histórico de Métricas ---
CURRENT_METRICS="$(date '+%Y-%m-%d %H:%M:%S') | CPU: ${CPU_USAGE}% | RAM: ${RAM_USAGE}% | DISK: ${DISK_USAGE}%"
echo "$CURRENT_METRICS" >> "$METRICS_LOG_FILE"

# --- 2. Revisar Límites y Generar Alertas ---

ALERT_MESSAGE=""
OVER_LIMIT=0

# Revisar CPU
if [ "$CPU_USAGE" -gt "$CPU_LIMIT" ]; then
    ALERT_MESSAGE+="CPU ALTA: ${CPU_USAGE}% (Límite: ${CPU_LIMIT}%) | "
    OVER_LIMIT=1
fi

# Revisar RAM
if [ "$RAM_USAGE" -gt "$RAM_LIMIT" ]; then
    ALERT_MESSAGE+="RAM ALTA: ${RAM_USAGE}% (Límite: ${RAM_LIMIT}%) | "
    OVER_LIMIT=1
fi

# Revisar Disco
if [ "$DISK_USAGE" -gt "$DISK_LIMIT" ]; then
    ALERT_MESSAGE+="DISCO ALTO: ${DISK_USAGE}% (Límite: ${DISK_LIMIT}%)"
    OVER_LIMIT=1
fi

# --- 3. Enviar Alertas y Mostrar Estado ---

if [ $OVER_LIMIT -eq 1 ]; then
    echo -e "${RED}ALERTA: $ALERT_MESSAGE${NC}"
    
    echo "$(date '+%Y-%m-%d %H:%M:%S') - ALERTA: $ALERT_MESSAGE" >> "$ALERT_LOG_FILE"
    
    # --- 3. Enviar Notificación (Bonus/Requisito 3) ---
    
    if [ -n "$WEBHOOK_URL" ]; then
        curl -X POST -H 'Content-type: application/json' \
        --data "{\"content\":\"🚨 **ALERTA DE SERVIDOR:** $ALERT_MESSAGE\"}" \
        "$WEBHOOK_URL"
    fi
    
    if [ -n "$EMAIL_TO" ]; then
        echo "ALERTA: $ALERT_MESSAGE" | mail -s "Alerta de Servidor: Recursos Altos" "$EMAIL_TO"
    fi
    
else
    echo -e "${GREEN}OK: $CURRENT_METRICS${NC}"
fi

exit 0
