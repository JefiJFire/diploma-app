FROM nginx:1.28-alpine

# Версия приложения подставляется при сборке: --build-arg APP_VERSION=v1.0.0
ARG APP_VERSION=dev

LABEL org.opencontainers.image.title="diploma-app" \
      org.opencontainers.image.version="${APP_VERSION}"

COPY nginx/default.conf /etc/nginx/conf.d/default.conf
COPY html/ /usr/share/nginx/html/

RUN sed -i "s/__APP_VERSION__/${APP_VERSION}/g" /usr/share/nginx/html/index.html \
 && echo "${APP_VERSION}" > /usr/share/nginx/html/version.txt

EXPOSE 80

HEALTHCHECK --interval=30s --timeout=3s CMD wget -qO- http://127.0.0.1/healthz || exit 1
