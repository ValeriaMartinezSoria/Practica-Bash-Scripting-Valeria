#!/bin/bash

# --- Configuración ---
# Directorio donde vivirá la aplicación (debe coincidir con tu config de nginx)
APP_DIR="/srv/http/clash-of-clan"
# URL del repositorio Git
REPO_URL="https://github.com/rayner-villalba-coderoad-com/clash-of-clan.git"
# Servicio a reiniciar
SERVICE_TO_RESTART="nginx"
# Archivo de log
LOG_FILE="/var/log/deploy.log"

# --- Configuración de Webhook ---
# Pega tu URL de Webhook de Slack o Discord aquí
WEBHOOK_URL=""

# --- Función de Logging ---
log_action() {
  local mensaje="$1"
  # | tee -a : Escribe en la consola Y añade al archivo de log
  echo "$(date '+%Y-%m-%d %H:%M:%S') - $mensaje" | sudo tee -a "$LOG_FILE"
}

# --- Función de Manejo de Errores ---
handle_error() {
  local mensaje_error="$1"
  log_action "ERROR: $mensaje_error"
  log_action "--- DESPLIEGUE FALLIDO ---"
  
  # Enviar notificación de error
  if [ -n "$WEBHOOK_URL" ]; then
    curl -X POST -H 'Content-type: application/json' \
    --data "{\"content\":\"🚨 **DESPLIEGUE FALLIDO:** $mensaje_error\"}" \
    "$WEBHOOK_URL"
  fi
  
  exit 1
}

# --- Verificación de Root ---
# Necesario para reiniciar systemctl y escribir en /var/log
if [ "$EUID" -ne 0 ]; then
  echo "Error: Este script debe ejecutarse como root (con sudo)."
  exit 1
fi

# --- Inicio del Despliegue ---
log_action "--- INICIO: Despliegue de $APP_DIR ---"

# --- Clonar o Actualizar ---
if [ -d "$APP_DIR" ]; then
  # El directorio existe, actualizar (pull)
  log_action "Directorio $APP_DIR encontrado. Actualizando desde Git..."
  cd "$APP_DIR" || handle_error "No se pudo entrar al directorio $APP_DIR"
  
  # Verificamos si 'git pull' falla
  git pull || handle_error "Falló 'git pull'. Abortando."
  
  log_action "Actualización 'git pull' completada."
else
  # El directorio no existe, clonar
  log_action "Directorio $APP_DIR no encontrado. Clonando repositorio..."
  
  # Verificamos si 'git clone' falla
  git clone "$REPO_URL" "$APP_DIR" || handle_error "Falló 'git clone'. Abortando."
  
  log_action "Clonación completada."
fi

# --- Reiniciar el servicio ---
log_action "Reiniciando el servicio: $SERVICE_TO_RESTART..."

# Verificamos si el reinicio falla
systemctl restart "$SERVICE_TO_RESTART" || handle_error "Falló el reinicio de $SERVICE_TO_RESTART"

log_action "Servicio reiniciado exitosamente."

# --- Fin y Notificación de Éxito ---
log_action "--- DESPLIEGUE COMPLETADO EXITOSAMENTE ---"

if [ -n "$WEBHOOK_URL" ]; then
  curl -X POST -H 'Content-type: application/json' \
  --data "{\"content\":\"✅ **Despliegue completado:** $APP_DIR actualizado y $SERVICE_TO_RESTART reiniciado.\"}" \
  "$WEBHOOK_URL"
fi

exit 0
