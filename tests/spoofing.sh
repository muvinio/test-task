#!/bin/bash
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/helpers.sh"

PASSED=0
TOTAL=0
BASE_HOST="${BASE_HOST:-localhost}"
FAKE_HEADER='-H "X-Forwarded-For: 1.2.3.4"'
BLOCKED_IP="1.2.3.4"

run_test() {
    TOTAL=$((TOTAL+1))
    if test_request "$1" "$2" "$3" "$4" "$BLOCKED_IP"; then
        PASSED=$((PASSED+1))
    fi
}

echo -e "\n${MAGENTA}=== SPOOFING TESTS (защита от поддельного X-Forwarded-For) ===${NC}"

run_test "nginx1:80 + fake XFF" "http://${BASE_HOST}:80/app/" 2 "$FAKE_HEADER"
run_test "nginx2:81 + fake XFF" "http://${BASE_HOST}:81/app/" 2 "$FAKE_HEADER"
run_test "nginx3:82 + fake XFF" "http://${BASE_HOST}:82/app/" 2 "$FAKE_HEADER"

run_test "nginx1→nginx2→app + fake XFF" "http://${BASE_HOST}:80/nginx2/app/" 3 "$FAKE_HEADER"
run_test "nginx1→nginx2→nginx3→app + fake XFF" "http://${BASE_HOST}:80/nginx2/nginx3/app/" 4 "$FAKE_HEADER"

echo -e "${YELLOW}Spoofing: $PASSED/$TOTAL пройдено${NC}"
echo "SUMMARY:$PASSED:$TOTAL"