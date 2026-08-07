# Dockerfile para Flutter Web - Comanda Restaurantes
# Optimizado para Railway deployment

FROM ghcr.io/cirruslabs/flutter:3.44.0 AS build

WORKDIR /app

# Copiar archivos de configuracion primero (layer caching)
COPY pubspec.yaml pubspec.lock ./

RUN flutter pub get

COPY . .

RUN flutter build web --release --base-href /

# Etapa de produccion - servidor HTTP ligero
FROM python:3.11-alpine AS runtime

RUN addgroup -g 1000 flutteruser && \
    adduser -u 1000 -G flutteruser -s /bin/sh -D flutteruser

RUN mkdir -p /app/web && chown -R flutteruser:flutteruser /app

USER flutteruser

COPY --from=build --chown=flutteruser:flutteruser /app/build/web /app/web

WORKDIR /app/web

EXPOSE 8080

CMD ["python", "-m", "http.server", "8080", "--bind", "0.0.0.0"]
