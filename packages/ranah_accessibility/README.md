# Navigasi suara dan kontak beranda RANAH

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
- Respons pendek dibacakan dengan `flutter_tts` bila id-ID tersedia. Ini belum
  pembacaan seluruh panduan atau chatbot.
- Tombol fitur tetap tersedia jika izin ditolak, bahasa tidak tersedia, koneksi
  gagal, atau browser tidak mendukung pengenalan suara.
- Sesi dihentikan saat dibatalkan, panel ditutup, aplikasi masuk latar belakang,
  atau batas waktu tercapai. Rekaman dan transkrip tidak disimpan oleh RANAH;
  pengenalan ucapan dapat menggunakan layanan perangkat/browser melalui jaringan.

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
