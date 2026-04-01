# syntax=docker/dockerfile:1
FROM nginxinc/nginx-unprivileged:mainline-alpine-otel

USER root

COPY nginx/templates/default.conf.template /etc/nginx/templates/default.conf.template
COPY --chown=nginx:nginx www/ /usr/share/nginx/html/

COPY entrypoint-wrapper.sh /entrypoint-wrapper.sh
RUN chmod +x /entrypoint-wrapper.sh

USER nginx

ENV PORT=8080

ENTRYPOINT ["/entrypoint-wrapper.sh"]
CMD ["nginx", "-g", "daemon off;"]
