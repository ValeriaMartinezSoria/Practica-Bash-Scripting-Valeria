# Práctica de Bash Scripting: Nivel 3 - Despliegue Automatizado (mini-CI/CD)

Este es un ejercicio de scripting en Bash que simula un pipeline de Integración Continua y Despliegue Continuo (CI/CD) muy simple.

## 🎯 Objetivo del Ejercicio

El objetivo principal es crear un script `deploy_app.sh` que automatice el proceso de despliegue de una aplicación web cada vez que haya una actualización en su repositorio de Git.

1.  Clonar o actualizar (hacer `pull`) un repositorio específico desde GitHub.
2.  Reiniciar el servidor web (en este caso, `nginx`) para que los cambios surtan efecto.
3.  Guardar un log de todas las acciones de despliegue.
4.  **Bonus:** Agregar control de errores (abortar si `git pull` falla).
5.  **Bonus:** Enviar una notificación a Slack o Discord usando un Webhook.

## 🛠️ Configuración del Entorno

Para que este script funcione en un entorno de Arch Linux mínimo, se requirieron varios pasos de configuración.

### 1. Instalación de Dependencias

Se necesitaron tres paquetes clave: `git` (para interactuar con el repositorio), `nginx` (el servidor web) y `curl` (para enviar las notificaciones).

```bash
sudo pacman -S git nginx curl
```

### 2. Configuración de Nginx

Se configuró `nginx` para que supiera dónde encontrar los archivos de la aplicación que el script iba a clonar.

  * **Archivo de Configuración:** `/etc/nginx/nginx.conf`
  * **Directiva Clave (dentro de `server`):** Se apuntó `root` al directorio de despliegue.
    ```nginx
    server {
        listen 80;
        server_name localhost;
        
        # Apuntar a la carpeta donde clonaremos la app
        root /srv/http/clash-of-clan;
        index index.html;

        location / {
            try_files $uri $uri/ =404;
        }
    }
    ```
  * **Servicio:** Se inició y habilitó `nginx` (similar a `cronie`).
    ```bash
    sudo systemctl start nginx.service
    sudo systemctl enable nginx.service
    ```

-----

## 📜 Solución Final (`deploy_app.sh`)

Este es el script final que cumple con todos los requisitos, incluyendo el manejo de errores y las notificaciones.

> [!IMPORTANT]
> Este script **debe ejecutarse con `sudo`** porque necesita:
>
> 1.  Escribir en el directorio `/srv/http/`.
> 2.  Reiniciar el servicio `nginx` (`systemctl`).
> 3.  Escribir en el archivo de log en `/var/log/`.

```bash
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
```

## 🚀 Cómo Usar

1.  **Dar permisos de ejecución:**
    ```bash
    chmod +x deploy_app.sh
    ```
2.  **Ejecutar el script (requiere `sudo`):**
    ```bash
    sudo ./deploy_app.sh
    ```
3.  **Verificar el resultado:**
      * Revisa tu canal de Discord/Slack para ver la notificación.
      * Abre `http://localhost` en un navegador para ver la app desplegada.
      * Revisa el log de despliegue: `cat /var/log/deploy.log`.

-----

> [!WARNING]
> **Puntos Críticos y Errores Comunes**
>
> 1.  **Error de `sudo`:** El primer error fue `Error: Este script debe ejecutarse como root`. Esto se debe a que `systemctl` y la escritura en `/var/log` y `/srv/http` requieren privilegios de administrador.
> 2.  **Error de `curl: (6)`:** El error `curl: (6) Could not resolve host: https` apareció porque la variable `WEBHOOK_URL` se dejó con un valor incorrecto.
>       * **Solución:** Poner una URL de Webhook real, o dejar la variable vacía (`WEBHOOK_URL=""`) para saltar la notificación de forma segura.
> 3.  **Conflicto de Puertos:** Si `nginx` no se inicia, es probable que otro servicio (como `httpd` de Apache) ya esté usando el puerto 80.

## 💡 Lecciones Aprendidas

  * **Scripts "Idempotentes":** El script es inteligente. Sabe que si la carpeta ya existe (`if [ -d "$APP_DIR" ]`), solo debe hacer `pull`, y si no, debe hacer `clone`. Esto se llama idempotencia.
  * **Control de Errores con `||`:** El operador `||` (O) es la forma más simple y efectiva de manejar errores en Bash. La lógica es `[COMANDO_A] || [COMANDO_B_SI_FALLA]`.
  * **`handle_error` y `exit 1`:** Crear una función centralizada para manejar errores (`handle_error`) nos permite notificar, registrar el fallo y, lo más importante, abortar el script con `exit 1` para evitar que un despliegue roto continúe.
  * **Variables de Entorno y `curl`:** El uso de `curl` para enviar datos JSON a un Webhook es la base de miles de integraciones de DevOps (bots de Git, alertas, etc.).
  * **Administración de Servicios:** Reforzamos el uso de `systemctl` para `start`, `enable`, `stop` y `disable` servicios del sistema.
