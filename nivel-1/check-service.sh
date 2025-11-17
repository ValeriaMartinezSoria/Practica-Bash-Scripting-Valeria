#!/bin/bash


SERVICE_NAME="$1"


if [ -z "$SERVICE_NAME" ]; then
  echo "Error: No se especificó un nombre de servicio."
  echo "Uso: $0 <nombre_del_servicio>"
  exit 1
fi

TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
LOG_FILE="service_status.log"


if systemctl is-active --quiet "$SERVICE_NAME"; then
  RESULTADO="activo"
else
  RESULTADO="inactivo"
  MENSAJE_ALERTA="[$TIMESTAMP] ALERTA: El servicio $SERVICE_NAME no está activo "

  echo "[$TIMESTAMP] ALERTA: El servicio $SERVICE_NAME no está activo"

  echo "$MENSAJE_ALERTA" | mail -s "Alerta de Servicio: $SERVICE_NAME Inactivo" valemartinezsoria@gmail.com
fi


echo "[$TIMESTAMP] Servicio: $SERVICE_NAME, Estado: $RESULTADO" >> "$LOG_FILE"

echo "Verificación completada. En $LOG_FILE"
