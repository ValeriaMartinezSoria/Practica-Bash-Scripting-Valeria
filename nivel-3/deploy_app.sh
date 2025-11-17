#!/bin/bash


#      CONFIGURACIÓN GENERAL

APP_PATH="/srv/http/clash-of-clan"
GIT_REPO="https://github.com/rayner-villalba-coderoad-com/clash-of-clan.git"
SERVICE_NAME="nginx"
DEPLOY_LOG="/var/log/deploy.log"

# Webhook (Slack / Discord)
WEBHOOK_URL=""


#        FUNCIONES


log() {
  local msg="$1"
  echo "$(date '+%Y-%m-%d %H:%M:%S') - $msg" | sudo tee -a "$DEPLOY_LOG"
}

notify_error() {
  local err="$1"
  log "ERROR: $err"
  log "--- DEPLOYMENT FAILED ---"

  # Enviar al webhook si existe
  [ -n "$WEBHOOK_URL" ] && \
  curl -X POST -H "Content-Type: application/json" \
       --data "{\"content\":\"🚨 **Deployment Error:** $err\"}" \
       "$WEBHOOK_URL"

  exit 1
}


#      CHECK PRIVILEGIOS

if [ "$EUID" -ne 0 ]; then
  echo "Este script debe ejecutarse como root."
  exit 1
fi


#      INICIO DEL DEPLOY

log "--- START DEPLOY: $APP_PATH ---"


#  CLONAR O ACTUALIZAR REPO

if [ -d "$APP_PATH" ]; then
  log "Directorio encontrado. Actualizando repositorio..."
  cd "$APP_PATH" || notify_error "No se puede acceder a $APP_PATH"

  git pull || notify_error "git pull falló."
  log "Actualización completada."
else
  log "Directorio no encontrado. Clonando el repositorio..."
  git clone "$GIT_REPO" "$APP_PATH" || notify_error "git clone falló."
  log "Clonación exitosa."
fi


#    REINICIAR EL SERVICIO

log "Reiniciando servicio: $SERVICE_NAME..."
systemctl restart "$SERVICE_NAME" || notify_error "El reinicio de $SERVICE_NAME falló."
log "Servicio reiniciado correctamente."


#     NOTIFICACIÓN FINAL

log "--- DEPLOY COMPLETED SUCCESSFULLY ---"

if [ -n "$WEBHOOK_URL" ]; then
  curl -X POST -H "Content-Type: application/json" \
       --data "{\"content\":\" **Deploy completado:** Proyecto actualizado y servicio $SERVICE_NAME reiniciado.\"}" \
       "$WEBHOOK_URL"
fi

exit 0

