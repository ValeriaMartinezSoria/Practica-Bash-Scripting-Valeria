# Práctica de Bash Scripting: Nivel 2 - Automatización de Mantenimiento

Este es un ejercicio de scripting en Bash para automatizar tareas de mantenimiento, específicamente la rotación y compresión de logs antiguos.

## 🎯 Objetivo del Ejercicio

El objetivo principal era crear un script `cleanup_logs.sh` que cumpliera con los siguientes requisitos:

1.  Buscar en `/var/log` todos los archivos con más de **7 días** de antigüedad.
2.  Comprimirlos (`tar.gz`) y moverlos a una carpeta `/backup/logs/`.
3.  Eliminar los archivos originales *luego de confirmar* la compresión.
4.  Generar un log con las acciones realizadas.
5.  **Bonus:** Configurar este script en `cron` para que se ejecute cada noche a las 2 AM.

## 🛠️ Entorno de Prueba

Para simular el escenario, primero se pueden crear archivos de log falsos con distintas fechas.

> [!NOTE]
> **Creación de archivos de logs falsos (Ejecutar como `root`)**
>
> Estos comandos crean archivos en `/var/log` y modifican sus fechas para simular antigüedad.
> ```bash
> # Ejecuta esto como root o con sudo
> 
> # 1. Crear archivos
> cd /var/log
> touch app.log error.log access.log nginx.log system.log old_app.log old_error.log
> 
> # 2. Modificar fechas (10 días de antigüedad)
> touch -d "10 days ago" old_app.log old_error.log
> 
> # 3. Modificar fechas (2 días de antigüedad)
> touch -d "2 days ago" app.log error.log access.log
> 
> # (nginx.log y system.log quedan con la fecha de hoy)
> cd -
> ```

## 📜 Solución Final (`cleanup_logs.sh`)

Este es el script final que cumple con todos los requisitos. Debe ejecutarse como `root` porque opera en `/var/log`.

```bash
#!/bin/bash

# --- Configuración ---
SOURCE_DIR="/var/log"
BACKUP_DIR="/backup/logs"
DAYS_TO_KEEP=7
SCRIPT_LOG_FILE="/var/log/cleanup_script.log" # Log del propio script

# --- 1. Verificación de Root ---
if [ "$EUID" -ne 0 ]; then
  echo "Error: Este script debe ejecutarse como root para leer/escribir en /var/log"
  exit 1
fi

# --- Función de Logging ---
# Registra un mensaje tanto en la consola como en el archivo de log
log_action() {
  local mensaje="$1"
  # | tee -a AÑADE al log y muestra en consola
  echo "$(date '+%Y-%m-%d %H:%M:%S') - $mensaje" | tee -a "$SCRIPT_LOG_FILE"
}

# --- Inicio del Script ---
log_action "--- INICIO: Script de limpieza de logs ---"

# 2. Asegurarse de que el directorio de backup existe
mkdir -p "$BACKUP_DIR"

# 3. Generar nombre único para el archivo de backup
TIMESTAMP=$(date '+%Y%m%d_%H%M%S')
BACKUP_FILENAME="logs_antiguos_$TIMESTAMP.tar.gz"
BACKUP_FILE_PATH="$BACKUP_DIR/$BACKUP_FILENAME"

# 4. Requisito 1: Buscar archivos con más de 7 días
#    -type f: Solo archivos
#    -mtime +$DAYS_TO_KEEP: Tiempo de modificación (mtime) de MÁS de 7 días.
#    -name "*.log": Para ser específicos (evita comprimir el propio log del script si es viejo)
log_action "Buscando archivos en $SOURCE_DIR más antiguos de $DAYS_TO_KEEP días..."
FILES_TO_ARCHIVE=$(find "$SOURCE_DIR" -type f -name "*.log" -mtime +$DAYS_TO_KEEP)

if [ -z "$FILES_TO_ARCHIVE" ]; then
  log_action "No se encontraron archivos para comprimir. Saliendo."
  log_action "--- FIN: Script de limpieza de logs ---"
  exit 0
fi

log_action "Archivos encontrados para comprimir:"
log_action "$FILES_TO_ARCHIVE"

# 5. Requisito 2: Comprimir
log_action "Comprimiendo archivos en $BACKUP_FILE_PATH..."
# c = crear, z = gzip, f = archivo
tar -czf "$BACKUP_FILE_PATH" $FILES_TO_ARCHIVE

# 6. Requisito 3: Verificar compresión y Eliminar originales
#    Verificamos el código de salida ($?) del comando 'tar'. 0 = éxito.
if [ $? -eq 0 ]; then
  log_action "Compresión exitosa. Eliminando archivos originales..."
  # rm -v (verbose) para que muestre qué borra.
  # Redirigimos la salida de 'rm' al log.
  rm -v $FILES_TO_ARCHIVE >> "$SCRIPT_LOG_FILE" 2>&1
  log_action "Archivos originales eliminados."
else
  log_action "ERROR: La compresión falló. No se eliminarán los archivos originales."
  log_action "--- FIN: Script de limpieza de logs ---"
  exit 1
fi

log_action "--- FIN: Script de limpieza de logs ---"
````

## 🚀 Cómo Usar

1.  **Dar permisos de ejecución:**
    ```bash
    chmod +x cleanup_logs.sh
    ```
2.  **Ejecutar el script (requiere `sudo`):**
    ```bash
    sudo ./cleanup_logs.sh
    ```
3.  **Verificar los resultados:**
      * **Ver el log del script:**
        ```bash
        cat /var/log/cleanup_script.log
        ```
      * **Ver el archivo comprimido:**
        ```bash
        ls -lh /backup/logs/
        ```
      * **Ver que los archivos viejos desaparecieron de `/var/log`:**
        ```bash
        ls -lh /var/log/*.log
        ```

-----

## 🤯 Configuración del Cron Job

El bonus requería ejecutar el script automáticamente a las 2 AM. Esto implica configurar `cron`, que requiere instalación y manejo de editores.

> [!IMPORTANT]
> **Paso 1: Instalar y Habilitar `cronie`**
>
> Arch Linux no incluye un servicio de cron por defecto. `cronie` es el paquete estándar.
>
> ```bash
> # 1. Instalar
> sudo pacman -S cronie
> ```
> ```bash
> # 2. Iniciar y Habilitar el servicio
> sudo systemctl start cronie.service
> sudo systemctl enable cronie.service
> ```
> 
> Si no haces esto, el comando `crontab` no existirá (`command not found`).

> [!NOTE]
> **Paso 2: Editar el Crontab de `root`**
>
> Como el script necesita privilegios elevados (para leer/escribir en `/var/log`), debemos editar el crontab del usuario `root`.
>
> ```bash
> sudo crontab -e
> ```
>
> Al final del archivo, añade la línea:
>
> ```cron
> # Minuto Hora Día Mes DíaSemana COMANDO
> 0 2 * * * /ruta/absoluta/a/tu/cleanup_logs.sh
> ```

> [!WARNING]
> **Puntos Críticos de la Configuración de Cron**
>
> 1.  **`vi: command not found`:** Si al ejecutar `sudo crontab -e` recibes un error de `vi`, es porque `cron` intenta usar `vi` como editor por defecto y no lo tienes.
>       * **Solución:** Especifica `nano` (o tu editor) manualmente:
>         ```bash
>         sudo EDITOR=nano crontab -e
>         ```
> 2.  **Ruta Absoluta:** En `cron`, **NUNCA** uses rutas relativas como `./cleanup_logs.sh`. Cron no sabe en qué directorio estás. Debes usar la ruta completa (ej: `/home/doriandev/practica/nivel-2/cleanup_logs.sh`). Puedes obtenerla con el comando `readlink -f cleanup_logs.sh`.
> 3.  **Logs de Cron:** Si el script falla, `cron` usualmente envía un correo al usuario `root`. Puedes revisar los logs del sistema con `journalctl -u cronie` para ver si se ejecutó.

## 💡 Lecciones Aprendidas

  * `find`: El comando más poderoso para buscar archivos, usando `-mtime +N` (más de N días) y `-type f` (solo archivos).
  * `tar -czf`: El trío estándar para (c)rear, (z)comprimir con gzip, y (f)definir un nombre de archivo.
  * `$?`: Variable especial que guarda el código de salida (0 = éxito, \>0 = error) del último comando ejecutado. Esencial para scripts seguros.
  * `EUID`: Variable que contiene el ID del usuario. `0` es siempre `root`. `[ "$EUID" -ne 0 ]` es la forma estándar de verificar si *no* eres root.
  * `cronie`: Es el *servicio* que ejecuta las tareas. `crontab -e` es solo el *comando* para editar el archivo de configuración.
  * `EDITOR=nano`: Cómo sobrescribir el editor por defecto para un solo comando.

