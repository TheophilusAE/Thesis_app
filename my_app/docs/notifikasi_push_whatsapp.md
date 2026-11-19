# Notifikasi, Push (FCM) & WhatsApp

Dokumen ini menjelaskan cara kerja notifikasi aplikasi GPdI Persadamas dan cara memeliharanya.

## 1. Notifikasi di dalam aplikasi

- **Tempat penyimpanan:** setiap notifikasi adalah satu baris di `public.notifications`, yang hanya bisa dibaca pemiliknya karena dilindungi RLS.
- **Kolom tambahan dari `migration_notifications_v2.sql`:**
  - `category`: `ibadah`, `pelayanan`, `khusus`, atau `umum`.
  - `route` dan `route_params`: halaman yang dibuka saat notifikasi diketuk.
  - `broadcast_id`: pengumuman asal notifikasi tersebut.
- **Pengumuman (broadcast):** disimpan di `notification_broadcasts`.
  - Dibuat lewat RPC `create_broadcast`, yang mengirimkannya ke inbox setiap penerima.
  - Hanya Super Admin yang bisa mengubahnya (`update_broadcast`). Perubahan ikut memperbarui inbox semua penerima.
- **Penghapusan:** tidak ada penghapusan otomatis.
  - Pengguna dapat menghapus notifikasinya sendiri.
  - Super Admin dapat membersihkan notifikasi lama secara manual (`purge_old_notifications`, minimal berumur 30 hari).
- **Ucapan ulang tahun:** dikirim manual lewat tombol "Kirim ucapan hari ini" (`send_birthday_greetings`).
  - Data diambil dari `users.tanggal_lahir`.
  - Satu ucapan per orang per hari.
  - Otomatisasi akan ditambahkan setelah aplikasi stabil.

## 2. Push notification (Firebase Cloud Messaging) — AKTIF di Android

```
App (login) ──register_device_token()──▶ device_tokens
INSERT notifications ──Database Webhook "push_on_notification"──▶ Edge Function send-push
send-push ──FCM HTTP v1 (service account)──▶ HP penerima
```

- **Pendaftaran HP:** aplikasi mendaftarkan token FCM setiap kali halaman beranda dibuka (`PushService.registerFor`).
  - Satu HP terdaftar untuk satu akun, yaitu akun terakhir yang login di HP itu.
  - Saat logout, token dihapus.
- **Pengiriman:** `send-push` mengirim push ke semua HP milik penerima, lalu menghapus token yang sudah tidak berlaku.
- **Secrets Edge Function:**
  - `FIREBASE_SERVICE_ACCOUNT`: isi JSON kunci service account Firebase.
  - `PUSH_WEBHOOK_SECRET`: teks acak yang juga dipasang sebagai header `x-webhook-secret` di webhook.
- **Keamanan:**
  - Kunci Firebase **tidak pernah** ada di aplikasi maupun repo.
  - `google-services.json` di-ignore oleh git.
  - Opsi "Verify JWT" pada `send-push` dimatikan. Fungsi dilindungi oleh header rahasia.
- **iOS:** belum dikonfigurasi (belum ada APNs dan `GoogleService-Info.plist`).

**Pemecahan masalah:** buka **Edge Functions → send-push → Logs**.

| Pesan di log | Arti |
|---|---|
| `401 unauthorized` | Header webhook tidak sama dengan `PUSH_WEBHOOK_SECRET`. |
| `no device registered` | Akun penerima belum login di HP mana pun dengan aplikasi versi baru. |
| `Invalid JWT` | "Verify JWT" masih aktif. |

## 3. WhatsApp resmi (WhatsApp Cloud API) — DISIAPKAN, BELUM AKTIF

Gereja belum memiliki akun Meta Business. Karena itu, yang sudah disiapkan hanyalah arsitekturnya:

- **`migration_whatsapp_v1.sql`** (belum dijalankan):
  - Kolom opt-in `users.whatsapp_opt_in` dan `users.whatsapp_opt_in_at`.
  - Tabel log `whatsapp_messages`, yang hanya bisa dibaca pemegang izin `notifikasi:read`.
- **Edge Function `send-whatsapp`** (belum di-deploy):
  - Memeriksa JWT pemanggil dan izin `notifikasi:create`.
  - Hanya mengirim ke anggota yang opt-in dengan nomor yang valid. Nomor dengan awalan 08… diubah ke format 628….
  - Hanya mengirim **template yang sudah disetujui Meta**.
  - Setiap percobaan dicatat.
  - Selama `WHATSAPP_ENABLED` bukan `"true"`, fungsi tidak mengirim apa pun dan mengembalikan `503 { enabled: false }`.
- **Aplikasi:** belum ada tombol WhatsApp. Fitur ini tidak ditampilkan sebelum benar-benar aktif.

### Langkah aktivasi (nanti)

1. Buat dan verifikasi **Meta Business Account** (business.facebook.com).
2. Di developers.facebook.com, buat App bertipe **Business**, lalu tambahkan produk **WhatsApp**.
3. Daftarkan **nomor WhatsApp Business** gereja.
   - Gunakan nomor yang tidak dipakai di aplikasi WhatsApp biasa.
   - Catat **Phone Number ID**-nya.
4. Buat **System User** dengan izin `whatsapp_business_messaging`, lalu buat **token permanen**.
5. Ajukan **template pesan**, misalnya `pengumuman_umum` dan `pengingat_pelayanan` (bahasa `id`), dan tunggu persetujuan Meta.
6. Jalankan `migration_whatsapp_v1.sql`. Deploy `supabase/functions/send-whatsapp` dengan **Verify JWT AKTIF**.
7. Isi secrets:
   - `WHATSAPP_TOKEN`
   - `WHATSAPP_PHONE_NUMBER_ID`
   - `WHATSAPP_ENABLED=true`
8. Kumpulkan **opt-in** jemaat: persetujuan tertulis atau lewat formulir, lalu isi `whatsapp_opt_in = true`.
9. Lakukan uji kirim ke satu nomor. Setelah berhasil, buat tombol pemicu di aplikasi.

> WhatsApp **tidak boleh** diklaim aktif sebelum langkah 9 berhasil. Meta mengenakan biaya per percakapan yang dimulai bisnis. Periksa tarifnya sebelum mengirim massal.
