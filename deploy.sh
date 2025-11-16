#!/bin/bash

# Скрипт развертывания в один клик для Qutty AI
# Автор: Claude AI
# Дата: 2025-11-16

set -e

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Функции для вывода
print_success() {
    echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
    echo -e "${RED}✗ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠ $1${NC}"
}

# Проверка, что скрипт запущен с правами root
if [[ $EUID -ne 0 ]]; then
   print_error "Этот скрипт должен быть запущен с правами root (sudo)"
   exit 1
fi

echo ""
echo "=================================================="
echo "  Развертывание Qutty AI в один клик"
echo "=================================================="
echo ""

# Чтение параметров
read -p "Введите email для SSL сертификатов: " SSL_EMAIL
if [ -z "$SSL_EMAIL" ]; then
    print_error "Email не может быть пустым"
    exit 1
fi

# Проверка наличия .env файла
if [ ! -f .env ]; then
    print_warning ".env файл не найден. Используйте .env.example как шаблон."
    if [ -f .env.example ]; then
        cp .env.example .env
        print_info ".env файл создан из .env.example. Пожалуйста, отредактируйте его перед продолжением."
        exit 1
    else
        print_error "Создайте .env файл перед запуском скрипта"
        exit 1
    fi
fi

# Обновление системы
print_info "Обновление системы..."
apt-get update -qq
print_success "Система обновлена"

# Установка необходимых пакетов
print_info "Установка необходимых пакетов..."
apt-get install -y -qq \
    apt-transport-https \
    ca-certificates \
    curl \
    gnupg \
    lsb-release \
    git
print_success "Пакеты установлены"

# Установка Docker
if ! command -v docker &> /dev/null; then
    print_info "Установка Docker..."
    curl -fsSL https://get.docker.com -o get-docker.sh
    sh get-docker.sh
    rm get-docker.sh
    systemctl enable docker
    systemctl start docker
    print_success "Docker установлен"
else
    print_success "Docker уже установлен"
fi

# Установка Docker Compose
if ! command -v docker-compose &> /dev/null; then
    print_info "Установка Docker Compose..."
    curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
    print_success "Docker Compose установлен"
else
    print_success "Docker Compose уже установлен"
fi

# Создание необходимых директорий
print_info "Создание директорий..."
mkdir -p certbot/conf
mkdir -p certbot/www
print_success "Директории созданы"

# Временная nginx конфигурация для получения сертификата
print_info "Создание временной nginx конфигурации для получения SSL..."
cat > nginx/conf.d/default.conf.tmp << 'EOF'
server {
    listen 80;
    server_name ai-api.qutty.net ai.qutty.net;

    location /.well-known/acme-challenge/ {
        root /var/www/certbot;
    }

    location / {
        return 200 'OK';
        add_header Content-Type text/plain;
    }
}
EOF

# Сохранение оригинальной конфигурации
if [ -f nginx/conf.d/default.conf ]; then
    mv nginx/conf.d/default.conf nginx/conf.d/default.conf.ssl
fi
mv nginx/conf.d/default.conf.tmp nginx/conf.d/default.conf

# Запуск nginx для получения сертификата
print_info "Запуск временного nginx..."
docker-compose -f docker-compose.prod.yml up -d nginx

# Ожидание запуска nginx
sleep 5

# Получение SSL сертификатов
print_info "Получение SSL сертификатов для ai-api.qutty.net..."
docker-compose -f docker-compose.prod.yml run --rm certbot certonly \
    --webroot \
    --webroot-path /var/www/certbot \
    --email $SSL_EMAIL \
    --agree-tos \
    --no-eff-email \
    -d ai-api.qutty.net

print_info "Получение SSL сертификатов для ai.qutty.net..."
docker-compose -f docker-compose.prod.yml run --rm certbot certonly \
    --webroot \
    --webroot-path /var/www/certbot \
    --email $SSL_EMAIL \
    --agree-tos \
    --no-eff-email \
    -d ai.qutty.net

print_success "SSL сертификаты получены"

# Остановка временного nginx
print_info "Остановка временного nginx..."
docker-compose -f docker-compose.prod.yml down

# Восстановление оригинальной конфигурации
if [ -f nginx/conf.d/default.conf.ssl ]; then
    rm nginx/conf.d/default.conf
    mv nginx/conf.d/default.conf.ssl nginx/conf.d/default.conf
fi

# Сборка и запуск всех сервисов
print_info "Сборка Docker образов..."
docker-compose -f docker-compose.prod.yml build --no-cache

print_info "Запуск сервисов..."
docker-compose -f docker-compose.prod.yml up -d

print_success "Сервисы запущены"

# Ожидание запуска сервисов
print_info "Ожидание запуска сервисов (30 секунд)..."
sleep 30

# Проверка статуса сервисов
print_info "Проверка статуса сервисов..."
docker-compose -f docker-compose.prod.yml ps

echo ""
echo "=================================================="
echo "  Развертывание завершено!"
echo "=================================================="
echo ""
print_success "Фронтенд доступен по адресу: https://ai.qutty.net"
print_success "API доступен по адресу: https://ai-api.qutty.net"
echo ""
print_info "Полезные команды:"
echo "  - Просмотр логов: docker-compose -f docker-compose.prod.yml logs -f"
echo "  - Остановка: docker-compose -f docker-compose.prod.yml down"
echo "  - Перезапуск: docker-compose -f docker-compose.prod.yml restart"
echo "  - Обновление: git pull && docker-compose -f docker-compose.prod.yml up -d --build"
echo ""
print_warning "Убедитесь, что DNS записи для ai.qutty.net и ai-api.qutty.net указывают на этот сервер!"
echo ""
