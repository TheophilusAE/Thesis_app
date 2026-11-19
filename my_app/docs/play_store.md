# Rilis ke Google Play — GPdI Persadamas

Panduan ini ditulis untuk pemilik aplikasi dan dijalankan berurutan. Kode dan file pendukung sudah siap per 19 Nov 2026. Langkah yang ditandai **(Anda)** harus dikerjakan sendiri karena memakai akun, kunci, atau kata sandi pribadi.

## Status kesiapan

| Syarat Google Play | Status |
|---|---|
| Target Android terbaru (targetSdk 36) | Siap |
| Mendukung HP dengan memori 16 KB | Siap: semua library 64-bit sejajar 16 KB, dicek di APK rilis |
| Package name tetap: `com.gpdipersadamas.app` | Siap |
| Hapus akun di aplikasi (Profil → Keamanan Akun → Hapus Akun) | Kode siap; **(Anda)** jalankan migrasi dan deploy fungsi (langkah 1) |
| Kebijakan privasi + halaman hapus akun via web | Teks siap di `docs/kebijakan_privasi.md`; **(Anda)** isi data gereja dan publikasikan (langkah 2) |
| Ditandatangani kunci upload sendiri | **(Anda)** buat kunci (langkah 3) |
| Ikon 512×512 dan feature graphic 1024×500 | Siap di `store_assets/` |
| Screenshot HP (minimal 2) | **(Anda)** ambil dari HP (langkah 6) |

## 1. Aktifkan "Hapus Akun" di server (Anda)

1. Di Supabase **SQL Editor**, jalankan query pre-flight yang ada di bagian bawah `migration_account_deletion.sql`. Kirim hasilnya bila ada baris yang muncul.
2. Jalankan `migration_account_deletion.sql`. Hasil yang diharapkan: "Success".
3. Buka **Edge Functions → Deploy a new function → Via Editor**, beri nama **`delete-account`**, lalu tempel isi `supabase/functions/delete-account/index.ts` dan klik **Deploy**. Biarkan **Verify JWT tetap AKTIF**; ini berbeda dari `send-push`.
4. Uji dengan akun dummy (misalnya `jemaat@example.com`):
   1. Login di HP, buka **Profil → Keamanan Akun → Hapus Akun**, ketik `HAPUS`, lalu konfirmasi.
   2. Pastikan akun itu hilang dari **Authentication → Users** dan dari tabel `users`.

## 2. Kebijakan privasi (Anda)

1. Buka `docs/kebijakan_privasi.md` dan ganti semua `[ISI: …]`, yaitu email resmi gereja, alamat, tanggal, dan batas hari proses.
2. Buat halaman publik, misalnya lewat Google Sites (gratis): sites.google.com → Blank → judul "Kebijakan Privasi GPdI Persadamas" → tempel teksnya → **Publish**.
3. Salin alamat halaman itu. Alamat yang sama dipakai untuk *Privacy policy* dan *Delete account URL*, karena bagian 3 halaman itu menjelaskan cara hapus akun tanpa aplikasi.

## 3. Buat kunci upload (Anda, sekali seumur aplikasi)

> **Simpan file `.jks` dan kata sandinya di dua tempat aman**, misalnya flashdisk dan Google Drive pribadi. Jangan simpan di folder proyek dan jangan dikirim ke siapa pun, termasuk ke Claude. Jika kunci hilang, Anda harus meminta reset kunci ke Google.

Di PowerShell:

```powershell
mkdir C:\kunci-gpdi
& "C:\Program Files\Java\jdk-21\bin\keytool.exe" -genkeypair -v `
  -keystore C:\kunci-gpdi\upload-keystore.jks -storetype JKS `
  -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

(`keytool` ada di JDK 21 yang sudah terpasang di PC ini.) Isi kata sandi dan data yang ditanyakan. Nama organisasi boleh diisi "GPdI Persadamas Banjarmasin".

Lalu buat file `D:\Thesis\App\my_app\android\key.properties`. File ini sudah diabaikan git, jadi aman:

```properties
storePassword=<kata sandi keystore>
keyPassword=<kata sandi key>
keyAlias=upload
storeFile=C:/kunci-gpdi/upload-keystore.jks
```

## 4. Build file untuk Play Store (Anda)

```powershell
cd D:\Thesis\App\my_app
flutter build appbundle --release
```

Hasilnya ada di `build\app\outputs\bundle\release\app-release.aab`. Tanpa `key.properties`, build tetap jalan tetapi ditandatangani kunci debug, dan Play Console akan menolaknya.

Setiap rilis berikutnya, naikkan versi di `pubspec.yaml` (misalnya `version: 1.0.1+2`). Angka setelah `+` wajib selalu naik.

## 5. Akun Play Console (Anda)

1. play.google.com/console → **Personal account** → bayar USD 25 → verifikasi identitas (KTP) dan nomor HP.
2. Akun personal baru wajib menjalankan **closed testing dengan minimal 12 tester selama 14 hari berturut-turut** sebelum boleh rilis ke publik. Siapkan 12 jemaat atau teman dengan HP Android dan alamat Gmail mereka.

## 6. Membuat aplikasi di Play Console (Anda)

**Create app.** Isi sebagai berikut:

- Nama: `GPdI Persadamas Banjarmasin`
- Bahasa default: Indonesia
- Jenis: App
- Harga: Gratis

### Store listing

**Deskripsi singkat** (maks. 80 karakter):

> Jadwal ibadah, Alkitab, event, dan kehadiran QR jemaat GPdI Persadamas.

**Deskripsi lengkap:**

> Aplikasi resmi GPdI Persadamas Banjarmasin untuk jemaat, pelayan, dan pengurus gereja.
>
> • Jadwal ibadah mingguan dan event gereja, lengkap dengan tautan siaran YouTube
> • Alkitab Terjemahan Baru yang bisa dibaca offline: pilih kitab, pasal, dan ayat, serta atur ukuran huruf
> • Renungan harian dan Quest Baca Alkitab
> • Kartu anggota dengan QR untuk kehadiran ibadah dan check-in event
> • Notifikasi jadwal pelayanan, pengumuman gereja, dan ucapan ulang tahun
> • Permintaan doa, Group (komsel), khotbah, dan feedback
> • Untuk pelayan: jadwal tugas, pengingat, dan permintaan penggantian
> • Untuk pengurus: kelola jadwal, pelayan, event, pengumuman, dan kas sesuai izin
>
> Akun baru diverifikasi oleh pengurus gereja sebelum dapat memakai fitur anggota. Tamu tetap dapat melihat jadwal ibadah, event, renungan, dan Alkitab tanpa login.

**Grafis:**

- Ikon: `store_assets/play_icon_512.png`
- Feature graphic: `store_assets/feature_graphic_1024x500.png`
- Screenshot: minimal 2, sebaiknya 4–8. Ambil di HP dari Beranda, Jadwal, Alkitab, QR Saya, dan Notifikasi. Gunakan akun dummy, bukan data jemaat asli.

### App content

**Privacy policy:** alamat dari langkah 2.

**App access:** pilih "All or some functionality is restricted", lalu berikan **akun uji khusus reviewer Google**.

- Buat akun jemaat baru dan setujui di aplikasi.
- Tulis email dan kata sandinya **hanya di Play Console**, jangan di repo.

**Ads:** No.

**Content rating:**

- Kategori: Reference, News, or Educational (atau Lifestyle).
- Jawab "Tidak" untuk kekerasan, konten seksual, dan judi.
- Jawab "Ya" untuk "user dapat berinteraksi/berbagi konten" karena ada permintaan doa dan feedback yang dilihat pengurus.

**Target audience:** 13+ (jangan pilih di bawah 13, supaya tidak masuk program Families).

**Data safety:**

| Pertanyaan | Jawaban |
|---|---|
| Mengumpulkan atau membagikan data? | Ya, mengumpulkan |
| Data dienkripsi saat dikirim? | Ya |
| Pengguna bisa meminta data dihapus? | Ya (di aplikasi dan lewat web) |
| Personal info | **Name**, **Email address**, **Phone number** (wajib); **Address**, **Other info**: NIK, tanggal baptis, tanggal lahir (opsional). Tujuan: App functionality, Account management. Tidak dibagikan. |
| App activity | **Other user-generated content**: permintaan doa dan feedback; **Other actions**: kehadiran dan pendaftaran event. Tujuan: App functionality. |
| Device or other IDs | Token notifikasi (FCM). Tujuan: App functionality (notifikasi). |
| Kamera, foto, lokasi, kontak | **Tidak** dikumpulkan. Kamera hanya memindai QR dan tidak menyimpan gambar. |
| Dibagikan ke pihak ketiga? | Tidak. Supabase dan Firebase adalah pemroses data untuk gereja, bukan "sharing". |

**Account deletion:** isi "Delete account URL" dengan alamat dari langkah 2.

## 7. Upload ke closed testing (Anda)

1. **Testing → Closed testing → Create track**, lalu buat daftar email tester (12+ Gmail).
2. **Create release → Upload** `app-release.aab`. Saat ditanya Play App Signing, pilih **Use Google-generated key** (disarankan). Kunci upload Anda tetap dipakai untuk setiap upload berikutnya.
3. Isi catatan rilis, misalnya "Rilis pertama", lalu **Review → Start rollout**.
4. Kirim link opt-in ke para tester. Mereka harus **ikut dan menginstal** selama 14 hari.
5. Setelah 14 hari, buka **Dashboard → Apply for production**, isi kuesioner, lalu tunggu review (biasanya beberapa hari).

## Setelah rilis

- Push notification, hapus akun, dan semua migrasi berjalan di server yang sama. Tidak perlu konfigurasi tambahan untuk versi Play Store.
- `google-services.json` sudah ikut di dalam build. Jangan diunggah ke repo.
- Uji ulang setiap rilis di minimal satu HP Android 15+, karena HP tersebut memeriksa dukungan 16 KB.
