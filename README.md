# Qutty AI - Платформа для AI-диагностики

Платформа для медицинской диагностики с использованием искусственного интеллекта.

## Быстрый старт для развертывания

### Требования

- Сервер Ubuntu 20.04+
- Root доступ
- Домены ai.qutty.net и ai-api.qutty.net, указывающие на ваш сервер

### Развертывание в один клик

```bash
# Клонируйте репозиторий
git clone https://github.com/your-repo/qutty-ai-public.git
cd qutty-ai-public

# Настройте окружение
cp .env.example .env
nano .env  # Отредактируйте параметры

# Запустите скрипт развертывания
chmod +x deploy.sh
sudo ./deploy.sh
```

Скрипт автоматически:
- Установит Docker и Docker Compose
- Получит SSL сертификаты от Let's Encrypt
- Соберет и запустит все сервисы

### После развертывания

Приложение будет доступно по адресам:
- Фронтенд: https://ai.qutty.net
- API: https://ai-api.qutty.net
- API документация: https://ai-api.qutty.net/docs

### Подробная документация

Полная инструкция по развертыванию и управлению доступна в [DEPLOYMENT.md](DEPLOYMENT.md)

## Архитектура

- **Backend**: FastAPI (Python)
- **Frontend**: Next.js (React)
- **Database**: PostgreSQL
- **Reverse Proxy**: Nginx
- **SSL**: Let's Encrypt (Certbot)

## Разработка

### Локальный запуск

```bash
# Backend
pip install -r requirements.txt
uvicorn main:app --reload

# Frontend
cd frontend
npm install
npm run dev
```

### Docker Compose для разработки

```bash
docker-compose up -d
```

## Управление

```bash
# Просмотр логов
docker-compose -f docker-compose.prod.yml logs -f

# Перезапуск сервисов
docker-compose -f docker-compose.prod.yml restart

# Остановка
docker-compose -f docker-compose.prod.yml down
```

## Лицензия

Все права защищены.
