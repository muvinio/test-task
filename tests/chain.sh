#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/helpers.sh"

PASSED=0
TOTAL=0
BASE_HOST="${BASE_HOST:-localhost}"

run_test() {
    TOTAL=$((TOTAL+1))
    if test_request "$1" "$2" "$3"; then
        PASSED=$((PASSED+1))
    fi
}

echo -e "\n${MAGENTA}=== CHAIN TESTS (цепочки прокси) ===${NC}"

# Цепочки из двух прокси (3 IP)
run_test "nginx1→nginx2→app" "http://${BASE_HOST}:80/nginx2/app/" 3
run_test "nginx1→nginx3→app" "http://${BASE_HOST}:80/nginx3/app/" 3
run_test "nginx2→nginx1→app" "http://${BASE_HOST}:81/nginx1/app/" 3
run_test "nginx2→nginx3→app" "http://${BASE_HOST}:81/nginx3/app/" 3
run_test "nginx3→nginx1→app" "http://${BASE_HOST}:82/nginx1/app/" 3
run_test "nginx3→nginx2→app" "http://${BASE_HOST}:82/nginx2/app/" 3

# Полные цепочки (4 IP)
run_test "nginx1→nginx2→nginx3→app" "http://${BASE_HOST}:80/nginx2/nginx3/app/" 4
run_test "nginx1→nginx3→nginx2→app" "http://${BASE_HOST}:80/nginx3/nginx2/app/" 4
run_test "nginx2→nginx1→nginx3→app" "http://${BASE_HOST}:81/nginx1/nginx3/app/" 4
run_test "nginx2→nginx3→nginx1→app" "http://${BASE_HOST}:81/nginx3/nginx1/app/" 4
run_test "nginx3→nginx1→nginx2→app" "http://${BASE_HOST}:82/nginx1/nginx2/app/" 4
run_test "nginx3→nginx2→nginx1→app" "http://${BASE_HOST}:82/nginx2/nginx1/app/" 4

echo -e "${YELLOW}Chain: $PASSED/$TOTAL пройдено${NC}"
echo "SUMMARY:$PASSED:$TOTAL"
