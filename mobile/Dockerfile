# ── Build stage ──
FROM ghcr.io/cirruslabs/flutter:3.22.0 AS builder

WORKDIR /app

# Copy dependency definition first for caching layers
COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get

# Copy all source files and compile for Web
COPY . .
RUN flutter build web --release

# ── Production stage ──
FROM nginx:1.25-alpine

# Copy custom Nginx configuration
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Copy compiled Flutter web build from builder to Nginx html directory
COPY --from=builder /app/build/web /usr/share/nginx/html

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
