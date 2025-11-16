#!/bin/bash

# Скрипт для создания врача в базе данных через Docker

# Цвета для вывода
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Создание врача в базе данных...${NC}"

# SQL-запрос для создания врача
SQL_QUERY="INSERT INTO users (id, username, password, name, role)
VALUES (
    gen_random_uuid(),
    'doctor1',
    'doctor123',
    'Иванов Иван Иванович',
    'doctor'
)
RETURNING id, username, name, role;"

# Выполнение запроса через docker compose
docker compose exec -T db psql -U postgres -d postgres -c "$SQL_QUERY"

# Проверка результата
if [ $? -eq 0 ]; then
    echo -e "${GREEN}Врач успешно создан!${NC}"
else
    echo "Ошибка при создании врача"
    exit 1
fi
