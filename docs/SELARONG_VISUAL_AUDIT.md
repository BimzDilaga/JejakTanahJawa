# Audit visual Bab 3 Selarong — 24 November 2026

Bab 3 sekarang menggunakan teropong dan lingkungan bertekstur, dengan kedalaman lembah yang mengisi seluruh kamera sampai bawah jurang. Alur tetap: penjaga → Diponegoro → pengamatan → laporan.

## Hasil audit dan perbaikan

- Bidang langit di bawah jurang: diganti panorama lembah opaque sebagai lapisan kedalaman. Ubin dipasang bergantian terbalik dan overlap dua piksel, mencakup kamera dari awal sampai ujung bab.
- Tebing bawah yang tampak tertarik panjang: lapisan kedalaman lama diganti gambar lembah yang dibuat khusus. Tebing dan gambar gua pengguna tetap menjadi lapisan dekat.
- Pijakan persegi polos: diganti batu kapur berlumut. Tinggi permukaan lumut dihitung dari PNG dan disejajarkan dengan permukaan collider; rute lompatan tetap dapat dilalui.
- Pos pengamat tanpa alat: dipasang teropong kuningan pada tripod kayu, dengan petunjuk E untuk menggunakannya. Pos berada di atas batu yang bertumpu ke tanah.
- Gubuk geometris: diganti gubuk bambu/jerami. Ini objek lingkungan; sistem upgrade tetap mengikuti rencana pengguna.
- Teks status berulang dan notifikasi yang menyentuh HUD stance: dirapikan. Petunjuk interaksi dipindah ke bawah agar tidak menutup Jaka atau teropong.
- Idle Jaka: memakai gambar asli `assets/Animasi Karakter/Jaka New/Javanese-Inspired Pixel Art Warrior.png`, dengan tinggi dan pijakan konsisten. File asal tidak ditimpa.

## Aset yang dibuat dan dipasang

Semua gambar baru dibuat menggunakan **built-in image_gen**, lalu disimpan dalam proyek. PNG sumber hasil generasi mempertahankan alpha aslinya; crop dan permukaan pijakan dicatat terpisah di `data/selarong_art.json`.

| File di `assets/Generated/Selarong/` | Kegunaan |
|---|---|
| `telescope-v1.png` | Teropong pada pos pengamat |
| `limestone-platform-v1.png` | Tiga pijakan parkour berlumut |
| `lookout-rock-v1.png` | Batu besar penyangga pos pengamat |
| `shelter-v1.png` | Gubuk di jalur menuju gua |
| `valley-depth-v1.png` | Kedalaman lembah tanpa lubang alpha |

Prompt lengkap: [SELARONG_ASSET_PROMPTS.json](SELARONG_ASSET_PROMPTS.json). Metadata gambar dapat dibuat ulang dengan `tools/prepare_selarong_assets.py` (Pillow). Frame idle dibuat ulang dengan `tools/prepare_jaka.gd -- --idle-only`.

## Verifikasi

- `tests/chapter_three_smoke.tscn`: seluruh alur penjaga, gua, lompatan, teropong, dan laporan sampai akhir bab.
- `tests/selarong_visual_audit.tscn`: 20 kombinasi posisi/waktu, termasuk jurang, sambungan panorama, gubuk, gua, pos pengamat, dan batas kanan. Pemeriksaan memastikan panorama opaque, overlap ubin, cakupan kamera, serta kecocokan permukaan gambar dengan collider.
- Screenshot renderer tersedia ketika tes audit dijalankan dengan `-- --screenshots=<folder>`. Siang mencakup 11 posisi; pagi, sore, dan malam masing-masing tiga posisi utama.
- `tests/jaka_combat.tscn`: frame idle khusus, jalan/lari, parry, stance, dan partikel.
- `tests/day_night_smoke.tscn`: filter tetap berlaku di Bab 1–3 dan UI berada di atas filter.

Jalankan audit headless:

    godot --headless --fixed-fps 60 --path . res://tests/selarong_visual_audit.tscn

Untuk menilai tampilannya, jalankan dengan renderer dan argumen screenshot. Audit cakupan otomatis dilengkapi pemeriksaan gambar pada area jurang, gua, gubuk, dan teropong.
