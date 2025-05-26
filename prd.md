# Dokumen Kebutuhan Produk (PRD)

## Ringkasan Produk (Apa dan Mengapa)

### Ikhtisar
Dokumen ini merinci kebutuhan dan spesifikasi untuk aplikasi Celenganku, sebuah platform mobile untuk manajemen keuangan pribadi yang membantu pengguna mengatur, mengelola, dan melacak tabungan mereka secara efektif. Aplikasi ini memungkinkan pengguna membuat "saving pots" (celengan) untuk berbagai tujuan, melacak pemasukan dan pengeluaran, serta memvisualisasikan progres keuangan mereka dengan grafik interaktif. Tujuan utamanya adalah memberikan alat praktis untuk membantu pengguna mencapai tujuan keuangan dan mengelola keuangan pribadi dengan lebih baik.

### Latar Belakang dan Konteks
Di era digital saat ini, pengelolaan keuangan masih menjadi tantangan bagi banyak orang. Sementara aplikasi perbankan menyediakan layanan dasar, banyak yang tidak menawarkan fleksibilitas untuk membagi tabungan berdasarkan tujuan spesifik, melacak progres, dan memvisualisasikan perkembangan keuangan secara komprehensif. Riset pasar menunjukkan kebutuhan akan platform yang mudah digunakan dengan fitur khusus untuk menabung dengan tujuan tertentu (sinking funds), terutama di kalangan generasi muda yang ingin lebih disiplin dalam menabung.

Celenganku hadir sebagai solusi untuk masalah tersebut dengan menyediakan pendekatan visual dan terstruktur untuk menabung, dilengkapi dengan fitur pelacakan dan kategorisasi yang membantu pengguna memahami dan mengelola aliran keuangan mereka dengan lebih baik.

## Kriteria Keberhasilan / Dampak

### Metrik untuk Mengukur Keberhasilan
- Tingkat adopsi pengguna aktif mingguan (WAU) mencapai 10.000 dalam 6 bulan pertama
- Retensi pengguna 30 hari > 40%
- Rata-rata pembuatan 3 saving pots per pengguna
- Konsistensi transaksi: minimum 5 transaksi/bulan per pengguna aktif
- Rating aplikasi > 4.5 di platform distribusi

### Metrik yang Perlu Dipantau
- Waktu yang dihabiskan di aplikasi per sesi
- Frekuensi pembukaan aplikasi per minggu
- Jumlah transaksi yang dicatat per pot
- Tingkat pencapaian target tabungan
- Performa database dan waktu respons API
- Persentase error dan crash aplikasi

## Tim

- **Product Manager:** [Nama]
- **UX/UI Designer:** [Nama]
- **Frontend Developer (Flutter):** [Nama]
- **Backend Developer (Supabase):** [Nama]
- **QA Engineer:** [Nama]

## Desain Solusi

### Kebutuhan Fungsional

#### Autentikasi dan Manajemen Akun
- Pengguna dapat membuat akun baru dengan email dan password
- Pengguna dapat masuk ke akun mereka menggunakan kredensial yang sudah ada
- Pengguna dapat mengubah informasi profil dan preferensi
- Pengguna dapat mengatur dan mengubah kata sandi
- Pengguna dapat meminta reset password melalui email

#### Dashboard Utama
- Pengguna dapat melihat total saldo dari semua saving pots
- Pengguna dapat melihat grafik pengeluaran dan pemasukan bulanan
- Pengguna dapat melihat distribusi pengeluaran berdasarkan kategori
- Pengguna dapat melihat saving pots terbaru dan progresnya

#### Manajemen Saving Pots
- Pengguna dapat membuat pot tabungan baru dengan nama, deskripsi, dan target
- Pengguna dapat menentukan target jumlah dan tanggal untuk setiap pot
- Pengguna dapat menyesuaikan detail pot seperti nama, target, dan deskripsi
- Pengguna dapat melihat visualisasi progres untuk setiap pot tabungan
- Pengguna dapat mencari pot tabungan dengan nama
- Pengguna dapat menghapus pot tabungan yang tidak diperlukan lagi

#### Transaksi
- Pengguna dapat mencatat pemasukan dan pengeluaran untuk pot tabungan tertentu
- Pengguna dapat melihat riwayat transaksi untuk setiap pot dan secara keseluruhan
- Pengguna dapat mengkategorikan transaksi (belanja, transportasi, makanan, dll)
- Pengguna dapat menambahkan catatan dan tanggal pada setiap transaksi
- Pengguna dapat mengedit dan menghapus transaksi yang sudah direkam

#### Visualisasi dan Laporan
- Pengguna dapat melihat grafik progres tabungan bulanan
- Pengguna dapat melihat diagram lingkaran untuk distribusi pengeluaran
- Pengguna dapat melihat riwayat transaksi dalam format kronologis
- Pengguna dapat melihat tren pengeluaran dan pemasukan

#### Preferensi dan Pengaturan
- Pengguna dapat mengubah antara tema terang dan gelap
- Pengguna dapat mengatur format mata uang dan preferensi tampilan

### Kebutuhan Non-Fungsional
- **Keamanan:** Enkripsi data pengguna, autentikasi yang aman, dan perlindungan data sensitif
- **Performa:** Waktu muat aplikasi < 3 detik, respons interaksi < 1 detik
- **Keandalan:** Uptime 99.9%, integritas data terjamin
- **Skalabilitas:** Mendukung hingga 100,000 pengguna aktif
- **Aksesibilitas:** Mendukung pembaca layar, kontras warna yang memadai
- **Kompatibilitas:** Android 7.0+, iOS 12+

## Implementasi

### Dokumen Desain Teknis

#### Arsitektur Aplikasi
Celenganku dibangun menggunakan Flutter untuk frontend dan Supabase untuk backend, dengan arsitektur berikut:

- **Frontend (Flutter):**
  - State Management: Provider pattern untuk manajemen state aplikasi
  - UI Components: Material Design dan custom widgets
  - Visualisasi Data: FL Chart untuk grafik interaktif
  - Navigasi: Sistem router berbasis named routes

- **Backend (Supabase):**
  - Database: PostgreSQL untuk penyimpanan data terstruktur
  - Autentikasi: Supabase Auth untuk manajemen user
  - Storage: Supabase Storage untuk menyimpan gambar profil dan thumbnail pot
  - Realtime: Subscriptions untuk pembaruan data secara realtime

#### Model Data
- **User Profile:** Detail pengguna, preferensi, dan metadata
- **Savings Pot:** Wadah tabungan dengan detail dan target
- **Transaction:** Catatan keuangan terkait dengan pot dan kategori
- **Transaction Category:** Kategori untuk mengklasifikasikan transaksi

#### API dan Integrasi
- Supabase API untuk operasi CRUD pada semua model data
- Supabase Realtime untuk pembaruan data secara instan
- Integrasi dengan sistem file lokal untuk caching dan persistensi

### Rencana Pengujian dan QA

#### Pengujian Unit
- Test komponen UI individual dan logika bisnis
- Test model data dan transformasi
- Test integrasi Provider dengan UI

#### Pengujian Integrasi
- Test alur pengguna end-to-end
- Test sinkronisasi data dengan backend
- Test interaksi antarkomponen

#### Pengujian UI/UX
- Test responsivitas pada berbagai ukuran layar
- Test aksesibilitas
- Test performa UI selama interaksi pengguna

#### Pengujian Keamanan
- Validasi autentikasi dan otorisasi
- Test enkripsi dan perlindungan data
- Test keamanan API

#### Alat dan Metodologi
- Flutter Test framework untuk unit dan widget testing
- Firebase Test Lab untuk pengujian pada berbagai perangkat
- Manual testing untuk validasi UX

## Dampak

Aplikasi Celenganku diharapkan memberikan dampak signifikan pada cara pengguna mengelola keuangan pribadi mereka. Dengan memungkinkan pengelompokan tabungan berdasarkan tujuan, pengguna dapat lebih mudah mencapai target keuangan jangka pendek dan jangka panjang. Visualisasi yang jelas tentang pemasukan, pengeluaran, dan progres tabungan akan membantu meningkatkan kesadaran keuangan dan mendorong kebiasaan menabung yang lebih baik.

Potensi risiko implementasi termasuk masalah performa database saat skala pengguna membesar dan kebutuhan bandwidth yang meningkat untuk fitur realtime. Hal ini akan dimitigasi dengan optimasi query database, implementasi caching efisien, dan penggunaan Supabase secara optimal.

## Catatan

- Fase pertama peluncuran akan fokus pada fitur inti tanpa integrasi perbankan
- Fitur notifikasi dan pengingat akan diimplementasikan pada versi 1.1
- Integrasi dengan layanan perbankan dapat dipertimbangkan untuk versi masa depan
- Backup data otomatis dan ekspor laporan keuangan direncanakan untuk versi 1.2

## Link Dokumentasi Program

http://github.com/celenganku
