# Pemeriksaan pembaruan Jaka — 23 November 2026

Engine: Godot 4.7.2, renderer Compatibility. Sumber diperbarui di direktori proyek asli.

## Hasil

- `tests/jaka_combat.tscn`: `JAKA_COMBAT failures=0`.
- `tests/chapter_smoke.tscn`: `CHAPTER_SMOKE failures=0`.
- `tests/chapter_two_smoke.tscn`: `CHAPTER_TWO_SMOKE failures=0`. Rute patroli dan parkour tetap dapat diselesaikan.
- `tests/chapter_three_smoke.tscn`: `CHAPTER_THREE_SMOKE failures=0`.
- Pemeriksaan renderer nyata: sembilan screenshot idle, jalan, lari, parry window, parry sukses, stance break, heal, ultimate, dan dialog.
- Paket Windows Desktop `.pck`: ekspor exit 0; paket dapat memuat Bab 1 dan enam frame parry. Pemeriksaan juga memastikan sumber mentah Jaka New tidak diperlukan dalam paket.
- `git diff --check`: tidak ada kesalahan whitespace.

## Perbaikan dari hasil pemeriksaan

- Shader flash memakai warna fragment yang sudah bertekstur; menghindari pengalian tekstur dua kali yang menggelapkan karakter.
- Z-index Jaka dinaikkan supaya placeholder platform Bab 2 tidak menutupi tubuhnya.
- Heal tetap dapat dipakai setelah menerima damage, sesuai perilaku sebelumnya.
- Frame gerak yang saling tumpang-tindih pada lembar sumber dipisahkan berdasarkan komponen tubuh agar potongan karakter tetangga tidak ikut tampil.
- Kaki menggunakan baseline tetap; pose airborne pada lari tetap mempunyai gerakan naik/turun.

## Batas pemeriksaan

Ini belum merupakan playtest manusia untuk keseimbangan. Paket web tidak diterbitkan pada pembaruan lokal ini. Efek ultimate RGB sudah dibersihkan dari matte hitam utama; bagian aura/afterimage gelap masih bisa dipoles. Placeholder lompat, serangan biasa, stun, dan mati dirinci di `DEVELOPMENT_TASKS.md`.

Lingkungan uji mengeluarkan pesan kegagalan membaca certificate store Windows; tidak ada kegagalan script atau resource saat pengujian runtime/paket. Empat sumber audio dengan format tidak cocok masih perlu dikonversi dan belum digunakan game.
