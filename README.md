# Jejak Tanah Jawa

Bab 1: Tegalrejo, Juli 1825. Proyek Godot 4.7.2, renderer Compatibility.

## Menjalankan

Buka `project.godot` di Godot, tekan F5, lalu pilih **Mulai perjalanan**.

## Kontrol

- A/D atau panah: bergerak
- Space: lompat
- E: bicara, tampilkan teks, lanjut dialog, pilih jawaban pertama
- 1/2 atau klik: memilih jawaban pada dialog
- J: menembak; animasi memakai spritesheet `Animasi_Menembak.png`. Pada Bab 1 tidak ada pertarungan wajib menurut naskah terbaru.
- T: catatan sejarah
- Esc: jeda / lanjut

## Alur Bab 1

Jaka berbicara dengan sesepuh untuk memahami ketegangan di Tegalrejo. Ia menerima pesan dari utusan, mengantarkannya kepada penjaga di ujung desa, lalu keluar. Bab 2 menurut naskah baru adalah jalur menuju Selarong dan belum tersedia. Pilihan jawaban memberi respons singkat yang berbeda, tetapi fakta sejarah dan hasil cerita tetap sama.

Menu, desa, dialog dengan potret dan pilihan jawaban, tiga catatan sejarah, kucing pendamping, jeda, dan layar selesai tersedia. Panel dialog berada di atas area permainan supaya Jaka tetap terlihat. Belum ada audio.

Jaka dan NPC pendukung adalah tokoh fiksi; percakapan bukan kutipan historis. Lihat `docs/HISTORY.md` untuk sumber dan pilihan redaksi.

## Mengedit

- `scripts/chapter_one.gd`: dunia, UI, dan alur saat permainan dijalankan. Sebagian besar layout baru terlihat saat runtime.
- `data/chapter_one.json`: dialog, jawaban, dan catatan sejarah.
- `player.gd` dan `scripts/actor_visual.gd`: kontrol serta animasi Jaka. Latar putih pada lembar menembak disaring saat runtime; PNG asli tidak diubah.
- `scripts/enemy.gd`: musuh tersedia sebagai fondasi Bab 2, belum dipakai di Bab 1.
- `game_state.gd`: status sesi.

## Pengujian

Jalankan executable Godot dengan argumen:

    --headless --path . --log-file chapter-smoke.log res://tests/chapter_smoke.tscn

Hasil saat revisi: `CHAPTER_SMOKE failures=0` pada headless dan renderer OpenGL. Tes mencakup gerak/lompat, interaksi tiga NPC, pilihan jawaban kedua, perubahan tujuan, exit terkunci, penggunaan animasi menembak, pause, catatan sejarah, penyelesaian bab, dan reset sesi. Tampilan menu, dialog, pilihan jawaban, dan layar selesai diperiksa dari tangkapan renderer.
