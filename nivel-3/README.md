#  Práctica Bash Scripting – Nivel 3 (Mini CI/CD)

Script que automatiza el despliegue de una aplicación web usando Git y Nginx.

##  ¿Qué hace?
- Clona o actualiza el repositorio.
- Reinicia Nginx.
- Genera un log en `/var/log/deploy.log`.
- (Opcional) Envía notificaciones via Webhook.
- Maneja errores y detiene el despliegue si algo falla.

## 📦 Requisitos
```bash
sudo pacman -S git nginx curl
Configurar Nginx para apuntar a /srv/http/clash-of-clan y habilitarlo:

bash
Copiar código
sudo systemctl start nginx
sudo systemctl enable nginx

# Uso
Dar permisos y ejecutar:

bash
Copiar código
chmod +x deploy_app.sh
sudo ./deploy_app.sh
# Verificación
App: http://localhost

Log: cat /var/log/deploy.log

Webhook: revisar canal de Slack/Discord

# Errores comunes
No usar sudo

Webhook inválido

Puerto 80 ocupado

# Puntos clave
Script idempotente (clone/pull inteligente)

Manejo de errores con || y función handle_error

Reinicio de servicios con systemctl
