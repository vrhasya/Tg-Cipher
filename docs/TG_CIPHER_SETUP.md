# TG Cipher — setup sebelum build pertama

Status: persiapan fork, **belum ada APK yang dibuat atau login yang diuji**.

## Konfigurasi yang wajib ditentukan

1. Tetapkan identitas aplikasi final (nama, package, ikon). Jangan gunakan nama/ikon Telegram resmi untuk publikasi.
2. Di `gradle.properties` ubah `APP_PACKAGE` dari `org.telegram.messenger` menjadi package milik Anda. Untuk modul `TMessagesProj_AppStandalone`, build type `standalone` menambahkan suffix `.web`; contoh `APP_PACKAGE=com.cipher.tg01` menghasilkan `com.cipher.tg01.web`. Jangan daftarkan package Firebase yang keliru.
3. Ambil `api_id` dan `api_hash` milik Anda dari https://my.telegram.org. Jangan gunakan nilai bawaan Telegram.
4. Isi `TG_CIPHER_API_ID` dan `TG_CIPHER_API_HASH` melalui **environment variables** build atau file `local.properties` (sudah diabaikan Git). Contoh isi lokal:
   ```properties
   TG_CIPHER_API_ID=123456
   TG_CIPHER_API_HASH=0123456789abcdef0123456789abcdef
   ```
   Nilai di atas hanya contoh, **jangan gunakan untuk login**. Jangan masukkan kredensial sesungguhnya ke commit, issue, screenshot, atau chat.
5. Buat Firebase Android app untuk **package final yang benar**, unduh `google-services.json` dari project sendiri, lalu masukkan saat build. File `TMessagesProj/google-services.json` bawaan upstream sudah dilacak Git; **jangan menimpa dan meng-commit file tersebut dengan project Firebase pribadi**. Gunakan file sementara saat build/CI.
6. Buat signing keystore milik Anda. Berkas `TMessagesProj/config/release.keystore` bawaan upstream adalah dummy: **jangan terbitkan APK dengan signing dummy**. Inject keystore di mesin build/CI, tanpa commit.
7. Gunakan modul `TMessagesProj_AppStandalone` untuk satu APK mandiri:
   ```bash
   ./gradlew :TMessagesProj_AppStandalone:assembleAfatStandalone
   ```
   Harus menggunakan Android SDK 36, NDK 27.2.12479018, CMake 3.22.1 dan toolchain yang cocok. Jangan lakukan kompilasi berat di VPS production.
8. Sebelum build, jalankan `bash scripts/cipher-preflight.sh`; skrip hanya membaca konfigurasi dan memberi status, tidak mencetak API hash.
9. Uji login menggunakan metode yang **didukung Telegram untuk client pihak ketiga**, bukan dengan menyamar sebagai aplikasi resmi atau memalsukan pemeriksaan Play Integrity.

## Perubahan yang sudah dilakukan di branch bootstrap
- `BuildVars.APP_ID` dan `APP_HASH` kini membaca properti `BuildConfig` dari Gradle.
- Field `BuildConfig` tersebut membaca `TG_CIPHER_API_ID` dan `TG_CIPHER_API_HASH` dari environment atau `local.properties`.
- `SUPPORTS_PASSKEYS=false` karena upstream menyebut flag tersebut hanya untuk identitas aplikasi resmi.
- Belum mengubah package, ikon, keystore, atau konfigurasi Firebase pribadi.
