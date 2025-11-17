# Práctica de Bash Scripting para DevOps

🚀 Este repositorio documenta una serie de 4 ejercicios prácticos de Bash scripting, diseñados para simular tareas y desafíos del mundo real de un administrador de sistemas o ingeniero DevOps.

El objetivo es ir desde lo básico (verificar servicios) hasta la automatización completa (despliegue y monitoreo), resolviendo todos los problemas de un entorno de Linux por el camino.

## 🛠️ Entorno de la Práctica

Todos los scripts fueron desarrollados y probados en un entorno **Arch Linux**. Esto añadió un desafío realista y fue una parte clave del aprendizaje:

* **Instalación de Paquetes:** Fue necesario instalar `git`, `nginx`, `curl`, `cronie` (para cron), `s-nail` (para mail) y `sysstat` (para `mpstat`).
* **Configuración de Servicios:** Se configuraron servicios desde cero (`nginx.conf`, `systemctl enable cronie.service`).
* **Resolución de Conflictos:**
    * Se resolvió el error de `vi not found` en `crontab` usando `EDITOR=nano`.
---

## 📂 Resumen de los 4 Niveles

### [Nivel 1: Fundamentos y Notificaciones](./nivel-1/)

* **Script:** `check_service.sh`
* **Objetivo:** Crear un script que verifica si un servicio (`systemd`) está activo y envía una alerta por **correo electrónico** si falla.
* **Conceptos Clave:** Parámetros (`$1`), `systemctl is-active`, condicionales `if/else`, y `mail`.
* **Reto Clave:** La depuración completa de `s-nail` (`.mailrc`) para enviar correos usando el SMTP de Gmail, manejando Contraseñas de Aplicación, puertos (`:465`), protocolos (`smtps://`) y codificación de URL (`%40`).

### [Nivel 2: Tareas de Mantenimiento y Cron](./nivel-2/)

* **Script:** `cleanup_logs.sh`
* **Objetivo:** Automatizar la limpieza de logs. El script busca archivos (`find -mtime`) con más de 7 días, los comprime (`tar -czf`) y los borra de forma segura (verificando `$?`).
* **Conceptos Clave:** `find`, `tar`, `grep`, variables de `EUID` (para `root`), y `cron`.
* **Reto Clave:** Instalar `cronie` (`systemctl start/enable`) y configurar `sudo crontab -e` para ejecutar un script con privilegios de administrador.

### [Nivel 3: Despliegue Automatizado (mini-CI/CD)](./nivel-3/)

* **Script:** `deploy_app.sh`
* **Objetivo:** Simular un pipeline de CI/CD. El script es idempotente: clona (`git clone`) o actualiza (`git pull`) un repositorio, reinicia `nginx` y notifica a **Discord** con un Webhook (`curl`).
* **Conceptos Clave:** `git`, `nginx`, `curl`, funciones, y manejo de errores con `|| handle_error`.
* **Reto Clave:** Manejo de errores robusto para abortar el despliegue si falla un paso (ej. `git pull`) y configurar `nginx` (`nginx.conf`) para servir el sitio.

### [Nivel 4: Monitoreo y Alertas](./nivel-4/)

* **Script:** `monitor_system.sh`
* **Objetivo:** Crear un script de monitoreo para la terminal. Mide CPU (`mpstat`), RAM (`free`) y Disco (`df`), y genera alertas (con **colores**) si se superan los umbrales.
* **Conceptos Clave:** `mpstat`, `free`, `df`, `awk` (para cálculos), `printf`, `cron` (para usuario) y `tput`.
* **Reto Clave:** Obtener métricas de forma fiable y hacer que los colores de la terminal funcionen en `zsh` usando `tput` en lugar de los códigos de escape estándar.

---

## 💡 Lecciones Generales Aprendidas

* **Scripting Seguro:** Siempre verificar la entrada (`[ -z "$1" ]`), los permisos (`[ "$EUID" -ne 0 ]`) y el éxito de un comando (`if [ $? -eq 0 ]`).
* **Manejo de Servicios:** Uso intensivo de `systemctl` (start, enable, stop, disable) para `nginx`, `httpd` y `cronie`.
* **Procesamiento de Texto:** Uso avanzado de `awk` (para cálculos matemáticos), `grep`, `tr`, y `printf` (para formato y colores).
* **Automatización con Cron:** Configuración de `cron` tanto para `root` (tareas del sistema) como para el usuario (tareas de monitoreo).
* **Compatibilidad:** La importancia de `tput` sobre `echo -e` o `printf` con códigos hardcodeados para la compatibilidad entre terminales (`bash` vs `zsh`).
