#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
export BASE_HOST="${BASE_HOST:-localhost}"

echo "Запуск тестового набора X-Forwarded-For (цель: $BASE_HOST)"

total_passed=0
total_tests=0

for suite in direct chain spoofing; do
    suite_script="$SCRIPT_DIR/$suite.sh"
    if [ ! -f "$suite_script" ]; then
        echo -e "\033[0;31mФайл $suite_script не найден, пропускаем\033[0m"
        continue
    fi
    chmod +x "$suite_script" 2>/dev/null
    output=$(bash "$suite_script" 2>&1)
    echo "$output"
    summary=$(echo "$output" | grep "^SUMMARY:" | tail -1)
    if [ -n "$summary" ]; then
        passed=$(echo "$summary" | cut -d':' -f2)
        tests=$(echo "$summary" | cut -d':' -f3)
        total_passed=$((total_passed + passed))
        total_tests=$((total_tests + tests))
    fi
done

echo -e "\n======================================"
if [ "$total_tests" -eq 0 ]; then
    echo -e "\033[0;31mНе было выполнено ни одного теста.\033[0m"
    exit 1
elif [ "$total_passed" -eq "$total_tests" ]; then
    echo -e "\033[0;32mИТОГО: $total_passed / $total_tests тестов пройдено\033[0m"
    exit 0
else
    echo -e "\033[0;31mИТОГО: $total_passed / $total_tests тестов пройдено\033[0m"
    exit 1
fi