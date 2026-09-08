# Servidor web con Nginx
FROM nginx:1.27-alpine

# Eliminar la página de bienvenida por defecto
COPY nginx.conf /etc/nginx/conf.d/default.conf
COPY public/ /usr/share/nginx/html/

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]