#!/bin/bash

PASS=0
FAIL=0

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

pass() {
    echo -e "${GREEN}[PASS]${NC} $1"
    PASS=$((PASS+1))
}

fail() {
    echo -e "${RED}[FAIL]${NC} $1"
    FAIL=$((FAIL+1))
}

echo "================================================="
echo " OLS cPanel Post Migration Verification v1.0"
echo "================================================="
echo

# Public IP
PUBLIC_IP=$(curl -s ifconfig.io)

if [ -n "$PUBLIC_IP" ]; then
    pass "Public IP : $PUBLIC_IP"
else
    fail "Unable to determine Public IP"
fi

# License
if /usr/local/cpanel/cpkeyclt >/dev/null 2>&1; then
    pass "cPanel License"
else
    fail "cPanel License"
fi

# Exim
systemctl is-active exim >/dev/null 2>&1
[ $? -eq 0 ] && pass "Exim" || fail "Exim"

# Dovecot
systemctl is-active dovecot >/dev/null 2>&1
[ $? -eq 0 ] && pass "Dovecot" || fail "Dovecot"

# Apache
systemctl is-active httpd >/dev/null 2>&1
[ $? -eq 0 ] && pass "Apache" || fail "Apache"

# MySQL
if ps -ef | grep -q "[m]ysqld"; then
    pass "MySQL Process"
else
    fail "MySQL Process"
fi

# cPanel Accounts
if whmapi1 listaccts >/dev/null 2>&1; then
    pass "cPanel Accounts"
else
    fail "cPanel Accounts"
fi

# Mail Queue
QUEUE=$(exim -bpc 2>/dev/null)

if [[ "$QUEUE" =~ ^[0-9]+$ ]]; then
    pass "Mail Queue : $QUEUE"
else
    fail "Mail Queue"
fi

echo
echo "================================================="
echo " SUMMARY"
echo "================================================="
echo "PASS : $PASS"
echo "FAIL : $FAIL"
echo

if [ "$FAIL" -eq 0 ]; then
    echo -e "${GREEN}GO LIVE : YES${NC}"
    exit 0
else
    echo -e "${RED}GO LIVE : NO${NC}"
    exit 1
fi
