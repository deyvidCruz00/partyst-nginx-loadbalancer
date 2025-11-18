# Usar imagen oficial de Nginx como base
FROM nginx:latest

# Remover configuración por defecto
RUN rm /etc/nginx/conf.d/default.conf

# Copiar configuración personalizada
COPY nginx.conf /etc/nginx/nginx.conf

# Crear carpeta de logs si no existe
RUN mkdir -p /var/log/nginx

# Exponer puerto (Render asigna automáticamente)
EXPOSE 10000

# Healthcheck
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:10000/health || exit 1

# Iniciar Nginx en foreground (importante para contenedores)
CMD ["nginx", "-g", "daemon off;"]
