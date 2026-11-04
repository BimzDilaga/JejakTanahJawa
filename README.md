# Jejak Tanah Jawa

Bab 1: Tegalrejo, Juli 1825. Godot 4.7.2, renderer Compatibility.

## Menjalankan
Buka project.godot di Godot dan tekan F5, lalu pilih Mulai perjalanan.

## Kontrol
- A/D atau panah: bergerak
- Space: lompat
- E: interaksi, tampilkan teks, lanjut dialog
- J: serang ke arah hadap
- T: catatan sejarah
- Esc: pause / lanjut

## Progres
Menu, pengantar, desa Tegalrejo, dialog Sari dan Wirya, dua tentara, kesehatan, kucing pendamping, catatan sejarah, pause, ulang permainan, dan transisi akhir Bab 1 sudah tersedia. Bab 2 belum tersedia. Belum ada audio; aset yang diberikan berupa gambar.

Jaka, Sari, Wirya, percakapan, dan pertarungan merupakan dramatisasi fiksi. Sumber sejarah: docs/HISTORY.md.

## Mengedit
- scripts/chapter_one.gd membangun dunia, UI, dan alur saat permainan dijalankan. Sebagian besar layout terlihat saat runtime.
- data/chapter_one.json berisi dialog dan catatan sejarah.
- player.gd dan scripts/enemy.gd mengatur gerak dan pertarungan.
- scripts/actor_visual.gd menentukan crop dan animasi. PNG asli dipertahankan.
- game_state.gd menyimpan state sesi yang direset saat mengulang.

## Pengujian
Jalankan executable Godot dengan argumen:

    --headless --path . --log-file chapter-smoke.log res://tests/chapter_smoke.tscn

Hasil: CHAPTER_SMOKE failures=0, diuji headless dan dengan renderer OpenGL. Meliputi gerak/lompat, dialog, pause, exit sebelum misi selesai, serangan kedua pihak, penghitung musuh, transisi, penyelesaian, reset, dan layar gagal. Tampilan menu, permainan, dialog, jurnal, hasil, dan retry diperiksa melalui tangkapan renderer.

Sandbox pengujian mengeluarkan peringatan shader cache dan certificate store; tidak ada error script pada run pengujian.
