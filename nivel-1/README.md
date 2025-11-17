# Nivel 1 – Verificador de Servicios (Bash)

Script para verificar el estado de un servicio en Linux, registrar el resultado y enviar alertas por correo.

---

## Script (`check_service.sh`)

```bash
#!/bin/bash

SERVICE_NAME="$1"
LOG_FILE="service_status.log"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')
ADMIN_EMAIL="doriansant@gmail.com"

if [ -z "$SERVICE_NAME" ]; then
  echo "Uso: $0 <servicio>"
  exit 1
fi

if systemctl is-active --quiet "$SERVICE_NAME"; then
  RESULTADO="activo"
else
  RESULTADO="inactivo"
  MENSAJE="[$TIMESTAMP] ALERTA: $SERVICE_NAME inactivo."
  echo "$MENSAJE"
  echo "$MENSAJE" | mail -s "Alerta: $SERVICE_NAME" "$ADMIN_EMAIL"
fi

echo "[$TIMESTAMP] Servicio: $SERVICE_NAME, Estado: $RESULTADO" >> "$LOG_FILE"

Uso Rápido
chmod +x check_service.sh
./check_service.sh nginx
cat service_status.log

Configurar correo (Gmail + s-nail)

Instalar:

sudo pacman -S s-nail


Crear ~/.mailrc:

set v15-compat
set from="tu-email@gmail.com"
set mta=smtps://tu-email%40gmail.com:CONTRASEÑA_APP@smtp.gmail.com:465
set mta-auth=login


Permisos:

chmod 600 ~/.mailrc

# Conceptos clave:

systemctl is-active --quiet → mejor forma de verificar servicios.

Logs con >> para no sobrescribir.

Gmail requiere contraseña de aplicación.

@ se codifica como %40 en la URL SMTP.
