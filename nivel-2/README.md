#  Práctica de Bash Scripting – Nivel 2  
Automatización de mantenimiento y rotación de logs.

##  Objetivo  
Automatizar la limpieza de logs antiguos mediante un script que:

- Busca archivos `.log` en `/var/log` con más de **7 días**.  
- Los comprime en **tar.gz** dentro de `/backup/logs/`.  
- Elimina los originales después de la compresión.  
- Registra todas las acciones en un archivo de log.  
- (Bonus) Se ejecuta automáticamente cada noche mediante **cron**.

##  Entorno de prueba  
Se incluye un script (`setup_logs.sh`) para generar logs falsos y simular distintos niveles de antigüedad.

##  Script principal  
El archivo `cleanup_logs.sh` realiza la búsqueda, compresión, eliminación de logs viejos y registro de todas las acciones.

## Uso  
Dar permisos:

```bash
chmod +x cleanup_logs.sh

Ejecutar:

sudo ./cleanup_logs.sh


Ver resultados:

cat /var/log/cleanup_script.log
ls -lh /backup/logs/
ls -lh /var/log/*.log

 Ejecución automática con Cron (Bonus)
1. Instalar y habilitar cronie (si es necesario):
sudo pacman -S cronie
sudo systemctl start cronie
sudo systemctl enable cronie

2. Editar el crontab de root:
sudo EDITOR=nano crontab -e

3. Añadir la tarea diaria a las 2 AM:
0 2 * * * /ruta/completa/cleanup_logs.sh

Lecciones aprendidas

Búsqueda de archivos por antigüedad usando find.

Compresión con tar.gz.

Verificación de procesos con códigos de salida.

Registro de acciones en un log propio.

Automatización con cron.
