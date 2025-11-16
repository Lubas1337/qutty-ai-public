#!/bin/bash

# Скрипт для создания врача через API внутри Docker контейнера

# Цвета для вывода
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Создание врача через API...${NC}"

# Выполнение curl внутри контейнера back
RESPONSE=$(docker compose exec -T back curl -s -X POST http://localhost:8872/register/ \
  -H "Content-Type: application/json" \
  -d '{
    "username": "doctor1",
    "password": "doctor123",
    "name": "Иванов Иван Иванович",
    "role": "doctor"
  }')

# Вывод ответа
echo -e "\nОтвет API:"
echo "$RESPONSE"

# Проверка успешности
if echo "$RESPONSE" | grep -q "User created successfully"; then
    echo -e "\n${GREEN}✓ Врач успешно создан через API!${NC}"

    # Попытка войти
    echo -e "\n${YELLOW}Проверка логина...${NC}"
    LOGIN_RESPONSE=$(docker compose exec -T back curl -s -X POST http://localhost:8872/login/ \
      -H "Content-Type: application/json" \
      -d '{
        "username": "doctor1",
        "password": "doctor123"
      }')

    echo "Ответ логина:"
    echo "$LOGIN_RESPONSE"

    if echo "$LOGIN_RESPONSE" | grep -q "access_token"; then
        echo -e "\n${GREEN}✓ Логин успешен!${NC}"
    fi
elif echo "$RESPONSE" | grep -q "Username already registered"; then
    echo -e "\n${YELLOW}⚠ Пользователь doctor1 уже существует${NC}"
else
    echo -e "\n${RED}✗ Ошибка при создании врача${NC}"
fi
