# Práctica de Bash Scripting: Nivel 1 - Verificador de Servicios

Este es un ejercicio de scripting en Bash para verificar el estado de un servicio en Linux (`systemd`), guardar un log y enviar alertas por correo.

## 🎯 Objetivo del Ejercicio

El objetivo principal era crear un script `check_service.sh` que cumpliera con los siguientes requisitos:

1.  Recibir el nombre de un servicio (ej. `nginx`) como parámetro.
2.  Verificar si el servicio está **activo** usando `systemctl is-active`.
3.  Si el servicio **no está activo**, mostrar un mensaje de alerta.
4.  Guardar el resultado (activo/inactivo) en un archivo `service_status.log`.
5.  **Bonus:** Agregar un *timestamp* a los logs.
6.  **Bonus:** Enviar una notificación por correo (`mail` o `sendmail`) si el servicio falla.

## 📜 Solución Final (`check_service.sh`)

Este es el script final que cumple con todos los requisitos, incluyendo los bonus.

```bash
#!/bin/bash

# --- Configuración ---
SERVICE_NAME="$1"
LOG_FILE="service_status.log"
TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S')

# Email al que se enviarán las alertas
ADMIN_EMAIL="doriansant@gmail.com"

# --- 1. Validar Entrada ---
if [ -z "$SERVICE_NAME" ]; then
  echo "Error: No se especificó un nombre de servicio."
  echo "Uso: $0 <nombre_del_servicio>"
  exit 1 # Salir con código de error
fi

# --- 2. Verificar Servicio ---
if systemctl is-active --quiet "$SERVICE_NAME"; then
  # Si está activo
  RESULTADO="activo"
else
  # Si está inactivo
  RESULTADO="inactivo"
  MENSAJE_ALERTA="[$TIMESTAMP] ALERTA: El servicio $SERVICE_NAME está inactivo o no existe."
  
  # --- 3. Alerta por Consola ---
  echo "$MENSAJE_ALERTA"
  
  # --- 6. Bonus: Alerta por Correo ---
  echo "$MENSAJE_ALERTA" | mail -s "Alerta de Servicio: $SERVICE_NAME Inactivo" "$ADMIN_EMAIL"
fi

# --- 4 & 5. Guardar en Log con Timestamp ---
echo "[$TIMESTAMP] Servicio: $SERVICE_NAME, Estado: $RESULTADO" >> "$LOG_FILE"
```

## 🚀 Cómo Usar

1.  **Dar permisos de ejecución:**
    ```bash
    chmod +x check_service.sh
    ```
2.  **Ejecutar (ejemplo con un servicio activo):**
    ```bash
    ./check_service.sh NetworkManager
    ```
3.  **Ejecutar (ejemplo con un servicio inactivo):**
    ```bash
    ./check_service.sh nginx
    ```
4.  **Revisar el log:**
    ```bash
    cat service_status.log
    ```

-----

## 🤯 Configuración del Correo

La parte más compleja fue configurar el envío de correos. El script usa el comando `mail`, pero este requiere una configuración extensa para conectarse a un SMTP externo como Gmail.

> [\!IMPORTANT]
> **Paso 1: Instalar `s-nail`**
>
> El paquete `s-nail` proporciona el comando `mail` y la capacidad de conectarse a SMTP.
>
> ```bash
> sudo pacman -S s-nail
> ```

> [\!NOTE]
> **Paso 2: El Archivo de Configuración `~/.mailrc`**
>
> `s-nail` (v14+) requiere una sintaxis de configuración moderna. Tras una larga depuración, la configuración funcional para Gmail debe crearse en `~/.mailrc`:
>
> ```ini
> # --- Configuración Moderna de s-nail (v15+) ---
> # Habilita la sintaxis de URL moderna
> set v15-compat
>
> # Tu email de "From"
> set from="tu-email@gmail.com"
>
> # El "Mail Transfer Agent" (MTA)
> # Define el servidor SMTP, usuario, contraseña y puerto
> set mta=smtps://tu-email%40gmail.com:TU\_CONTRASEÑA\_DE\_APLICACIÓN@smtp.gmail.com:465
>
> # Forzar autenticación
> set mta-auth=login
> ```

> [\!WARNING]
> **Puntos Críticos de la Configuración de Correo**
>
> 1.  **Contraseña de Aplicación:** **No** uses tu contraseña normal de Gmail. Debes generar una **"Contraseña de aplicación"** desde la configuración de seguridad de tu cuenta de Google.
> 2.  **Codificación de URL (`%40`):** El `@` en tu dirección de correo electrónico debe ser codificado como `%40` en la URL `mta`.
> 3.  **Protocolo y Puerto (`smtps://` y `465`):** Usamos `smtps://` (SMTP sobre SSL/TLS) que se conecta al puerto **465** de Gmail. El error común es usar el puerto `587` (que es para `STARTTLS` y requiere una sintaxis `smtp://` diferente).
> 4.  **Permisos:** El archivo `~/.mailrc` contiene tu contraseña. Debe tener permisos estrictos:
>     ```bash
>     chmod 600 ~/.mailrc
>     ```

## 💡 Lecciones Aprendidas

  * Uso de `$1` para capturar parámetros y `[ -z "$1" ]` para validarlos.
  * `systemctl is-active --quiet` es la forma más limpia de verificar el estado de un servicio en un script (devuelve `0` si está activo, `>0` si no).
  * Redirección `>>` para añadir (append) a un log sin borrar el contenido anterior.
  * Depuración profunda de `s-nail` para el envío de correos, resolviendo errores de:
      * Búsqueda de `sendmail` (solucionado usando `~/.mailrc`).
      * Sintaxis obsoleta (solucionado con `mta=` y `v15-compat`).
      * Codificación de URL (solucionado con `%40`).
      * Confusión de protocolo/puerto (solucionado usando `smtps://` con el puerto `465`).
