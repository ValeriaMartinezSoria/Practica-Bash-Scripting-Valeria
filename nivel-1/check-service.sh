#!/bin/bash

# $1 es el primer parametro pasado al script
SERVICE_NAME="$1"

# Verificamos si el parametro $1 esta vacio
if [ -z "$SERVICE_NAME" ]; then
  echo "Error: No se especificó un nombre de servicio."
  echo "Uso: $0 <nombre_del_servicio>"
  exit 1
fi

TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
LOG_FILE="service_status.log"

# Verificamos si el servicio esta activo
if systemctl is-active --quiet "$SERVICE_NAME"; then
  RESULTADO="activo"
else
  RESULTADO="inactivo"
  MENSAJE_ALERTA="[$TIMESTAMP] ALERTA: El servicio $SERVICE_NAME no está activo o no existe."

  echo "[$TIMESTAMP] ALERTA: El servicio $SERVICE_NAME no está activo o no existe."

  echo "$MENSAJE_ALERTA" | mail -s "Alerta de Servicio: $SERVICE_NAME Inactivo" doriansamt@gmail.com
fi

# Usamos '>>' para AÑADIR al final del archivo en lugar de sobrescribirlo
echo "[$TIMESTAMP] Servicio: $SERVICE_NAME, Estado: $RESULTADO" >> "$LOG_FILE"

echo "Verificación completada. Resultado guardado en $LOG_FILE"
