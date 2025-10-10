# 使用多階段構建來優化最終映像大小
# 第一階段：構建 Flutter Web 應用
FROM ghcr.io/cirruslabs/flutter:stable AS build

# 設置工作目錄
WORKDIR /app

# 設置 Flutter 配置
ENV FLUTTER_ROOT=/opt/flutter
ENV PATH="$FLUTTER_ROOT/bin:$PATH"

# 複製 pubspec 文件並獲取依賴
COPY pubspec.* ./
RUN flutter pub get

# 複製源代碼
COPY . .

# 啟用 Web 支援並構建
RUN flutter config --enable-web
RUN flutter build web --release

# 第二階段：使用 nginx 來服務靜態文件
FROM nginx:alpine

# 從構建階段複製構建產物
COPY --from=build /app/build/web /usr/share/nginx/html

# 創建簡單的 nginx 配置
RUN echo 'events { worker_connections 1024; }' > /etc/nginx/nginx.conf && \
    echo 'http {' >> /etc/nginx/nginx.conf && \
    echo '  include /etc/nginx/mime.types;' >> /etc/nginx/nginx.conf && \
    echo '  default_type application/octet-stream;' >> /etc/nginx/nginx.conf && \
    echo '  gzip on;' >> /etc/nginx/nginx.conf && \
    echo '  server {' >> /etc/nginx/nginx.conf && \
    echo '    listen 8080;' >> /etc/nginx/nginx.conf && \
    echo '    root /usr/share/nginx/html;' >> /etc/nginx/nginx.conf && \
    echo '    index index.html;' >> /etc/nginx/nginx.conf && \
    echo '    location / {' >> /etc/nginx/nginx.conf && \
    echo '      try_files $uri $uri/ /index.html;' >> /etc/nginx/nginx.conf && \
    echo '    }' >> /etc/nginx/nginx.conf && \
    echo '  }' >> /etc/nginx/nginx.conf && \
    echo '}' >> /etc/nginx/nginx.conf

# 暴露端口 8080
EXPOSE 8080

# 啟動 nginx
CMD ["nginx", "-g", "daemon off;"]
