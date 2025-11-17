# Práctica de Bash Scripting

Este repositorio incluye **4 ejercicios de Bash** orientados a practicar tareas comunes en Linux: verificar servicios, automatizar procesos, realizar despliegues simples y monitorear recursos del sistema.

El objetivo es avanzar de lo básico a la automatización completa de pequeñas tareas útiles.

---

##  Entorno de Trabajo

Los scripts fueron probados en Linux y se utilizaron algunas herramientas como:

- `git`, `curl`, `nginx`
- `cronie` para tareas programadas
- `s-nail` para enviar correos
- `sysstat` para obtener estadísticas del sistema

También se configuraron servicios con `systemctl` y se solucionaron pequeños errores como cambiar el editor de `crontab` usando `EDITOR=nano`.

---

##  Descripción de los Niveles

### **Nivel 1 – Verificación de Servicios**
**Script:** `check_service.sh`  
Revisa si un servicio está activo y envía una notificación por correo si deja de funcionar.  
Incluye uso de parámetros, condicionales y manejo básico de `systemctl`.

---

### **Nivel 2 – Limpieza de Logs**
**Script:** `cleanup_logs.sh`  
Busca archivos antiguos, los comprime y elimina para liberar espacio.  
Se complementa con tareas programadas usando `cron`.

---

### **Nivel 3 – Despliegue Automático**
**Script:** `deploy_app.sh`  
Actualiza o clona un repositorio, reinicia `nginx` y envía un aviso mediante un webhook.  
Simula un pequeño flujo de despliegue automatizado.

---

### **Nivel 4 – Monitoreo del Sistema**
**Script:** `monitor_system.sh`  
Muestra métricas de CPU, RAM y almacenamiento, y genera alertas cuando se superan ciertos umbrales.  
Puede automatizarse con `cron` para revisiones periódicas.

---

##  Aprendizajes Clave

- Validación de parámetros y permisos.
- Manejo de servicios con `systemctl`.
- Automatización con `cron`.
- Uso de herramientas como `awk`, `tar`, `mpstat`, `df` y `free`.
- Formato de salida en terminal para mostrar mensajes claros y con colores.

