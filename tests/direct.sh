#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/helpers.sh"

PASSED=0
TOTAL=0
BASE_HOST="${BASE_HOST:-localhost}"

run_test() {
    TOTAL=$((TOTAL+1))
    # Теперь прямой запрос через один nginx должен дать 2 IP: пользователь и этот nginx
    if test_request "$1" "$2" 2; then
        PASSED=$((PASSED+1))
    fi
}

echo -e "\n${MAGENTA}=== DIRECT TESTS (один прокси → app) ===${NC}"

run_test "nginx1:80 → app" "http://${BASE_HOST}:80/app/"
run_test "nginx2:81 → app" "http://${BASE_HOST}:81/app/"
run_test "nginx3:82 → app" "http://${BASE_HOST}:82/app/"

echo -e "${YELLOW}Direct: $PASSED/$TOTAL пройдено${NC}"
echo "SUMMARY:$PASSED:$TOTAL"