# Usar imagen oficial de Nginx como base
FROM nginx:latest

# Remover configuración por defecto
RUN rm /etc/nginx/conf.d/default.conf

# Copiar configuración personalizada como template
COPY nginx.conf /etc/nginx/templates/nginx.conf.template

# Crear carpeta de logs si no existe
RUN mkdir -p /var/log/nginx

# Exponer puerto (Render asigna automáticamente)
EXPOSE 10000

# Healthcheck
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:${PORT:-10000}/health || exit 1

# Script de inicio que sustituye variables y arranca nginx
CMD ["/bin/sh", "-c", "envsubst '\\$PORT' < /etc/nginx/templates/nginx.conf.template > /etc/nginx/nginx.conf && nginx -g 'daemon off;'"]
