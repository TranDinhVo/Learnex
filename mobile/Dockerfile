# ── Build stage ──
FROM debian:stable-slim AS builder

WORKDIR /app

# Install standard system packages for Flutter build
RUN apt-get update && apt-get install -y \
    curl \
    git \
    unzip \
    xz-utils \
    zip \
    libglu1-mesa \
    && rm -rf /var/lib/apt/lists/*

# Clone specific Flutter channel (beta) with shallow history for extreme speed
RUN git clone --depth 1 https://github.com/flutter/flutter.git -b beta /opt/flutter

# Add Flutter to the path
ENV PATH="/opt/flutter/bin:/opt/flutter/bin/cache/dart-sdk/bin:${PATH}"

# Pre-cache Web build binaries
RUN flutter config --enable-web
RUN flutter precache --web

# Copy dependency definition first for layer caching
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
