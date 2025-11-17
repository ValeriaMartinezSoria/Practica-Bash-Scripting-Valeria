# Práctica de Bash Scripting: Nivel 4 - Monitoreo y Alertas

Este es el ejercicio final de la serie, que combina todo lo aprendido (scripts, logs, notificaciones y automatización) para crear un script de monitoreo del sistema.

## 🎯 Objetivo del Ejercicio

El objetivo es crear un script `monitor_system.sh` que mida las métricas vitales del sistema y envíe alertas si se superan ciertos umbrales.

1.  Medir el porcentaje de uso de **CPU**, **RAM** y **Disco**.
2.  Si alguna métrica supera un límite (ej. 80%), guardar una alerta en `alerts.log`.
3.  Enviar una alerta por correo electrónico o Webhook (Discord/Slack).
4.  **Bonus:** Agregar colores a la salida (Rojo/Verde).
5.  **Bonus:** Guardar un historial diario de las métricas.

## 🛠️ Configuración y Dependencias

A diferencia de los scripts anteriores, este requería una herramienta específica para medir el CPU de forma fiable: `mpstat`.

> [!IMPORTANT]
> **Instalación de `sysstat`**
>
> El comando `mpstat` no viene instalado por defecto. Es parte del paquete `sysstat`.
> ```bash
> # Instala el paquete que provee 'mpstat'
> sudo pacman -S sysstat
> ```
> Las demás herramientas (`curl`, `mail`/`s-nail`) ya se instalaron en los niveles anteriores.

## 📜 Solución Final (`monitor_system.sh`)

Este es el script final que cumple con todos los requisitos, incluyendo los colores e historial.

```bash
#!/bin/bash

# --- Configuración de Límites ---
# Define tus umbrales de alerta (porcentaje)
CPU_LIMIT=80
RAM_LIMIT=80
DISK_LIMIT=80 # Límite para el disco raíz ("/")

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

# Obtener % de uso de CPU
# mpstat 1 1: toma 1 muestra de 1 segundo
# awk: 100 - $NF (columna %idle) = % de uso total
CPU_USAGE=$(printf "%.0f" $(mpstat 1 1 | awk '/Average:/ {print 100 - $NF}'))

# Obtener % de uso de RAM
# free -m: Muestra en Megabytes
# awk: (used / total) * 100
RAM_USAGE=$(free -m | awk '/Mem:/ {printf "%.0f", $3 / $2 * 100}')

# Obtener % de uso de Disco
# df /: Revisa solo el sistema de archivos raíz
# awk 'NR==2 {print $5}': Imprime la 5ta columna de la 2da línea
# tr -d '%': Quita el símbolo '%'
DISK_USAGE=$(df / | awk 'NR==2 {print $5}' | tr -d '%')

# --- Guardar Histórico de Métricas ---
CURRENT_METRICS="$(date '+%Y-%m-%d %H:%M:%S') | CPU: ${CPU_USAGE}% | RAM: ${RAM_USAGE}% | DISK: ${DISK_USAGE}%"
echo "$CURRENT_METRICS" >> "$METRICS_LOG_FILE"

# --- 2. Revisar Límites y Generar Alertas ---
ALERT_MESSAGE=""
OVER_LIMIT=0

if [ "$CPU_USAGE" -gt "$CPU_LIMIT" ]; then
    ALERT_MESSAGE+="CPU ALTA: ${CPU_USAGE}% (Límite: ${CPU_LIMIT}%) | "
    OVER_LIMIT=1
fi

if [ "$RAM_USAGE" -gt "$RAM_LIMIT" ]; then
    ALERT_MESSAGE+="RAM ALTA: ${RAM_USAGE}% (Límite: ${RAM_LIMIT}%) | "
    OVER_LIMIT=1
fi

if [ "$DISK_USAGE" -gt "$DISK_LIMIT" ]; then
    ALERT_MESSAGE+="DISCO ALTO: ${DISK_USAGE}% (Límite: ${DISK_LIMIT}%)"
    OVER_LIMIT=1
fi

# --- 3. Enviar Alertas y Mostrar Estado ---

if [ $OVER_LIMIT -eq 1 ]; then
    # --- Alerta (Rojo) ---
    echo -e "${RED}ALERTA: $ALERT_MESSAGE${NC}"
    
    # Guardar en el log de alertas
    echo "$(date '+%Y-%m-%d %H:%M:%S') - ALERTA: $ALERT_MESSAGE" >> "$ALERT_LOG_FILE"
    
    # --- 3. Enviar Notificación (Webhook) ---
    if [ -n "$WEBHOOK_URL" ]; then
        curl -X POST -H 'Content-type: application/json' \
        --data "{\"content\":\"🚨 **ALERTA DE SERVIDOR:** $ALERT_MESSAGE\"}" \
        "$WEBHOOK_URL"
    fi
    
    # --- 3. Enviar Notificación (Email) ---
    if [ -n "$EMAIL_TO" ]; then
        echo "ALERTA: $ALERT_MESSAGE" | mail -s "Alerta de Servidor: Recursos Altos" "$EMAIL_TO"
    fi
    
else
    # --- OK ---
    echo -e "${GREEN}OK: $CURRENT_METRICS${NC}"
fi

exit 0
````

## 🚀 Cómo Usar

1.  **Dar permisos de ejecución:**
    ```bash
    chmod +x monitor_system.sh
    ```
2.  **Configurar:**
    Edita el script (`nano monitor_system.sh`) y ajusta las variables en la parte superior (límites, URL de Webhook, y email).
3.  **Ejecutar manualmente:**
    ```bash
    ./monitor_system.sh
    ```
      * Si todo está bien, verás una línea **verde** con las métricas.
      * Si algo supera un límite, verás una línea **roja** y recibirás una notificación.
4.  **Revisar los logs:**
    ```bash
    # Ver el historial de alertas
    cat alerts.log

    # Ver el historial de métricas
    cat metrics_YYYYMMDD.log
    ```

-----

## 🤯 Configuración del Cron Job

Un script de monitoreo debe ejecutarse automáticamente. Usamos `cron` para esto.

> [!NOTE]
> **Ejecutar el script periódicamente (ej. cada 15 minutos)**
>
> A diferencia del Nivel 2, este script no necesita `sudo` (ya que `mpstat`, `free` y `df` no lo requieren), por lo que podemos usar el `crontab` de nuestro usuario normal.
>
> 1.  Abrir el crontab del usuario:
>     ```bash
>     # (Usa EDITOR=nano si 'vi' no está instalado)
>     crontab -e
>     ```
> 2.  Añadir la línea para ejecutar el script cada 15 minutos:
>     ```cron
>     # Ejecutar cada 15 minutos
>     */15 * * * * /ruta/absoluta/a/tu/monitor_system.sh
>     ```

> [!WARNING]
> **Ruta Absoluta y Logs**
>
> 1.  **Ruta Absoluta:** ¡Recuerda usar la ruta completa al script en `cron`\! (ej. `/home/doriandev/practica/nivel-4/monitor_system.sh`).
> 2.  **Archivos de Log:** Cuando `cron` ejecute el script, los archivos (`alerts.log` y `metrics_...log`) se crearán en el directorio `HOME` del usuario, **no** en el directorio del script. Para solucionarlo, puedes especificar rutas absolutas para los logs *dentro* del propio script.

## 💡 Lecciones Aprendidas

  * **Comandos de Métricas:**
      * `mpstat`: La mejor herramienta para obtener el uso de CPU (% idle).
      * `free -m`: El comando estándar para el uso de RAM.
      * `df /`: El comando para el uso de disco de un punto de montaje específico (el raíz).
  * **Procesamiento de Texto con `awk`, `printf` y `tr`:**
      * `awk '/Mem:/ {print $3 / $2 * 100}'`: `awk` puede hacer cálculos matemáticos al vuelo, esencial para calcular porcentajes de RAM.
      * `printf "%.0f"`: Se usó para redondear los decimales del CPU y RAM a números enteros, facilitando las comparaciones (`if [ "$NUM" -gt 80 ]`).
      * `tr -d '%'`: Un truco simple para eliminar caracteres no deseados (`%`) de la salida.
  * **Códigos de Escape ANSI (Colores):**
      * Definir variables como `RED='\033[0;31m'` y usarlas con `echo -e "${RED}Texto${NC}"` nos da una salida visual mucho más clara.
  * **Automatización con Cron (`*/15`):** Aprendimos la sintaxis de cron para "ejecutar cada N minutos".
