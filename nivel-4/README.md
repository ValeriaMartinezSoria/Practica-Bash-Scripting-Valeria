Monitor de Sistema en Bash (Nivel 4)

Script para medir CPU, RAM y Disco, generar alertas, enviar notificaciones y guardar un historial de métricas.

Requisitos

Instala mpstat:

sudo pacman -S sysstat

 Script monitor_system.sh
#!/bin/bash

# Límites
CPU_LIMIT=80
RAM_LIMIT=80
DISK_LIMIT=80

# Notificaciones
WEBHOOK_URL=""
EMAIL_TO="tu_email@gmail.com"

# Logs
ALERT_LOG_FILE="alerts.log"
METRICS_LOG_FILE="metrics_$(date '+%Y%m%d').log"

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

# Métricas
CPU_USAGE=$(printf "%.0f" $(mpstat 1 1 | awk '/Average:/ {print 100 - $NF}'))
RAM_USAGE=$(free -m | awk '/Mem:/ {printf "%.0f", $3/$2*100}')
DISK_USAGE=$(df / | awk 'NR==2 {print $5}' | tr -d '%')

CURRENT_METRICS="$(date '+%Y-%m-%d %H:%M:%S') | CPU: ${CPU_USAGE}% | RAM: ${RAM_USAGE}% | DISK: ${DISK_USAGE}%"
echo "$CURRENT_METRICS" >> "$METRICS_LOG_FILE"

# Alertas
ALERT_MSG=""
OVER=0

[ $CPU_USAGE -gt $CPU_LIMIT ] && ALERT_MSG+="CPU: ${CPU_USAGE}% | " && OVER=1
[ $RAM_USAGE -gt $RAM_LIMIT ] && ALERT_MSG+="RAM: ${RAM_USAGE}% | " && OVER=1
[ $DISK_USAGE -gt $DISK_LIMIT ] && ALERT_MSG+="DISK: ${DISK_USAGE}% | " && OVER=1

# Estado
if [ $OVER -eq 1 ]; then
    echo -e "${RED}ALERTA: $ALERT_MSG${NC}"
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $ALERT_MSG" >> "$ALERT_LOG_FILE"

    [ -n "$WEBHOOK_URL" ] && \
    curl -X POST -H 'Content-type: application/json' \
    --data "{\"content\":\"🚨 ALERTA: $ALERT_MSG\"}" "$WEBHOOK_URL"

    [ -n "$EMAIL_TO" ] && \
    echo "ALERTA: $ALERT_MSG" | mail -s "Alerta de Servidor" "$EMAIL_TO"
else
    echo -e "${GREEN}OK: $CURRENT_METRICS${NC}"
fi

exit 0

 Uso
chmod +x monitor_system.sh
./monitor_system.sh

Logs

alerts.log → Alertas

metrics_YYYYMMDD.log → Histórico diario

 Automatizar con cron (cada 15 minutos)
crontab -e
*/15 * * * * /ruta/absoluta/monitor_system.sh
