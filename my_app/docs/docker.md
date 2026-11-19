# Docker

> **Status:** file-file ini ditulis pada Checkpoint 4 (19 Nov 2026), tetapi **belum pernah dijalankan**: Docker belum terpasang di PC pengembang. Jalankan sekali dan perbaiki bila perlu sebelum diandalkan.

Aplikasi mobile tidak berjalan di dalam container. Docker dipakai untuk dua hal:

1. **Lingkungan build/test yang sama di semua komputer** (`Dockerfile`, `docker-compose.yml`). Flutter 3.41.6 dan Android SDK sudah dikunci versinya, jadi hasil test dan file rilis tidak bergantung pada PC masing-masing.
2. **Supabase lokal** (Supabase CLI) untuk menguji migrasi dan RLS sebelum menyentuh database produksi.

## Prasyarat

- **Docker Desktop.** Di Windows, aktifkan backend WSL 2.
- **Supabase CLI** (untuk bagian 2). Dengan Scoop, jalankan `scoop bucket add supabase https://github.com/supabase/scoop-bucket.git`, lalu `scoop install supabase`.

## 1. Test dan build di container

Jalankan dari folder `my_app`:

```powershell
docker compose build
docker compose run --rm test          # flutter analyze + flutter test
```

Untuk membuat file rilis Play Store (`.aab`), siapkan dulu tiga file berikut. Ketiganya tidak pernah masuk ke image:

- `android/key.properties`, dengan `storeFile=/keys/upload-keystore.jks` (path di dalam container);
- folder berisi `upload-keystore.jks`;
- `android/app/google-services.json`.

Setelah itu jalankan:

```powershell
$env:KEYSTORE_DIR = "C:\kunci-gpdi"     # folder keystore Anda
docker compose run --rm release
```

Hasilnya ada di `build/app/outputs/bundle/release/app-release.aab`.

## 2. Supabase lokal untuk menguji migrasi

```powershell
cd D:\Thesis\App\my_app
supabase init            # sekali saja; membuat supabase/config.toml
supabase start           # menjalankan Postgres, Auth, dan API lokal di Docker
```

1. Buka Studio lokal (alamatnya dicetak oleh `supabase start`, biasanya http://127.0.0.1:54323).
2. Jalankan SQL dengan urutan yang sama seperti di produksi (lihat header `database_setup.sql`):
   1. `database_setup.sql`
   2. `migration_rbac_v2.sql`
   3. `migration_guest_access.sql`
   4. `rls_tests_checkpoint1.sql`
   5. migrasi Checkpoint 2–4
3. Edge Function bisa dijalankan lokal dengan `supabase functions serve send-push --env-file .env.local`. File `.env.local` berisi secrets uji dan diabaikan oleh git.
4. Matikan dengan `supabase stop`.

> Database lokal terpisah dari produksi. Data di dalamnya hanya untuk uji, jadi jangan pernah menyalin data jemaat asli ke sana.
