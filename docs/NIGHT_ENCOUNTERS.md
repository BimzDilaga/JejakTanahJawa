# Pertemuan boss malam dan serangan Jaka

## NPC rumor

- **Penjaga sawah**, Tegalrejo, sekitar x=1900: rumor Buto Ijo dari batas sawah.
- **Penjaga singgah**, tempat singgah Bab 2, sekitar x=5480: rumor Banaspati dari jurang.
- **Penjaga kebun**, Desa Terdampak Bab 4, sekitar x=3550: rumor Headless Swordsman, petunjuk x=5150.
- Ketiganya diam di lokasi aman, membawa lentera, dan muncul pada fase **Malam** (0,75–1 dari siklus). Tidak ada warga baru yang berjalan di jalur patroli.
- Dekati lalu tekan E dan pilih mengikuti petunjuk. Percakapan membuka jejak, tanpa langsung memindahkan pemain: Buto Ijo berupa seretan pedang di x=3060, Banaspati berupa jejak bara di x=6220. Periksa dengan E lalu pilih mendekati sumber atau menunda. Petunjuk hanya tampak malam setelah rumor didengar.
- Pertemuan memakai arena dan angka combat yang sudah tersedia. Kembali dari layar jeda/kalah/menang memulihkan node perjalanan yang sama: posisi, misi, HP, waktu, bekal, dan hitungan heal tetap milik perjalanan semula. Bekal arena tidak masuk ke perjalanan.
- Kemenangan disimpan bersama perjalanan; saksi memberi dialog setelah boss dikalahkan. Memulai perjalanan baru meminta konfirmasi sebelum mengganti slot. Peta M memungkinkan kembali mencari legenda yang terlewat.
- Arena uji empat boss tersedia dari menu. Headless dapat dilawan dari rumor Bab 4. Ending rahasia memerlukan kemenangan cerita ketiga urban boss dan komandan Bab 5; kemenangan arena menu tidak memenuhi syarat.

Data lokasi/dialog: `data/night_encounters.json`. Pengendali: `scripts/night_encounters.gd`.

## Serangan biasa Jaka

- Sumber: `assets/Animasi Karakter/Jaka New/Attack/Jaka’s Keris Slash Animation.png`.
- Enam potongan `assets/Generated/Jaka/attack_01.png` sampai `attack_06.png`, dengan baseline dan tinggi karakter yang konsisten.
- Ayunan pertama 0,34 detik, kontak sekitar 0,15 detik; sambungan kedua/ketiga 0,38/0,44 detik. Satu hit per target per ayunan. Frame kontak dan event damage disamakan. Damage mengikuti upgrade attack.
- Pose dari ultimate tidak lagi dipakai untuk serangan biasa. Siapkan ulang dengan `tools/prepare_jaka.gd -- --attack-only`.

## Combo baru dan audio

- Spritesheet chained attack Jaka: `assets/Generated/Jaka/Concepts/chained-combo-sheet-v1.png` (6 kolom × 3 baris). Runtime mempertahankan lembar Attack pengguna untuk hit pertama, lalu baris 2/3 hasil generasi sebagai sambungan. Klik kiri lagi setelah 0,1 detik saat ayunan untuk mengantre hit berikutnya, maksimal tiga; tahan klik tidak mengulang. Parry atau dash membatalkan antrean.
- Kontrol terbaru: klik kiri serang, klik kanan parry, tekan Shift dash lalu tahan untuk lari, S+Shift dash mundur. Lihat `COMBAT_POLISH.md` untuk durasi/nilai yang mudah diubah.
- Parry dan stance break boss memakai audio sumber yang sudah dikonversi. Kedua arena memiliki musik loop masing-masing.
- Prompt lengkap spritesheet: `JAKA_CHAINED_ATTACK_PROMPT.md`.
- Prompt musik/SFX Headless Swordsman dan Buto Ijo: `BOSS_AUDIO_PROMPTS.md`.
- Pack 12 SFX Buto Ijo kini dibuat lewat kode dan terpasang, sesuai permintaan terbaru. Rincian: `BUTO_IJO_SFX.md`; sumber: `assets/Generated/Audio/ButoIjo/`. Prompt fal lama tetap disimpan sebagai referensi, tanpa job baru.

## Pengujian

`tests/night_encounters.tscn` memeriksa NPC siang/malam, prioritas input E, pilihan menunda/mengikuti, boss yang benar, kemenangan, pemulihan perjalanan, dialog setelah menang, dan reset sesi. Tes combat dan bab yang sudah tersedia tetap harus lolos.
