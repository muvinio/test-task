# 🔄 Multi-Hop Reverse Proxy с защитой X-Forwarded-For

Тестовый стенд из трёх Nginx в режиме обратного прокси и Node.js-приложения, которое отображает заголовки `X-Forwarded-For` и `remote_addr`.

---

## 🎯 Цель проекта

- Гарантировать корректную передачу цепочки IP-адресов:
  **клиент → все промежуточные Nginx → приложение**
- Обеспечить защиту от подделки заголовка `X-Forwarded-For`
- Поддержать множественные точки входа (любой nginx может быть первым)

---

## 🧱 Архитектура


```
client
  ├─► nginx1 (80) ─────────────┐
  ├─► nginx2 (81) ─────────────┤
  └─► nginx3 (82) ─────────────┤
                               ▼
                 цепочка доверенных прокси
                 (nginx → nginx → nginx)
                               │
                               ▼
              Node.js App (порт 3000, Docker)
```


## ⚙️ Логика работы

Каждый Nginx имеет две роли:

### 🌍 Внешний вход
- Принимает запрос от клиента
- Удаляет доверие к входящему `X-Forwarded-For`
- Использует `$remote_addr` как источник истины

### 🔁 Прокси-цепочка
- Передаёт запрос дальше
- Добавляет свой IP в `X-Forwarded-For`
- Формирует доверенную цепочку

---

## 🚀 Быстрый старт

### 1. Клонировать репозиторий

git clone repo-url
cd project

2. Запустить стенд
docker-compose up -d --build

🌐 Доступные сервисы

http://localhost:80 — nginx1

http://localhost:81 — nginx2

http://localhost:82 — nginx3

## 🧪 Тестирование

▶️ Автоматические тесты
./tests/run.sh

Скрипт выполняет:

Direct тесты (3 проверки)
Chain тесты (12 проверок)
Spoofing тесты (5 проверок)

Итого: 20 тестов

При успехе:
ИТОГО: 20 / 20 тестов пройдено


## 📦 Структура проекта
```
.
├── app/
│   ├── Dockerfile
│   └── src/
│       └── app.js
│
├── nginx/
│   ├── nginx1.conf
│   ├── nginx2.conf
│   └── nginx3.conf
│
├── tests/
│   ├── run.sh
│   ├── helpers.sh
│   ├── direct.sh
│   ├── chain.sh
│   ├── spoofing.sh
│   └── README.md
│
├── docker-compose.yml
└── README.md
```

✅ Что проверяет решение

✔ Multi-hop проксирование

Запрос может проходить через 1–3 Nginx

✔ Корректная цепочка X-Forwarded-For

client → nginx1 → nginx2 → nginx3 → app

✔ Защита от спуфинга


Любой клиентский X-Forwarded-For:


IGNORED / не становится источником истины

✔ Множественные точки входа

Любой nginx может быть первым в цепочке

🖼 Пример ответа приложения

Запрос:

curl -s http://localhost/nginx2/nginx3/app/

Ответ:
```

{

      "x_forwarded_for": "172.20.0.1, 172.20.0.2, 172.20.0.3, 172.20.0.4",
  
      "remote_addr": "::ffff:172.20.0.4"
  
}
```

## 🧠 Разбор цепочки

172.20.0.1 — клиент (host gateway)

172.20.0.2 — nginx1

172.20.0.3 — nginx2

172.20.0.4 — nginx3


## 🛠 Требования

Docker

Docker Compose

curl

bash / WSL / Git Bash (для тестов)


