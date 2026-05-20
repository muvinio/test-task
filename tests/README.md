# Тестирование цепочки прокси-серверов (Multi-Hop Reverse Proxy Test Stand)

В данной директории содержатся команды для проверки корректности передачи заголовков X-Forwarded-For и защиты от подмены IP-адресов (Anti-Spoofing) в инфраструктуре из трех балансировщиков Nginx и бэкенда Node.js.

## 📌 Архитектура и ожидаемое поведение

Проект настроен на динамическую оркестрацию без жестко зашитых статических IP-адресов. Контейнеры общаются через встроенный DNS Docker по именам сервисов.

При прохождении запроса количество IP-адресов в заголовке x_forwarded_for должно строго соответствовать формуле: Количество прокси в пути + 1.

* **Прямой запрос (1 прокси):** В цепочке должно быть строго 2 IP (Клиент -> Nginx -> App).
* **Транзитный запрос (2 прокси):** В цепочке должно быть строго 3 IP (Клиент -> Nginx1 -> Nginx2 -> App).
* **Полный проход (3 прокси):** В цепочке должно быть строго 4 IP (Клиент -> Nginx1 -> Nginx2 -> Nginx3 -> App).

---

## 🚀 Сценарии тестирования

## 🤖 Автоматическое тестирование (Скрипт проверки)

Для автоматизации проверок в папке `/tests` находится Bash-скрипт `run_tests.sh`. Он последовательно имитирует все типы запросов, проверяет структуру ответов и выводит финальный статус.

### 1. Подготовка скрипта

Перед первым запуском убедитесь, что у файла есть права на исполнение.
Выполните команду на сервере:

``` chmod +x ./tests/run_tests.sh ```

## 🧪 Ручное тестирование (curl)

⚠️ Windows: используйте curl.exe, а не curl

1️⃣ Direct (один прокси → app)

curl -s http://localhost/app/

curl -s http://localhost:81/app/

curl -s http://localhost:82/app/


2️⃣ Chain (2 прокси)

curl -s http://localhost/nginx2/app/

curl -s http://localhost/nginx3/app/

curl -s http://localhost:81/nginx1/app/

curl -s http://localhost:81/nginx3/app/

curl -s http://localhost:82/nginx1/app/

curl -s http://localhost:82/nginx2/app/


3️⃣ Chain (3 прокси)

curl -s http://localhost/nginx2/nginx3/app/

curl -s http://localhost/nginx3/nginx2/app/

curl -s http://localhost:81/nginx1/nginx3/app/

curl -s http://localhost:81/nginx3/nginx1/app/

curl -s http://localhost:82/nginx1/nginx2/app/

curl -s http://localhost:82/nginx2/nginx1/app/


4️⃣ Spoofing (защита от подделки)

curl -s -H "X-Forwarded-For: 1.2.3.4" http://localhost/app/

curl -s -H "X-Forwarded-For: 1.2.3.4" http://localhost:81/app/

curl -s -H "X-Forwarded-For: 1.2.3.4" http://localhost/nginx2/nginx3/app/
