# Panduan Sistem Multi-Role - Aplikasi Gereja

## Daftar Isi
1. [Pengenalan Sistem](#pengenalan-sistem)
2. [Peran dan Izin](#peran-dan-izin)
3. [Panduan Pengguna](#panduan-pengguna)
4. [Panduan Admin](#panduan-admin)
5. [Sistem Substitusi Pelayan](#sistem-substitusi-pelayan)
6. [Sistem Konfirmasi Kehadiran](#sistem-konfirmasi-kehadiran)
7. [Pemindahan Peran](#pemindahan-peran)

---

## Pengenalan Sistem

Aplikasi Gereja mendukung sistem multi-role yang fleksibel. Pengguna dapat memiliki lebih dari satu peran sekaligus (contoh: Jemaat dan Pelayan), dan dapat beralih antara peran untuk mengakses fitur yang berbeda.

### Tiga Peran Utama
- **👥 Jemaat** - Anggota jemaat biasa
- **🙏 Pelayan** - Staf pelayanan/penatalayan
- **👨‍💼 Admin** - Administrator sistem

---

## Peran dan Izin

### Jemaat (Anggota Gereja)
| Fitur | Akses |
|------|-------|
| Membaca Alkitab | ✅ |
| Membaca Renungan Harian | ✅ |
| Mengikuti Reading Quest | ✅ |
| Melihat Profil | ✅ |
| Memberikan Feedback | ✅ |
| Melihat Anggaran Gereja | ❌ |
| Mengelola Jadwal | ❌ |

### Pelayan (Tenaga Pelayanan)
| Fitur | Akses |
|------|-------|
| Semua fitur Jemaat | ✅ |
| Melihat Jadwal Pelayanan | ✅ |
| Membuat Permintaan Substitusi | ✅ |
| Mengkonfirmasi Kehadiran | ✅ |
| Melihat Riwayat Permintaan | ✅ |
| Mengelola Pengguna | ❌ |
| Menyetujui Substitusi | ❌ |

### Admin (Administrator)
| Fitur | Akses |
|------|-------|
| Semua fitur | ✅ |
| Mengelola Pengguna | ✅ |
| Mengatur Peran Pengguna | ✅ |
| Mengelola Jadwal Pelayanan | ✅ |
| Meninjau Permintaan Substitusi | ✅ |
| Memantau Konfirmasi Kehadiran | ✅ |
| Mengelola Renungan & Quest | ✅ |

---

## Panduan Pengguna

### Untuk Pengguna Jemaat

#### Masuk ke Aplikasi
1. Buka aplikasi dan masukkan email/nama pengguna
2. Masukkan password
3. Klik **Login**

#### Melihat Alkitab
1. Dari beranda, klik tab **Alkitab**
2. Pilih buku Alkitab dari daftar
3. Baca ayat-ayat yang diinginkan

#### Membaca Renungan Harian
1. Dari beranda, scroll ke bagian "Renungan Hari Ini"
2. Baca renungan lengkap dengan doa
3. Anda dapat memberikan feedback melalui tombol rating

#### Mengikuti Reading Quest
1. Klik tab **Quest** dari beranda
2. Pilih quest yang ingin diikuti
3. Baca ayat-ayat yang ditentukan
4. Tandai sebagai selesai dengan mengklik checkbox

### Untuk Pengguna Pelayan

#### Melihat Jadwal Pelayanan
1. Masuk ke aplikasi dengan akun Pelayan
2. Dari Beranda Pelayan, klik tab **Jadwal**
3. Lihat semua jadwal pelayanan Anda yang sudah dijadwalkan
4. Setiap jadwal menampilkan:
   - Tanggal dan waktu
   - Jenis pelayanan
   - Lokasi

#### Membuat Permintaan Substitusi

**Kapan Digunakan:** Ketika Anda tidak dapat hadir pada jadwal pelayanan yang dijadwalkan.

**Langkah-langkah:**
1. Buka tab **Substitusi**
2. Klik tombol **Minta Ganti** pada jadwal yang ingin diminta substitusinya
3. Isi form dengan:
   - **Alasan**: Jelaskan mengapa Anda meminta substitusi (wajib)
   - **Nama Pengganti** (opsional): Jika Anda sudah memiliki pengganti
4. Klik **Kirim Permintaan**

**Status Permintaan:**
- 🟡 **Menunggu** - Permintaan belum disetujui admin
- 🟢 **Disetujui** - Admin telah menyetujui, pengganti sudah ditentukan
- 🔴 **Ditolak** - Admin menolak permintaan (lihat catatan admin)
- ✅ **Selesai** - Jadwal pelayanan telah berlalu

#### Mengkonfirmasi Kehadiran

**Kepada Siapa:** Untuk jadwal pelayanan yang akan datang dalam 1 hari ke depan.

**Langkah-langkah:**
1. Buka tab **Kehadiran**
2. Lihat daftar jadwal yang perlu dikonfirmasi
3. Untuk setiap jadwal, klik tombol **Konfirmasi Hadir** (hijau)
4. Opsional: Tambahkan catatan (contoh: "Siap 10 menit lebih awal")
5. Klik **Konfirmasi**

**Membatalkan Konfirmasi:**
- Jika Anda meng-klik tombol **Konfirmasi** sebelumnya, Anda dapat membatalkannya dengan klik tombol merah **X** pada jadwal yang sudah dikonfirmasi

#### Melihat Notifikasi

1. Buka tab **Notifikasi** di Beranda Pelayan
2. Lihat semua notifikasi sistem, termasuk:
   - Permintaan substitusi disetujui/ditolak
   - Perubahan jadwal
   - Pengumuman dari admin
3. Klik notifikasi untuk melihat detail lengkap

#### Beralih Peran (Jika Memiliki Multiple Role)

Jika Anda memiliki lebih dari satu peran (contoh: Jemaat dan Pelayan):

1. Lihat **dropdown peran** di AppBar (bagian atas layar)
2. Anda akan melihat semua peran Anda dengan emoji:
   - 👥 Jemaat
   - 🙏 Pelayan
   - 👨‍💼 Admin
3. Klik dropdown dan pilih peran yang ingin Anda gunakan
4. Aplikasi akan menampilkan screen yang sesuai dengan peran yang dipilih

---

## Panduan Admin

### Mengakses Panel Admin

1. Masuk dengan akun admin
2. Anda akan langsung diarahkan ke **Dashboard Admin**
3. Klik tab **Kelola Data** untuk mengakses semua fitur administrasi

### Tab-Tab Admin

#### 1. User - Mengelola Pengguna
- **Tambah Pengguna**: Klik tombol "Tambah User"
- **Edit Pengguna**: Klik user di list untuk mengubah info
- **Hapus Pengguna**: Klik tombol "Hapus"
- Cari pengguna dengan kotak pencarian

#### 2. Role - Mengatur Peran Pengguna

**Memberikan Multiple Role:**
1. Klik pada pengguna yang ingin diubah perannya
2. Dialog akan menampilkan checkbox untuk setiap peran:
   - ☑️ Jemaat
   - ☑️ Pelayan
   - ☑️ Admin
3. Centang peran yang ingin diberikan (minimal 1 harus dipilih)
4. Klik **Simpan**

**Catatan:** 
- Setiap pengguna harus memiliki setidaknya 1 peran
- Pengguna dapat memiliki semua 3 peran sekaligus
- Perubahan peran berlaku langsung saat pengguna membuka ulang aplikasi

#### 3. Renungan - Mengelola Renungan Harian
- Tambah renungan baru
- Edit renungan yang ada
- Hapus renungan lama

#### 4. Quest Baca - Mengelola Reading Quest
- Buat quest membaca Alkitab baru
- Tentukan ayat-ayat yang harus dibaca
- Atur waktu deadline

#### 5. Feedback - Melihat Feedback Pengguna
- Lihat feedback dari jemaat
- Balas atau analisis feedback
- Lihat rating dan komentar

#### 6. Pelayan - Mengelola Data Pelayan
- Tambah pelayan baru
- Edit informasi pelayan (nama, kontak, dll)
- Lihat riwayat pelayanan

#### 7. Jadwal Ibadah - Mengelola Jadwal Pelayanan
- Buat jadwal pelayanan baru
- Edit jadwal yang ada
- Tentukan jenis pelayanan dan tanggal
- Tutup atau aktifkan jadwal

#### 8. Jadwal Latihan - Mengelola Jadwal Latihan
- Buat jadwal latihan untuk pelayan
- Atur materi latihan
- Tentukan instruktur

#### 9. Substitusi - Meninjau Permintaan Substitusi

**Meninjau Permintaan:**
1. Klik tab **Substitusi**
2. Filter permintaan berdasarkan status:
   - **Menunggu** - Permintaan yang perlu ditinjau
   - **Disetujui** - Permintaan yang sudah disetujui
   - **Ditolak** - Permintaan yang ditolak
   - **Semua** - Tampilkan semua permintaan

**Menyetujui Permintaan:**
1. Klik permintaan dengan status "Menunggu"
2. Klik tombol **Setujui** (hijau)
3. Pilih pengganti dari dropdown
4. Opsional: Tambahkan catatan untuk requester
5. Klik **Setujui**
6. **Notifikasi otomatis** akan dikirim ke pelayan yang meminta

**Menolak Permintaan:**
1. Klik tombol **Tolak** (merah) pada permintaan
2. Masukkan alasan penolakan (wajib)
3. Klik **Tolak**
4. **Notifikasi otomatis** akan dikirim dengan alasan penolakan

#### 10. Kehadiran - Memantau Konfirmasi Kehadiran Pelayan

**Ringkasan:**
- **Total**: Jumlah seluruh jadwal pelayanan
- **Sudah Konfirmasi**: Berapa banyak yang sudah dikonfirmasi
- **Belum Konfirmasi**: Berapa banyak yang masih pending

**Filter & Cari:**
1. Gunakan filter untuk melihat:
   - **Semua** - Semua konfirmasi
   - **Sudah Konfirmasi** - Hanya yang sudah dikonfirmasi
   - **Belum Konfirmasi** - Hanya yang belum dikonfirmasi
2. Gunakan kotak pencarian untuk mencari nama pelayan

**Melihat Detail:**
1. Klik pada konfirmasi untuk melihat detail lengkap:
   - Nama pelayan
   - Tanggal jadwal
   - Status konfirmasi
   - Waktu konfirmasi
   - Catatan pelayan

**Refresh Data:**
- Tarik ke bawah untuk menyegarkan data terbaru

---

## Sistem Substitusi Pelayan

### Alur Kerja Substitusi

```
1. Pelayan membuat permintaan substitusi
                ↓
2. Admin menerima notifikasi
   (jumlah pending terlihat)
                ↓
3. Admin meninjau di tab "Substitusi"
                ↓
4. Admin memilih untuk Setujui atau Tolak
                ↓
5. Pelayan menerima notifikasi hasil
   - Jika setujui: "Permintaan disetujui, pengganti: [Nama]"
   - Jika tolak: "Permintaan ditolak, alasan: [Alasan]"
```

### Notifikasi Otomatis

- **Ke Admin**: Notifikasi baru ketika permintaan dibuat
- **Ke Pelayan**: 
  - Ketika permintaan disetujui
  - Ketika permintaan ditolak (dengan alasan)

### Status Permintaan

| Status | Warna | Arti |
|--------|-------|------|
| Menunggu | Kuning | Sedang menunggu persetujuan admin |
| Disetujui | Hijau | Sudah disetujui, pengganti ditentukan |
| Ditolak | Merah | Ditolak oleh admin |
| Selesai | Abu-abu | Jadwal pelayanan sudah berlalu |

---

## Sistem Konfirmasi Kehadiran

### Kapan Pelayan Harus Konfirmasi

- Jadwal pelayanan yang akan datang dalam **1 hari ke depan**
- Pelayan akan melihat daftar di tab "Kehadiran"

### Alur Konfirmasi

```
1. Aplikasi menghasilkan daftar jadwal yang perlu dikonfirmasi
   (jadwal yang dekat dalam 1 hari)
                ↓
2. Pelayan membuka tab "Kehadiran"
                ↓
3. Pelayan mengklik tombol "Konfirmasi Hadir" (hijau)
                ↓
4. Aplikasi mencatat:
   - Waktu konfirmasi
   - Catatan dari pelayan (jika ada)
                ↓
5. Admin dapat melihat status di tab "Kehadiran"
```

### Data yang Dicatat

Saat pelayan mengkonfirmasi kehadiran, sistem mencatat:
- ✅ Siapa yang konfirmasi (nama pelayan)
- ✅ Kapan dikonfirmasi (waktu pasti)
- ✅ Catatan pelayan (jika ada)
- ✅ ID unik untuk audit trail

### Admin Memantau

Admin dapat melihat:
- Jumlah total jadwal yang dijadwalkan
- Berapa banyak yang sudah dikonfirmasi
- Siapa saja yang belum konfirmasi
- Detail masing-masing konfirmasi

---

## Pemindahan Peran

### Kapan Menggunakan Pemindahan Peran

**Scenario 1:** Pengguna memiliki role Jemaat + Pelayan
- Di layar utama, ada dropdown di AppBar
- Klik untuk melihat semua role
- Pilih role yang ingin digunakan

**Scenario 2:** Pengguna hanya memiliki 1 role
- Dropdown tidak ditampilkan (disembunyikan otomatis)

### Cara Beralih Peran

1. Lihat **AppBar** (bagian atas layar)
2. Klik dropdown peran (menampilkan icon role saat ini)
3. Pilih peran dari daftar:
   - 👥 Jemaat
   - 🙏 Pelayan
   - 👨‍💼 Admin
4. Layar akan berubah sesuai peran yang dipilih

### Fitur Pemindahan Peran

- ✅ Instant switching - langsung berganti tampilan
- ✅ Menyimpan preferensi - role terakhir diingat
- ✅ Akses cepat - bisa beralih tanpa logout
- ✅ Notifikasi - Snackbar menunjukkan role baru

---

## Troubleshooting

### Saya tidak bisa melihat fitur Pelayan
**Solusi:** 
- Admin perlu memberikan role "Pelayan" ke akun Anda
- Hubungi admin untuk permintaan role

### Permintaan substitusi saya belum disetujui
**Solusi:**
- Tunggu admin meninjau di tab "Substitusi"
- Biasanya diproses dalam 24 jam
- Periksa notifikasi untuk status update

### Konfirmasi kehadiran tidak muncul di tab Kehadiran
**Solusi:**
- Konfirmasi hanya muncul untuk jadwal dalam 1 hari ke depan
- Jika jadwal lebih jauh, akan muncul sebelum waktunya

### Dropdown pemindahan peran tidak muncul
**Solusi:**
- Anda hanya memiliki 1 role
- Minta admin untuk memberikan role tambahan jika diperlukan

### Data tidak ter-sync
**Solusi:**
- Buka Settings dan tekan "Refresh Data"
- Atau tutup dan buka ulang aplikasi

---

## Informasi Teknis

### Penyimpanan Data
- Semua data disimpan di perangkat lokal (SharedPreferences)
- Data tidak tersimpan di cloud
- Backup dapat dilakukan melalui file export

### Format Tanggal
- Format tampilan: DD MMM YYYY, HH:MM (Contoh: 25 Mei 2026, 10:30)
- Zona waktu: Sesuai pengaturan perangkat

### Notifikasi
- Notifikasi ditampilkan di tab "Notifikasi"
- Notifikasi dapat ditandai sebagai sudah dibaca
- Notifikasi lama dapat dihapus

---

## Dukungan

Jika mengalami masalah:
1. Hubungi admin gereja
2. Berikan detail error yang ditampilkan
3. Sertakan screenshot jika diperlukan

**Terakhir diperbarui:** 25 Mei 2026
