#!/bin/bash

# Мягкие цвета
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[0;33m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

if ! command -v curl &> /dev/null; then
    echo -e "${RED}Ошибка: curl не найден.${NC}"
    exit 1
fi

test_request() {
    local description="$1"
    local url="$2"
    local expected_count="$3"
    local curl_opts="$4"
    local blocked_ip="$5"

    printf "${BLUE}[TEST] %s${NC}\n" "$description"

    local response
    response=$(curl -s $curl_opts "$url" 2>/dev/null)

    if [ -z "$response" ]; then
        printf "${RED}  FAIL: пустой ответ или ошибка соединения${NC}\n"
        return 1
    fi

    local xff
    xff=$(echo "$response" | grep -o '"x_forwarded_for"[[:space:]]*:[[:space:]]*"[^"]*"' | head -1 | sed 's/.*: *"//;s/"$//')

    if [ -z "$xff" ] && [ "$expected_count" -ne 0 ]; then
        printf "${RED}  FAIL: поле x_forwarded_for не найдено в ответе${NC}\n"
        return 1
    fi

    if [ "$xff" = "null" ]; then
        if [ "$expected_count" -eq 0 ]; then
            printf "${GREEN}  PASS: поле отсутствует (null) как и ожидалось${NC}\n"
            return 0
        else
            printf "${RED}  FAIL: поле x_forwarded_for == null, ожидалось $expected_count IP${NC}\n"
            return 1
        fi
    fi

    local ip_count
    ip_count=$(echo "$xff" | awk -F',' '{for(i=1;i<=NF;i++){gsub(/^[ \t]+|[ \t]+$/, "", $i); if(length($i)>0) count++} print count}')

    if [ "$ip_count" -ne "$expected_count" ]; then
        printf "${RED}  FAIL: ожидалось $expected_count IP, получено $ip_count (цепочка: $xff)${NC}\n"
        return 1
    fi

    if [ -n "$blocked_ip" ] && echo "$xff" | grep -qF "$blocked_ip"; then
        printf "${RED}  FAIL: найден запрещённый IP '$blocked_ip' в цепочке${NC}\n"
        return 1
    fi

    printf "${GREEN}  PASS: $xff${NC}\n"
    return 0
}