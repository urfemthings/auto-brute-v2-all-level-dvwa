# DVWA Brute Force Toolkit - Universal Edition

Toolkit berbasis Bash untuk pengujian kerentanan Brute Force pada Damn Vulnerable Web Application (DVWA) di semua tingkat keamanan (Low, Medium, High). Dirancang untuk berjalan di Termux tanpa memerlukan akses root.

Toolkit ini mampu menangani proteksi CSRF Token dinamis pada setiap permintaan (request).

### Daftar File

| Nama File | Deskripsi |
| :--- | :--- |
| `inputbrutelowuni.sh` | Versi universal untuk tingkat keamanan LOW. Mendukung metode GET/POST, kustomisasi parameter, dan deteksi otomatis DVWA. |
| `inputbrutemediumuni.sh` | Versi universal untuk tingkat keamanan MEDIUM. Menangani token `user_token` pada setiap percobaan. |
| `inputbrutehighuni.sh` | Versi universal untuk tingkat keamanan HIGH. Versi paling lengkap dengan pembaruan token secara real-time pada setiap iterasi. |
| `brute_low.sh`, `inputlow.sh` | Versi sederhana untuk tingkat LOW (versi awal). |
| `inputmediumbrut.sh`, `labtestv2bruteprothigthho.sh` | Versi sederhana untuk tingkat MEDIUM dan HIGH. |
| `passlist.txt` | Daftar kata sandi (wordlist) yang digunakan untuk pengujian. |

### Fitur Unggulan

1.  **Input Interaktif Universal:** Pengguna dapat menyesuaikan Target URL, Path, Metode Request, Parameter Username, Parameter Password, dan Parameter Token secara dinamis.
2.  **Bypass CSRF Token:** Secara otomatis mengambil `user_token` baru di dalam perulangan `while read PASS`, yang merupakan syarat wajib untuk membobol level HIGH.
3.  **Manajemen Cookie (Cookie Jar):** Menggunakan file `cookie.txt` untuk menyimpan sesi login `admin:password` agar tetap valid.
4.  **Pengaturan Keamanan Otomatis:** Secara otomatis mengatur tingkat keamanan DVWA melalui endpoint `/security.php`.
5.  **Penanda Keberhasilan Kustom:** Pengguna dapat menentukan teks penanda login berhasil, dengan nilai default `Welcome to the password protected area`.

### Cara Penggunaan

```bash
chmod +x inputbrutehighuni.sh
./inputbrutehighuni.sh