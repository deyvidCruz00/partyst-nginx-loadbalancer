# 🚀 Nginx Load Balancer para PartySTApp Backend

Este es un load balancer basado en Nginx que distribuye el tráfico entre 3 nodos del backend de PartySTApp desplegados en Render.

## 📋 Arquitectura

```
Clientes
    ↓
[Nginx Load Balancer] ← En Render (puerto 10000)
    ↓
┌───┴────┬────────┐
↓        ↓        ↓
Backend1 Backend2 Backend3
(Render) (Render) (Render)
```

## 🔧 Configuración

### 1. URLs de los Microservicios

El backend ya está configurado para usar:
- **Email Service**: `https://email-service-hkvt.onrender.com`
- **Notifications Service**: `https://notifications-service-mkdx.onrender.com`

### 2. URLs de los Nodos del Backend

Actualiza estos valores en `nginx.conf` con tus URLs reales de Render:

```nginx
upstream partyst_backend {
    least_conn;
    
    server partyst-backend-1.onrender.com:443 max_fails=3 fail_timeout=30s;
    server partyst-backend-2.onrender.com:443 max_fails=3 fail_timeout=30s;
    server partyst-backend-3.onrender.com:443 max_fails=3 fail_timeout=30s;
}
```

## 📦 Desplegar en Render

### Opción 1: Desde CLI (Recomendado)

```bash
# Navegar al directorio
cd nginx-loadbalancer

# Hacer push a tu repositorio (asegúrate de que está en el mismo repo)
git add .
git commit -m "Add Nginx load balancer"
git push origin main

# En Render Dashboard:
# 1. Click "New +" → "Web Service"
# 2. Conecta tu repositorio (GabrielUPTCHE/partyst-java-backend)
# 3. En Build Command: `ls -la` (o dejar en blanco)
# 4. En Start Command: `docker run --rm -p $PORT:10000 -v $(pwd)/nginx.conf:/etc/nginx/nginx.conf nginx`
# 5. Deploy
```

### Opción 2: Directamente en Render Dashboard

1. **New Web Service** → **Docker**
2. **Repository**: Selecciona `partyst-java-backend`
3. **Root Directory**: `nginx-loadbalancer`
4. **Build Command**: (vacío)
5. **Start Command**: `docker run --rm -p $PORT:10000 -v $(pwd)/nginx.conf:/etc/nginx/nginx.conf nginx`
6. **Environment**: Agregar `PORT=10000`

### Opción 3: Usando render.yaml

Si Render soporta docker compose:

```bash
render deploy --project-id <your-project-id> -f render.yaml
```

## 🔄 Métodos de Balanceo

El archivo `nginx.conf` usa `least_conn` por defecto, que distribuye las nuevas conexiones al servidor con menos conexiones activas.

Puedes cambiar a otros métodos:

```nginx
upstream partyst_backend {
    # Opciones:
    # round_robin      - Distribuye equitativamente (por defecto)
    # least_conn       - Menos conexiones activas (recomendado)
    # ip_hash          - Basado en IP del cliente (sticky sessions)
    # random           - Aleatorio
    # random two least_conn - Aleatorio entre dos con menos conexiones
    
    least_conn;
    
    server partyst-backend-1.onrender.com:443;
    server partyst-backend-2.onrender.com:443;
    server partyst-backend-3.onrender.com:443;
}
```

## 📊 Endpoints Disponibles

### Health Check
```bash
curl https://partyst-loadbalancer.onrender.com/health
# Respuesta: healthy
```

### Nginx Status
```bash
curl https://partyst-loadbalancer.onrender.com/nginx_status
```

### API Routes
```bash
curl https://partyst-loadbalancer.onrender.com/api/auth/login \
  -X POST \
  -H "Content-Type: application/json" \
  -d '{...}'
```

### WebSocket (si es necesario)
```javascript
const ws = new WebSocket('wss://partyst-loadbalancer.onrender.com/ws/...');
```

## ⚙️ Configuración Avanzada

### Rate Limiting

- **Rutas de Auth**: 5 req/s (burst 10)
- **API General**: 10 req/s (burst 20)

Modificar en `nginx.conf`:
```nginx
limit_req_zone $binary_remote_addr zone=auth:10m rate=5r/s;
limit_req_zone $binary_remote_addr zone=general:10m rate=10r/s;
```

### Timeouts

```nginx
proxy_connect_timeout 10s;  # Tiempo para conectar
proxy_send_timeout 30s;     # Tiempo para enviar request
proxy_read_timeout 30s;     # Tiempo para recibir response
```

### Buffering

```nginx
proxy_buffering on;
proxy_buffer_size 4k;
proxy_buffers 8 4k;
```

## 🔍 Monitoreo

### Logs en Render

```bash
# Ver logs de Nginx
render logs -n 100 --tail

# Buscar errores
render logs | grep error
```

### Health Check Local

```bash
docker build -t nginx-lb .
docker run -p 8080:10000 nginx-lb
curl http://localhost:8080/health
```

## 🚨 Troubleshooting

### Backend no responde
```
Problema: "502 Bad Gateway"
Solución: 
1. Verifica que los nodos estén corriendo: `curl https://partyst-backend-1.onrender.com/health`
2. Confirma las URLs en nginx.conf
3. Revisa los logs: `render logs`
```

### Conexiones lentas
```
Problema: Timeout en proxies
Solución:
1. Aumenta los timeouts en nginx.conf
2. Ajusta el buffer_size
3. Usa `least_conn` para balanceo óptimo
```

### SSL/TLS Errors
```
Problema: "SSL certificate problem"
Solución:
1. Asegúrate de que los backends usan HTTPS válido
2. Render proporciona SSL automáticamente
```

## 📝 Variables de Entorno

| Variable | Valor Predeterminado | Descripción |
|----------|-------------------|-------------|
| PORT | 10000 | Puerto donde escucha Nginx |
| NGINX_WORKER_PROCESSES | auto | Número de workers Nginx |
| NGINX_WORKER_CONNECTIONS | 1024 | Conexiones por worker |

## 🔐 Headers de Seguridad Incluidos

- `X-Frame-Options`: SAMEORIGIN
- `X-Content-Type-Options`: nosniff
- `X-XSS-Protection`: 1; mode=block
- `Referrer-Policy`: no-referrer-when-downgrade
- `Content-Security-Policy`: Personalizable

## 📚 Referencias

- [Nginx Upstream](https://nginx.org/en/docs/http/ngx_http_upstream_module.html)
- [Nginx Load Balancing](https://nginx.org/en/docs/http/load_balancing.html)
- [Render Documentation](https://render.com/docs)

## 💡 Tips

1. **Sticky Sessions**: Si necesitas que un usuario siempre vaya al mismo backend:
   ```nginx
   upstream partyst_backend {
       ip_hash;  # Basado en IP del cliente
       # ...
   }
   ```

2. **Blue-Green Deployment**: Puedes sacar un nodo temporalmente:
   ```nginx
   server partyst-backend-2.onrender.com:443 down;  # Temporalmente fuera
   ```

3. **Monitoreo**: Agregar New Relic o DataDog:
   ```nginx
   # En location /api/
   proxy_set_header X-Datadog-Trace-ID $request_id;
   ```

---

**Última actualización**: Noviembre 2025
**Mantenedor**: PartySTApp Team
