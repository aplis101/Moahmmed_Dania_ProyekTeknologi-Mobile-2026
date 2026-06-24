# SisaPintar - Aplikasi Mobile Pengurang Food Waste Berbasis AI & Flutter

Aplikasi mobile berbasis Flutter yang dirancang untuk membantu mahasiswa kos dan rumah tangga mengurangi pembuangan sisa bahan pangan (*food waste*) dengan merekomendasikan resep masakan kreatif secara instan berdasarkan sisa bahan makanan di kulkas melalui integrasi model kecerdasan buatan (LLM open-source).

Aplikasi ini ditujukan untuk mendukung **Sustainable Development Goals (SDGs) - Goal 2: Zero Hunger (Tanpa Kelaparan)**.

---

## 1. Detail Ideasi & Analisis Masalah (5W1H)

*   **What (Apa)**: Tingginya volume pembuangan sisa bahan pangan (*food waste*) di tingkat rumah tangga karena manajemen bahan makanan yang buruk.
*   **Who (Siapa)**: Mahasiswa kos dan masyarakat umum yang sering membuang sisa bahan masakan karena bingung cara mengolahnya.
*   **Where (Di mana)**: Di lingkungan tempat tinggal mahasiswa kos dan area perumahan padat penduduk di Indonesia.
*   **When (Kapan)**: Saat bahan makanan mendekati masa kedaluwarsa atau setelah aktivitas memasak harian ketika ada bahan mentah tersisa.
*   **Why (Mengapa)**: Inefisiensi pangan merugikan ekonomi rumah tangga dan memperparah masalah kelaparan global yang bertentangan dengan SDGs Goal 2.
*   **How (Bagaimana)**: Menyediakan aplikasi mobile cerdas untuk mengonversi sisa bahan makanan menjadi ide resep kreatif secara instan.

---

## 2. Fitur Utama Aplikasi

1.  **Smart Ingredient Matcher (Rekomendasi Resep AI)**: Pengguna memasukkan daftar sisa bahan makanan di dapur untuk memicu rekomendasi resep masakan praktis secara real-time via API LLM (Groq/HuggingFace).
2.  **Local Expiry Tracker (Pengingat Kedaluwarsa)**: Pencatatan tanggal kedaluwarsa bahan makanan secara lokal (SQLite/Hive) yang dilengkapi notifikasi pengingat otomatis di ponsel.
3.  **Eco-Impact Dashboard (Statistik & Penghematan)**: Ringkasan statistik jumlah makanan yang berhasil diselamatkan dan kalkulasi perkiraan penghematan finansial pengguna.

---

## 3. Pembagian Peran & Job Desk

Peran dirancang secara berimbang untuk memastikan setiap anggota berkontribusi maksimal sesuai keahliannya. Peran **Dania Elsadig** difokuskan pada non-coding (UI/UX & Quality Assurance) agar dapat memberikan nilai tinggi tanpa tekanan pemrograman langsung.

| Nama Anggota | NIM | Peran Utama | Rincian Job Desk |
| :--- | :--- | :--- | :--- |
| **Mohammed Rashed** | 2406016105 | Full-Stack Developer | - Setup arsitektur aplikasi Flutter<br>- Integrasi database lokal (SQLite/Hive)<br>- Integrasi API LLM (Groq/HuggingFace)<br>- Slicing UI dari Figma ke Flutter code<br>- Implementasi Local Notifications |
| **Dania Elsadig** | 2406016106 | UI/UX & Quality Assurance | - Merancang mockup UI & User Flow di Figma<br>- Membuat dokumen Skenario Pengujian (QA Test Cases)<br>- Melakukan pengujian sistem (Black-box testing)<br>- Dokumentasi progress dan penyusunan Poster Proyek |

---

## 4. Linimasa Pemulihan Internal (Internal Recovery Timeline)

Karena kelompok saat ini berada pada **Minggu 10** namun baru menyelesaikan modul **Minggu 7 (Ideasi & Tim)**, kami menetapkan rencana pemulihan cepat (Sprint Plan) secara bertahap untuk mengejar ketertinggalan:

*   **Minggu 08 (Sprint 1) - Desain & Arsitektur**:
    *   *Dania*: Membuat mockup Figma & diagram User Flow.
    *   *Mohammed*: Setup project Flutter & instalasi dependensi (SQLite/Hive, Local Notifications).
    *   *Output*: [Rencana Kerja Detil Minggu 08](Minggu_08_Panduan/Rencana_Kerja_Minggu_08.md) / [Word Version](Minggu_08_Panduan/Rencana_Kerja_Minggu_08.docx) | [Detail Panduan Tugas](Minggu_08_Panduan/)
*   **Minggu 09 (Sprint 2) - Development & API**:
    *   *Dania*: Membuat dokumen Skenario Pengujian (QA) & verifikasi desain visual UI.
    *   *Mohammed*: Slicing UI, integrasi database Expiry Tracker, dan integrasi API LLM resep.
    *   *Output*: [Rencana Kerja Detil Minggu 09](Minggu_09_Panduan/Rencana_Kerja_Minggu_09.md) / [Word Version](Minggu_09_Panduan/Rencana_Kerja_Minggu_09.docx) | [Detail Panduan Tugas](Minggu_09_Panduan/)
*   **Minggu 10 (Sprint 3) - Pengujian, Bug Fixing & Finalisasi**:
    *   *Dania*: Black-box testing, kompilasi hasil pengujian, dan layouting Poster Proyek Final.
    *   *Mohammed*: Bug-fixing dari hasil QA, refactoring kode, penyempurnaan demo aplikasi untuk responsi.
    *   *Output*: [Rencana Kerja Detil Minggu 10](Minggu_10_Panduan/Rencana_Kerja_Minggu_10.md) / [Word Version](Minggu_10_Panduan/Rencana_Kerja_Minggu_10.docx)

---

## 5. Diagram Alur Pengguna (User Flow Diagrams)

Untuk mempermudah pemahaman alur kerja aplikasi SisaPintar, berikut adalah diagram alur pengguna yang dirancang secara profesional dalam format SVG:
1.  **[User Flow 1 - Smart Recipe Generator (AI)](Diagram_User_Flow/User_Flow_1_Recipe_Generator.svg)**
2.  **[User Flow 2 - Local Expiry Tracker](Diagram_User_Flow/User_Flow_2_Expiry_Tracker.svg)**
3.  **[User Flow 3 - Eco-Impact Dashboard](Diagram_User_Flow/User_Flow_3_Eco_Impact_Dashboard.svg)**

---

## 5. Rencana Pengembangan ke Depan (Future Roadmap)

1.  **Cloud Sync & Backup**: Sinkronisasi data sisa makanan lintas perangkat menggunakan Firebase/Supabase.
2.  **OCR / Barcode Scanner**: Input bahan otomatis menggunakan kamera untuk memindai struk belanja atau barcode produk.
3.  **Food Sharing Community**: Peta lokal interaktif untuk mendonasikan atau bertukar bahan makanan mentah berlebih dengan tetangga terdekat.
4.  **Kemitraan Bank Makanan**: Integrasi dengan lembaga sosial penyalur kelebihan makanan untuk mendistribusikan makanan layak konsumsi secara cepat dan aman.
