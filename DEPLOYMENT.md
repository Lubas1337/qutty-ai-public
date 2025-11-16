# Инструкция по развертыванию Qutty AI в один клик

Данная инструкция описывает процесс развертывания приложения Qutty AI на сервере Ubuntu с использованием Docker и автоматической настройки SSL сертификатов.

## Архитектура

Приложение состоит из следующих компонентов:

- **Backend**: FastAPI приложение (Python) - `ai-api.qutty.net`
- **Frontend**: Next.js приложение (Node.js) - `ai.qutty.net`
- **Database**: PostgreSQL
- **Reverse Proxy**: Nginx с SSL (Let's Encrypt)

## Требования

### Системные требования

- Сервер с Ubuntu 20.04 или выше
- Минимум 2GB RAM
- Минимум 20GB свободного места на диске
- Root доступ к серверу

### DNS настройки

**ВАЖНО**: Перед запуском скрипта убедитесь, что DNS записи настроены и указывают на IP адрес вашего сервера:

```
A запись: ai.qutty.net → IP_адрес_сервера
A запись: ai-api.qutty.net → IP_адрес_сервера
```

Проверить DNS можно командой:
```bash
nslookup ai.qutty.net
nslookup ai-api.qutty.net
```

## Быстрое развертывание в один клик

### Шаг 1: Клонирование репозитория

```bash
git clone https://github.com/your-repo/qutty-ai-public.git
cd qutty-ai-public
```

### Шаг 2: Настройка окружения

Создайте файл `.env` на основе `.env.example`:

```bash
cp .env.example .env
nano .env
```

Обязательно измените следующие параметры:

- `POSTGRES_PASSWORD` - безопасный пароль для базы данных
- `SECRET_KEY` - случайная строка для JWT токенов
- `API_KEY` - ваш OpenAI API ключ

### Шаг 3: Запуск скрипта развертывания

Сделайте скрипт исполняемым и запустите его:

```bash
chmod +x deploy.sh
sudo ./deploy.sh
```

Скрипт запросит ваш email для регистрации SSL сертификатов. Введите действительный email адрес.

### Что делает скрипт автоматически:

1. Обновляет систему
2. Устанавливает Docker и Docker Compose
3. Создает необходимые директории
4. Получает SSL сертификаты от Let's Encrypt
5. Собирает Docker образы
6. Запускает все сервисы

## Проверка развертывания

После завершения скрипта, проверьте работу сервисов:

```bash
# Проверка статуса контейнеров
docker-compose -f docker-compose.prod.yml ps

# Просмотр логов
docker-compose -f docker-compose.prod.yml logs -f
```

Откройте в браузере:

- Фронтенд: https://ai.qutty.net
- API: https://ai-api.qutty.net
- API документация: https://ai-api.qutty.net/docs

## Управление приложением

### Просмотр логов

```bash
# Все сервисы
docker-compose -f docker-compose.prod.yml logs -f

# Конкретный сервис
docker-compose -f docker-compose.prod.yml logs -f backend
docker-compose -f docker-compose.prod.yml logs -f frontend
docker-compose -f docker-compose.prod.yml logs -f nginx
```

### Перезапуск сервисов

```bash
# Все сервисы
docker-compose -f docker-compose.prod.yml restart

# Конкретный сервис
docker-compose -f docker-compose.prod.yml restart backend
```

### Остановка приложения

```bash
docker-compose -f docker-compose.prod.yml down
```

### Полная остановка с удалением данных

```bash
docker-compose -f docker-compose.prod.yml down -v
```

## Обновление приложения

Для обновления приложения до последней версии:

```bash
git pull
docker-compose -f docker-compose.prod.yml up -d --build
```

## Резервное копирование

### Создание резервной копии базы данных

```bash
docker-compose -f docker-compose.prod.yml exec db pg_dump -U postgres qutty_ai > backup_$(date +%Y%m%d_%H%M%S).sql
```

### Восстановление из резервной копии

```bash
docker-compose -f docker-compose.prod.yml exec -T db psql -U postgres qutty_ai < backup_20251116_120000.sql
```

## SSL сертификаты

SSL сертификаты от Let's Encrypt действительны 90 дней. Certbot контейнер автоматически обновляет их каждые 12 часов.

### Ручное обновление сертификатов

```bash
docker-compose -f docker-compose.prod.yml run --rm certbot renew
docker-compose -f docker-compose.prod.yml restart nginx
```

## Устранение неполадок

### Проверка доступности портов

```bash
# Проверка, что порты 80 и 443 открыты
sudo netstat -tulpn | grep -E ':(80|443)'
```

### Проверка firewall

Убедитесь, что порты 80 и 443 открыты в firewall:

```bash
sudo ufw allow 80/tcp
sudo ufw allow 443/tcp
sudo ufw status
```

### Проблемы с SSL

Если возникли проблемы с получением SSL сертификатов:

1. Проверьте, что DNS записи указывают на правильный IP
2. Убедитесь, что порты 80 и 443 доступны из интернета
3. Проверьте логи certbot:

```bash
docker-compose -f docker-compose.prod.yml logs certbot
```

### База данных не запускается

Проверьте логи базы данных:

```bash
docker-compose -f docker-compose.prod.yml logs db
```

Проверьте права доступа к volume:

```bash
docker volume inspect qutty-ai-public_postgres_data
```

## Дополнительная настройка

### Изменение лимита загрузки файлов

Отредактируйте `nginx/nginx.conf` и измените параметр `client_max_body_size`.

### Настройка CORS

Измените настройки CORS в `main.py` в разделе `CORSMiddleware`.

### Масштабирование

Для увеличения производительности отредактируйте количество workers в `docker-compose.prod.yml`:

```yaml
command: /bin/sh -c "alembic upgrade head && gunicorn -w 6 -k uvicorn.workers.UvicornWorker --bind 0.0.0.0:8872 main:app"
```

## Мониторинг

### Использование ресурсов

```bash
docker stats
```

### Проверка состояния сервисов

```bash
docker-compose -f docker-compose.prod.yml ps
```

## Безопасность

### Рекомендации по безопасности:

1. Регулярно обновляйте систему и Docker образы
2. Используйте сложные пароли в `.env` файле
3. Ограничьте SSH доступ
4. Настройте автоматические резервные копии
5. Мониторьте логи на предмет подозрительной активности
6. Регулярно обновляйте зависимости приложения

### Смена паролей

Для смены пароля базы данных:

1. Остановите приложение
2. Измените `POSTGRES_PASSWORD` в `.env`
3. Удалите volume с данными (ВНИМАНИЕ: это удалит все данные!)
4. Запустите приложение заново

```bash
docker-compose -f docker-compose.prod.yml down -v
# Измените .env
docker-compose -f docker-compose.prod.yml up -d
```

## Контакты и поддержка

Если у вас возникли вопросы или проблемы, создайте issue в репозитории проекта.

## Лицензия

Информацию о лицензии смотрите в файле LICENSE в корне репозитория.
