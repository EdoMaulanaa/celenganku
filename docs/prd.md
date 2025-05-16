**Product Requirements Document: Celenganku**

| **Versi Dokumen:** | 1.0                                      |
| :----------------- | :--------------------------------------- |
| **Penulis:**       | Edo |
| **Stakeholders:**  | Pengembang Aplikasi, (Calon) Pengguna    |
| **Status:**        | DRAFT                                    |

**1. Pendahuluan**

"Celenganku" adalah aplikasi tabungan digital personal yang dirancang untuk memberdayakan pengguna dalam mengelola keuangan mereka secara lebih efektif melalui pencatatan tabungan yang terstruktur dan pencapaian target finansial. Aplikasi ini bertujuan untuk memberikan pengalaman pengguna yang intuitif, bersih, dan modern, memungkinkan pengguna untuk membuat beberapa "celengan" atau pos tabungan terpisah untuk berbagai tujuan. Dibangun menggunakan Flutter untuk frontend cross-platform dan Supabase untuk backend yang scalable dan aman.

**2. Tujuan Produk (Goals & Objectives)**

*   **Tujuan Pengguna:**
    *   Menyediakan platform yang mudah digunakan untuk mencatat pemasukan dan pengeluaran dana dari berbagai pos tabungan.
    *   Memfasilitasi pembuatan dan pelacakan progres target tabungan spesifik untuk setiap pos.
    *   Meningkatkan kesadaran finansial dan disiplin menabung.
    *   Menawarkan visualisasi yang jelas mengenai total aset tabungan dan alokasinya.
*   **Tujuan Bisnis/Aplikasi:**
    *   Menciptakan aplikasi tabungan personal yang kompetitif dan disukai pengguna.
    *   Mendorong adopsi pengguna yang tinggi melalui antarmuka yang user-friendly dan fitur yang relevan.
    *   Memastikan keamanan dan privasi data pengguna sebagai prioritas utama.
    *   Membangun fondasi yang solid untuk pengembangan fitur lanjutan di masa depan.

**3. Target Pengguna**

*   **Demografi:** Dewasa muda (18-35 tahun), pelajar, profesional muda, atau siapa saja yang ingin memulai atau meningkatkan kebiasaan menabung secara digital.
*   **Karakteristik:**
    *   Melek teknologi dan nyaman menggunakan aplikasi mobile.
    *   Mencari solusi sederhana namun efektif untuk manajemen tabungan personal.
    *   Memiliki berbagai tujuan finansial jangka pendek hingga menengah (misalnya, membeli gadget, liburan, dana darurat).
    *   Menghargai desain yang bersih dan pengalaman pengguna yang tidak rumit.

**4. Visi Produk & Solusi yang Diajukan**

"Celenganku" akan menjadi asisten tabungan digital personal yang andal, memungkinkan pengguna untuk:

1.  **Membuat dan Mengelola Beberapa Pos Tabungan:** Pengguna dapat membuat "celengan" virtual terpisah (misalnya, "Dana Darurat," "Liburan Bali," "Laptop Baru") untuk alokasi dana yang lebih terorganisir.
2.  **Mencatat Transaksi dengan Mudah:** Proses input pemasukan (menabung) dan pengeluaran (mengambil dari tabungan) dibuat secepat dan seintuitif mungkin, dengan asosiasi ke pos tabungan yang relevan.
3.  **Menetapkan dan Melacak Target:** Setiap pos tabungan dapat memiliki target nominal dan tanggal, dengan visualisasi progres yang jelas.
4.  **Mendapatkan Gambaran Umum Finansial:** Dashboard utama akan menyajikan ringkasan total saldo di semua pos tabungan dan progres target secara keseluruhan.

**5. Fitur Utama (Key Features & Functionality)**

**5.1. Autentikasi Pengguna (User Authentication)**
    *   **5.1.1. Pendaftaran Akun:** Menggunakan Email & Password.
    *   **5.1.2. Login Akun:** Menggunakan Email & Password.
    *   **5.1.5. Logout.**

**5.2. Manajemen Pos Tabungan (Savings Accounts Management)**
    *   **5.2.1. Pembuatan Pos Tabungan Baru:**
        *   Input: Nama Pos Tabungan, Deskripsi, Ikon, Gambar Tabungan(Thumbnail), Target Nominal, Tanggal Target.
    *   **5.2.2. Daftar Pos Tabungan:** Menampilkan semua pos tabungan milik pengguna di halaman utama atau halaman khusus.
        *   Informasi per pos: Nama, Saldo Saat Ini, Progress Bar (jika ada target).
    *   **5.2.3. Detail Pos Tabungan:**
        *   Menampilkan informasi lengkap pos tabungan: Nama, Deskripsi, Saldo, Target Nominal, Sisa Target, Progres.
        *   Riwayat transaksi spesifik untuk pos tabungan tersebut.
    *   **5.2.4. Edit Pos Tabungan:** Mengubah nama, deskripsi, ikon, target.
    *   **5.2.5. Hapus Pos Tabungan:** Dengan konfirmasi. Jika ada saldo, berikan opsi untuk mentransfer saldo ke pos lain atau tandai sebagai pengeluaran.

**5.3. Manajemen Transaksi (Transaction Management)**
    *   **5.3.1. Pencatatan Transaksi Baru:**
        *   Input: Pilih Pos Tabungan (wajib), Jumlah (wajib), Jenis Transaksi (Pemasukan/Pengeluaran, wajib), Tanggal (default hari ini, bisa diubah), Catatan (opsional), Kategori (opsional, predefined list atau custom).
    *   **5.3.2. Riwayat Transaksi Global:** Menampilkan semua transaksi dari semua pos tabungan.
        *   Informasi per transaksi: Jumlah, Jenis, Tanggal, Catatan, Kategori, Pos Tabungan terkait.
        *   Filter berdasarkan: Tanggal, Jenis, Kategori, Pos Tabungan.
    *   **5.3.3. Edit Transaksi.**
    *   **5.3.4. Hapus Transaksi.**

**5.4. Dashboard / Halaman Utama**
    *   **5.4.1. Tampilan Saldo Total:** Agregasi saldo dari semua pos tabungan.
    *   **5.4.2. Ringkasan Pos Tabungan:** Daftar ringkas pos tabungan aktif dengan saldo masing-masing.
    *   **5.4.3. Akses Cepat:** Tombol untuk "Buat Pos Tabungan Baru" dan "Catat Transaksi Baru".

**5.5. Profil Pengguna**
    *   **5.5.1. Tampilan Informasi Akun:** Nama Pengguna, Email.
    *   **5.5.2. Edit Profil:** Ganti Nama Pengguna.
    *   **5.5.3. Ganti Password.**
    *   **5.5.4. Pengaturan Aplikasi:**
        *Pilihan Tema (Terang/Gelap). default Theme: Terang.

**6. Alur Pengguna (User Flow) - High Level**

1.  **Pengguna Baru:** Splash -> Onboarding (opsional) -> Daftar -> Login -> Dashboard -> Buat Pos Tabungan -> Catat Transaksi.
2.  **Pengguna Lama:** Splash -> Login -> Dashboard -> Lihat Saldo/Pos -> Catat Transaksi / Lihat Riwayat / Kelola Pos Tabungan.
3.  **Mencapai Target:** Dashboard -> Pilih Pos Tabungan dengan Target -> Lihat Progres -> Tandai Tercapai (jika diimplementasikan).

**7. Desain & Pengalaman Pengguna (UX/UI Guidelines)**

*   **Prinsip Desain:**
    *   **Modern & Bersih:** Estetika minimalis, penggunaan whitespace yang baik, tipografi yang jelas.
    *   **Intuitif:** Alur navigasi yang mudah dipahami, aksi yang jelas.
    *   **User-Friendly:** Mengurangi friksi, memberikan feedback visual yang memadai.
    *   **Aksesibel:** Memperhatikan kontras warna dan ukuran font (sesuai standar WCAG AA sebagai target).
*   **Palet Warna:**
    *   **Primary:** Biru (misalnya, `#007AFF` - iOS Blue, atau `#1976D2` - Material Design Blue 700). Variasi shades dan tints dari biru ini akan digunakan untuk elemen interaktif, header, dan aksen utama.
    *   **Secondary/Accent:** Warna komplementer atau analog yang harmonis dengan biru (misalnya, Teal atau Orange muda untuk CTA yang menonjol, jika sesuai).
    *   **Neutral:** Abu-abu (berbagai shades: `#F5F5F5` untuk background, `#757575` untuk teks sekunder, `#212121` untuk teks utama).
    *   **Warna Status:** Hijau untuk sukses/pemasukan (misalnya, `#4CAF50`), Merah untuk error/pengeluaran (misalnya, `#F44336`), Kuning/Oranye untuk peringatan.
*   **Tipografi:** Font Sans-serif modern dan mudah dibaca (inter).
*   **Ikonografi:** Set ikon yang konsisten dan modern (Material Icons).
*   **Navigasi:** Bottom Navigation Bar untuk akses cepat ke bagian utama (Dashboard, Daftar Pos Tabungan, Profil).

**8. Pertimbangan Teknis**

*   **Frontend:** Flutter (Dart) untuk pengembangan cross-platform (iOS & Android).
    *   State Management: Provider / Riverpod / BLoC (diputuskan oleh tim pengembang).
    *   Package `supabase_flutter` untuk interaksi dengan backend.
*   **Backend:** Supabase.
    *   **Database:** PostgreSQL.
    *   **Authentication:** Supabase Auth (Email/Password).
    *   **Storage:** Supabase Storage untuk avatar pengguna atau ikon custom pos tabungan.
    *   **Realtime:** Supabase Realtime untuk update saldo instan.
    *   **Security:** Row Level Security (RLS) wajib diimplementasikan untuk memastikan pengguna hanya dapat mengakses datanya sendiri.
*   **API:** RESTful API yang disediakan oleh Supabase (PostgREST).

**9. Metrik Kesuksesan (Success Metrics)**

*   **Akuisisi & Aktivasi:**
    *   Jumlah unduhan aplikasi.
    *   Jumlah akun terdaftar.
    *   Rasio pengguna yang menyelesaikan onboarding dan membuat pos tabungan pertama.
*   **Engagement:**
    *   Daily Active Users (DAU) / Monthly Active Users (MAU).
    *   Jumlah transaksi yang dicatat per pengguna per minggu/bulan.
    *   Jumlah pos tabungan yang dibuat per pengguna.
    *   Durasi sesi rata-rata.
*   **Retensi:**
    *   Tingkat retensi pengguna (Minggu ke-1, Bulan ke-1, Bulan ke-3).
    *   Tingkat churn.
*   **Kepuasan Pengguna:**
    *   Rating aplikasi di App Store / Play Store.
    *   Feedback kualitatif dari pengguna.
    *   (Jika target diimplementasikan) Persentase target yang berhasil dicapai pengguna.

**10. Pertanyaan Terbuka & Asumsi**

*   **Asumsi:** Pengguna familiar dengan konsep dasar tabungan dan penggunaan aplikasi mobile.
*   **Asumsi:** Koneksi internet tersedia untuk sinkronisasi data dengan Supabase. (Mode offline dasar bisa dipertimbangkan untuk v1.1).
*   **Pertanyaan:**
    *   Perlu daftar kategori transaksi predefined, atau pengguna bisa membuat kategori sendiri? (Predefined untuk v1, custom untuk v1.1).
    *   Bagaimana penanganan kasus jika pengguna ingin menghapus pos tabungan yang masih memiliki saldo? (Transfer/catat sebagai pengeluaran).
    *   Detail implementasi visualisasi progres target (misalnya, jenis chart).