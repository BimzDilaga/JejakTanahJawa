# Jejak Tanah Jawa

Bab 1: Tegalrejo, Bab 2: Menembus Jalur Perlawanan, dan Bab 3: Selarong, 1825. Proyek Godot 4.7.2, renderer Compatibility.

## Menjalankan

Buka `project.godot` di Godot, tunggu impor aset selesai, tekan F5, lalu pilih **Mulai perjalanan** untuk melihat prolog Sari dan masuk Bab 1.
Pilih **Main Bab 2** atau **Main Bab 3** untuk mencoba bab tertentu. Menyelesaikan Bab 1 dan 2 juga membuka tombol lanjut ke bab berikutnya.

## Kontrol

- A/D atau panah: bergerak
- Tahan Shift: lari; lepas untuk kembali berjalan
- Space: lompat
- E: bicara, tampilkan teks, lanjut dialog, pilih jawaban pertama
- 1/2 atau klik: memilih jawaban pada dialog
- J: serang dengan bambu runcing. Animasi sementara memakai tiga frame pertama ulti.
- K: parry bambu runcing selama 0,4 detik, dengan cooldown 1 detik.
- H: gunakan satu item heal untuk memulihkan satu hati. Item diperoleh dari bekal atau setiap tujuh tentara yang dikalahkan.
- L: dash yang melukai dan membuat musuh terkena stun. Lima serangan yang mengenai musuh mengisi ulti.
- T: catatan sejarah
- Esc: jeda / lanjut

## Alur Bab 1

Jaka berbicara dengan sesepuh untuk memahami ketegangan di Tegalrejo. Ia menerima pesan dari utusan, mengantarkannya kepada penjaga di ujung desa, lalu keluar. Pilihan jawaban memberi respons singkat yang berbeda, tetapi fakta sejarah dan hasil cerita tetap sama.

## Alur Bab 2

Peta sepanjang 15.100 piksel menghubungkan tepi desa, jembatan rusak, tempat singgah warga, jalur patroli, dan kawasan menuju Selarong. Setelah melewati patroli, seberangi jurang melalui tujuh pijakan untuk menemui utusan.

Ada 16 tentara yang bisa menyerang dari dekat atau menembak dari jauh. Dua titian membantu melewati sebagian patroli. Checkpoint tersedia di seberang jembatan, sebelum patroli, dan sebelum jurang. Jatuh atau kalah mengembalikan pemain ke checkpoint terakhir. Misi bantuan yang selesai tetap tercatat selama sesi.

## Alur Bab 3

Di Selarong, Jaka melewati pijakan batu, menyampaikan kabar warga kepada penjaga gua, lalu berbicara dengan Diponegoro. Ia naik ke batu pengamat untuk melihat jalur permukiman dan kembali melapor. Bab ini berfokus pada eksplorasi dan dialog. Bab 4 Desa Terdampak dan Bab 5 Magelang belum dibuat; bos Belanda disimpan untuk bab penutup.

Durasi permainan perlu dinilai lewat playtest karena tes otomatis membaca dialog seketika.

Menu, dialog dengan potret dan pilihan jawaban, catatan sejarah per bab, kucing pendamping, jeda, dan layar selesai tersedia. Panel dialog berada di bawah area permainan, dengan potret setengah badan yang muncul sedikit di atas panel. Belum ada audio.

Jaka dan NPC pendukung adalah tokoh fiksi; percakapan bukan kutipan historis. Lihat `docs/HISTORY.md` untuk sumber dan pilihan redaksi.

## Mengedit

- `scripts/chapter_one.gd`: dunia, UI, dan alur saat permainan dijalankan. Sebagian besar layout baru terlihat saat runtime.
- `data/chapter_one.json`: dialog, jawaban, dan catatan sejarah.
- `player.gd` dan `scripts/actor_visual.gd`: kontrol serta animasi Jaka.
- `scripts/chapter_two.gd`, `bab_jalur_perlawanan.tscn`: level dan progres Bab 2; memakai UI dan aktor Bab 1.
- `data/chapter_two.json`: dialog, pilihan respons, dan catatan sejarah Bab 2.
- `scripts/chapter_three.gd`, `bab_selarong.tscn`, `data/chapter_three.json`: level, eksplorasi, dan cerita Bab 3.
- `scripts/enemy.gd`: patroli dan pertarungan Bab 2, belum dipakai di Bab 1.
- `game_state.gd`: status sesi.

## Pengujian

Jalankan executable Godot dengan argumen:

    --headless --path . --log-file chapter-smoke.log res://tests/chapter_smoke.tscn

Tes mencakup prolog, gerak dan lompat, dialog, pilihan jawaban, serangan bambu, jeda, penyelesaian bab, dan reset sesi.

Tes Bab 2:

    --headless --fixed-fps 60 --path . --log-file chapter-two-smoke.log res://tests/chapter_two_smoke.tscn

Tes Bab 3:

    --headless --fixed-fps 60 --path . --log-file chapter-three-smoke.log res://tests/chapter_three_smoke.tscn

## Versi web

Workflow `.github/workflows/pages.yml` menguji tiga bab, mengekspor versi browser dengan Godot 4.7.2, lalu menerbitkannya ke GitHub Pages saat `main` diperbarui. Web export memakai template resmi satu thread. Alamat proyek: `https://bimzdilaga.github.io/JejakTanahJawa/`.

Build paket (tidak memerlukan template executable):

    --headless --path . --export-pack "Windows Desktop" ../JejakTanahJawa.pck

Jalankan paket dengan executable Godot dan `--main-pack ../JejakTanahJawa.pck`. Untuk ekspor `.exe` mandiri, pasang export template Godot 4.7.2 dahulu.
