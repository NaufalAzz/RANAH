# Pusat Siaga Erupsi RANAH

Paket Flutter bersama untuk mobile dan web. Beranda menampilkan tiga kontak
pertama dari data kontak yang sudah ada; ini nomor layanan umum, bukan hasil
penentuan posko terdekat. Atribusi sumber ditampilkan sebelum membuka telepon.

## Perilaku suara

- Tombol **Suara** di tengah navbar (dan header desktop web) membuka panel.
- Mikrofon baru diminta setelah pengguna menekan **Mulai bicara**. Izin sistem
  dan locale Bahasa Indonesia diperiksa oleh `speech_to_text`.
- Perintah final yang dikenal membuka fitur: panduan, peta, status gunung,
  kontak darurat, berita, notifikasi, menu, beranda. "Evakuasi" memberi pilihan.
- Perintah parsial, tidak dikenal, atau negatif tidak membuka fitur. Navigasi
  tidak pernah memanggil nomor atau meminta lokasi secara otomatis.
- Respons navigasi dan setiap langkah pada Tindakan Sekarang dapat dibacakan
  dengan `flutter_tts` bila id-ID tersedia. Ini bukan chatbot.
- Tombol fitur tetap tersedia jika izin ditolak, bahasa tidak tersedia, koneksi
  gagal, atau browser tidak mendukung pengenalan suara.
- Sesi dihentikan saat dibatalkan, panel ditutup, aplikasi masuk latar belakang,
  atau batas waktu tercapai. Rekaman dan transkrip tidak disimpan oleh RANAH;
  pengenalan ucapan dapat menggunakan layanan perangkat/browser melalui jaringan.

## Pusat siaga

- Tindakan Sekarang: empat kondisi, satu langkah per layar, pembacaan/berhenti,
  serta kontak bantuan. Panduan umum merujuk Buku Saku BNPB.
- Gunung yang Saya Ikuti: pilihan tersimpan, status sumber, rekomendasi laporan,
  waktu data, pembaruan manual. Tidak ada perintah evakuasi otomatis.
- Paket Siaga Offline: simpan laporan dan daftar kesiapan lokal. Panduan tindakan
  sudah dibundel. Web offline bergantung halaman yang telah dimuat dan storage
  browser; tidak menjanjikan pembukaan ulang aplikasi web secara offline.
- Latihan: tiga skenario keputusan, umpan balik dan hasil tersimpan. Tidak memakai
  batas waktu dan tidak menyatakan kesiapan nyata dari skor.
- Arahan Wilayah Saya: akses rekomendasi gunung tersimpan dan kontak. Pengumuman
  desa, jalur dan posko resmi belum tersedia, sehingga tidak dihasilkan otomatis.
- Peta/API hanya menganalisis KRB erupsi. Titik kumpul dan rute OSM umum dihentikan
  (410), berita/cache disaring ke gunung/erupsi/vulkanik/lahar, dan feed BMKG umum
  dikeluarkan dari penjadwalan. Data historis tidak dihapus dari database.
- Konfigurasi `RANAH_API_BASE_URL` tetap mengikuti client aplikasi sebelumnya.
  Bila API belum terkonfigurasi, tindakan dan latihan lokal tetap bisa dipakai.

## Menjalankan pemeriksaan

Gunakan Flutter yang memenuhi SDK aplikasi (`^3.13.2`):

```sh
cd packages/ranah_accessibility
flutter pub get
flutter analyze
flutter test
cd ../../ranah_mobile
flutter pub get
flutter analyze
flutter test
cd ../ranah_web
flutter pub get
flutter analyze
flutter test
flutter build web
```

Lockfile aplikasi diperbarui bersama dependensi paket ini. Android
mendeklarasikan RECORD_AUDIO dan service speech/TTS; iOS memiliki keterangan
izin mikrofon dan speech recognition. Web memerlukan HTTPS atau localhost,
browser yang mendukung speech recognition, serta izin mikrofon. Offline STT dan
suara TTS Bahasa Indonesia tidak dijamin pada semua perangkat.

## Uji perangkat sebelum rilis

- Android/iOS: izinkan dan tolak izin, buka ulang panel, cabut izin di Settings.
- Ucapkan "buka panduan", "peta", "status gunung", "kontak darurat", dan ucapan
  yang tidak dikenal; pastikan fitur tepat dan tidak ada panggilan otomatis.
- Tutup panel, pindah aplikasi, batalkan saat izin sedang muncul: mic harus mati
  dan hasil terlambat tidak boleh memindahkan halaman.
- Chrome dan Safari: periksa dukungan aktual; ketika tidak didukung, tombol
  sentuh tetap bekerja. Uji putus internet dan perangkat tanpa suara id-ID.
- Periksa layar 320px, teks diperbesar, TalkBack/VoiceOver, serta konfirmasi dan
  pembatalan telepon. Nomor dan sumber lama tetap perlu ditinjau sebelum rilis.
