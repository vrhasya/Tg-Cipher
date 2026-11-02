# Telecipher — build dan konfigurasi Android

## Status
- Nama: **Telecipher**
- `APP_PACKAGE=com.cipher.client01` (tanpa suffix `.web`)
- Branch: `feature/cipher-bootstrap`; **jangan merge PR sampai telah diaudit**
- Source upstream: Telegram Android 13.1.1
- **Belum ada APK hasil CI dan login belum diuji.**
- Kompilasi hanya di GitHub-hosted runner; VPS production tidak digunakan.

## Batasan autentikasi
Gunakan api_id + api_hash dari https://my.telegram.org milik pengembang sendiri.
Jangan gunakan kredensial API, keystore, OAuth, SafetyNet, atau Firebase resmi Telegram.
Tidak menjanjikan OTP via Firebase SMS pada aplikasi pihak ketiga; bila metode SMS resmi membatasi client, gunakan metode yang benar-benar didukung (mis. kode in-app/QR jika tersedia). Jangan bypass Play Integrity atau menyamarkan sertifikat.

## 1. Firebase pribadi
1. Buat Firebase project sendiri di https://console.firebase.google.com .
2. Tambah Android app **dengan package persis** `com.cipher.client01`.
3. Aktifkan Firebase Cloud Messaging (FCM) untuk notifikasi.
4. Unduh `google-services.json` dari Firebase Console untuk package tersebut.
5. File Firebase dari project Telegram upstream yang terlacak Git **jangan digunakan pada build final**.
6. Simpan file Firebase sendiri secara privat. Workflow akan memasukkan satu JSON yang sama ke dua lokasi sementara pada runner: `TMessagesProj/google-services.json` dan `TMessagesProj_AppStandalone/google-services.json`.

## 2. Signing keystore milik sendiri
Buat keystore privat dan simpan backup di lokasi aman. Contoh menggunakan JDK (boleh di Termux bila tersedia):

```bash
keytool -genkeypair -keystore "$HOME/telecipher-release.p12" -storetype PKCS12 -alias telecipher -keyalg RSA -keysize 3072 -validity 10000 -dname "CN=Telecipher, O=Telecipher, C=ID"
```

Ketika diminta, masukkan password privat yang kuat. Untuk PKCS12, gunakan password key yang sama dengan password store jika diperlukan.
Jangan gunakan `release.keystore` dummy bawaan source. JANGAN commit file .p12 atau file google-services privat.

## 3. GitHub Secrets
Repo → Settings → Secrets and variables → Actions → New repository secret.

Simpan **tujuh** secret ini, tanpa menampilkannya di Issue/PR/commit:
- `TELECIPHER_API_ID`: API ID Telegram pengembang.
- `TELECIPHER_API_HASH`: API hash 32-hex Telegram.
- `TELECIPHER_FIREBASE_JSON_B64`: hasil Base64 dari `google-services.json` privat.
- `TELECIPHER_KEYSTORE_B64`: hasil Base64 dari file .p12 privat.
- `TELECIPHER_KEY_ALIAS`: contoh `telecipher`.
- `TELECIPHER_STORE_PASSWORD`: password store.
- `TELECIPHER_KEY_PASSWORD`: password private key (sama dengan store jika PKCS12 memerlukan).

Di Termux dengan file berada pada lokasi yang diketahui:
```bash
base64 -w 0 /path/to/google-services.json
base64 -w 0 "$HOME/telecipher-release.p12"
```
Tempel keluaran Base64 ke **kolom secret GitHub**, bukan ke chat.
Jangan mencetak kredensial pada log publik.

## 4. GitHub Actions
Workflow: `.github/workflows/telecipher-build.yml`.
- Dipicu manual (`workflow_dispatch`) dengan input `confirm=BUILD_TELECIPHER`.
- Build **hanya** pada runner GitHub `ubuntu-24.04` dengan Java 17, SDK 36, NDK 27.2.12479018, CMake 3.22.1.
- Checkout submodules, validasi Firebase/keystore, build standalone, periksa APK signature dan package, upload APK artifact.
- Build command: `bash ./gradlew --no-daemon --max-workers=2 --no-parallel :TMessagesProj_AppStandalone:assembleAfatStandalone`.

**Batasan GitHub:** `workflow_dispatch` baru dapat dipicu setelah file workflow ada di **default branch**. Selama branch ini tidak di-merge ke `master`, tombol `Run workflow` belum tersedia. Jika nanti ingin menguji build, review PR lalu merge **atas keputusan pengguna**; jangan mengubah default branch hanya untuk menghindari batasan tersebut.

Workflow tidak otomatis menjalankan build pada push/PR. Terdapat batas resource runner; APK pertama belum dijamin sukses sebelum dijalankan dan log ditinjau.

## 5. Pemeriksaan lokal
```bash
bash scripts/cipher-preflight.sh
```
Hanya memvalidasi kredensial konfigurasi (tanpa mencetak isinya), package, Firebase yang cocok dan keystore bukan dummy.

## 6. Batasan branding
Nama Telecipher dan ikon awal custom sudah dipasang pada build standalone. Beberapa opsi ikon alternatif/teks branding bawaan source Telegram masih perlu audit lanjutan sebelum distribusi publik.

## Rencana setelah build pertama
1. Uji pemasangan di samping Telegram asli.
2. Uji login hanya lewat metode yang diizinkan Telegram untuk client pihak ketiga.
3. Uji persistensi sesi, notifikasi, dan deep links.
4. Baru tambahkan Gradle product flavors untuk client02, client03, dst.
