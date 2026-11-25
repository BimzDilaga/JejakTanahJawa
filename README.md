# Jejak Tanah Jawa

Lima bab: Tegalrejo, Jalur Perlawanan, Selarong, Desa Terdampak, dan Magelang. Proyek Godot 4.7.2, renderer Compatibility.

## Menjalankan

Buka `project.godot` di Godot, tunggu impor aset selesai, tekan F5, lalu pilih **Mulai perjalanan baru** untuk melihat prolog Sari dan masuk Bab 1. **Lanjutkan perjalanan** memulihkan slot terakhir. Selesaikan bab untuk membuka daerah berikutnya di **Peta & progres / M**.

Menu memakai satu ilustrasi hasil generasi: Jaka di depan, Diponegoro, Sari, Lasmi, Tegalrejo dan petunjuk tiga urban legend di kejauhan. Pengaturan menyediakan empat slider audio yang disimpan di perangkat.

Bab 3 memakai teropong di pos pengamat, gubuk, pijakan batu berlumut, dan latar lembah berlapis. Idle Jaka menggunakan `Javanese-Inspired Pixel Art Warrior.png`. Audit visual Selarong dan prompt aset tersimpan di `docs/SELARONG_VISUAL_AUDIT.md`.

Saat malam, temui **Penjaga sawah** di Tegalrejo, **Penjaga singgah** di Bab 2, atau **Penjaga kebun** di Desa Terdampak untuk mengikuti rumor Buto Ijo, Banaspati, dan Headless Swordsman. Tekan E untuk mendengar rumor lalu periksa petunjuknya. Setelah pertemuan, tombol kembali membawa pemain ke perjalanan semula. Serangan biasa Jaka memakai enam frame dari aset Attack terbaru.

Pilihan **Arena uji boss** menyediakan Buto Ijo, Banaspati, Headless Swordsman dan komandan tanpa mengubah kemenangan cerita. Tiap percobaan mendapat tiga heal dan dapat diulang dari layar kalah/jeda. Angka combat sementara, audit aset, serta placeholder dicatat di `docs/BOSS_TRIALS.md`.

Banaspati bergantian bertarung di tanah dan terbang kebal. Saat terbang, tembok api mengejar pemain melewati sembilan platform runtuh menuju tanah aman; setelah mendarat, skill terbang memiliki cooldown sementara 16 detik. Rute diperpanjang saat diperlukan. Pembaruan visual memakai `Tanah Baru.png`, bar boss di bawah, partikel debu/bara/benturan, dan filter api tipis khusus Banaspati.

## Kontrol

- A/D atau panah: bergerak
- Tekan Shift: dash pendek; tetap tahan bersama A/D untuk berlari. Lepas untuk berjalan.
- S + Shift: dash mundur sambil mempertahankan arah hadap. Kedua dash berbagi cooldown 1 detik dan tidak memberi kekebalan.
- Space: lompat; tetap dapat digunakan saat dash jika masih berpijak di tanah
- E: bicara, tampilkan teks, lanjut dialog, pilih jawaban pertama
- 1/2 atau klik: memilih jawaban pada dialog
- Klik kiri: serang dengan keris; klik lagi selama ayunan untuk menyambung sampai tiga serangan. Menahan klik tidak mengulang serangan.
- Klik kanan: parry keris selama 0,4 detik. Sukses tanpa cooldown; gagal cooldown 2 detik. Lima sukses memenuhi stance; percobaan berikutnya menyebabkan stun 2 detik. Stance pulih satu poin per detik tanpa parry.
- H: gunakan satu item heal untuk memulihkan satu hati. Item diperoleh dari bekal atau setiap tujuh tentara yang dikalahkan.
- L: dash yang melukai dan membuat musuh terkena stun. Lima serangan yang mengenai musuh mengisi ulti.
- T: catatan sejarah
- M: peta, teleport ke daerah terbuka, dan simpan perjalanan
- F11 atau tombol Layar penuh di menu: fullscreen/keluar fullscreen pada Windows dan browser
- Esc: jeda / lanjut
- F6 (editor/debug): pratinjau fase waktu berikutnya. Tidak aktif pada build release.

Perangkat sentuh mendapat tombol gerak, lompat, serang, parry, dash/lari, mundur, bicara, heal, ulti dan catatan. Gerak + dash + lompat mendukung beberapa jari sekaligus. Combat disembunyikan saat dialog dan diganti tombol Lanjut; pilihan dialog tetap bisa disentuh. Gunakan HP dalam posisi mendatar. Android asli belum diuji.

## Siklus waktu

Pagi → siang → sore → malam berganti otomatis dengan filter warna yang bertransisi halus. Satu siklus berlangsung **4 menit waktu bermain aktif**, sekitar satu menit per fase. Perjalanan baru dimulai pada sore hari sesuai prolog. Waktu diteruskan saat pindah bab dan berhenti selama dialog, jeda, menu, kalah, atau akhir bab.

Filter mencakup langit, lingkungan, karakter, dan efek dunia. HUD, menu, dan panel dialog berada di atas filter agar tetap jelas. Matahari, bulan sabit, bintang, kabut, daun, dan partikel memakai kode. Malam mempertahankan detail pijakan; api Banaspati memberi warna hangat secukupnya.

Durasi bisa diubah melalui `day_cycle_seconds` di `game_state.gd`. `time_of_day` adalah fase 0–1 dalam sesi: pusat pagi 0.125, siang 0.375, sore 0.625, dan malam 0.875. `scripts/day_night_cycle.gd` dan `shaders/day_night.gdshader` mengatur filter bersama untuk lima bab.

## Alur Bab 1

Jaka berbicara dengan sesepuh untuk memahami ketegangan di Tegalrejo. Ia menerima pesan dari utusan, mengantarkannya kepada penjaga di ujung desa, lalu keluar. Pilihan jawaban memberi respons singkat yang berbeda, tetapi fakta sejarah dan hasil cerita tetap sama.

## Alur Bab 2

Peta sepanjang 15.100 piksel menghubungkan tepi desa, jembatan rusak, tempat singgah warga, jalur patroli, dan kawasan menuju Selarong. Setelah melewati patroli, seberangi jurang melalui tujuh pijakan untuk menemui utusan.

Ada 16 tentara yang bisa menyerang dari dekat atau menembak dari jauh. Dua titian membantu melewati sebagian patroli. Checkpoint tersedia di seberang jembatan, sebelum patroli, dan sebelum jurang. Jatuh atau kalah mengembalikan pemain ke checkpoint terakhir. Misi bantuan yang selesai tetap tercatat selama sesi.

## Alur Bab 3

Di Selarong, Jaka melewati pijakan batu, menyampaikan kabar warga kepada penjaga gua, lalu berbicara dengan Diponegoro. Ia naik ke batu pengamat untuk melihat jalur permukiman dan kembali melapor. Bab ini berfokus pada eksplorasi dan dialog, lalu membuka Bab 4.

## Bab 4–5 dan ending

Desa Terdampak berfokus pada kabar tetua, keluarga warga, dan laporan kepada Sari. Headless Swordsman dapat ditemui melalui rumor malam. Narasi kemudian melompati tahun-tahun perang menuju Magelang, Maret 1830. Jaka mencari jalan keluar warga dan menghadapi komandan Belanda fiksi. Ketiga chained attack komandan menggabungkan pukulan pistol, tendangan, tembakan, RAPID, dan FINALSALVO; reload menjadi kesempatan membalas.

Semua bab memiliki patroli biasa yang boleh dilewati dan gubuk upgrade. Demo mulai **600 poin, semua level 0, tiga hati**. Tiga tentara memberi satu poin; biaya atribut **2, 4, 8, 16, ...**. Hati maksimum enam. Stamina awal **200**, pulih **100/detik saat diam, berjalan, maupun berlari** di tanah di luar aksi combat. Serangan/parry/lompat memakai 15/10/20 stamina sementara. Nilai di `data/progression.json`.

Buto Ijo dan Banaspati memiliki **72/56 HP per fase, dua fase**. Bar pertama habis: tumbang, kamera mengunci boss, tahan pose dua detik, reverse untuk bangkit, HP penuh. Fase dua bertempo lebih cepat. Stance break terpisah: berlutut empat detik lalu reverse. Komandan juga memiliki dua fase dengan 160 HP per fase; Headless sementara satu fase 64 HP. Semua angka boss ada di `data/boss_tuning.json`.

Setelah komandan kalah, **Pulang Membawa Nyala** memilih mengantar warga; **Bambu Terakhir** memilih bertahan agar mereka lolos. **Menang, Tapi Tak Mengubahnya** membutuhkan kemenangan cerita atas **Buto Ijo, Banaspati, Headless Swordsman, dan komandan**, lalu memilih membawa warga dan catatan. Kemenangan arena menu tidak memenuhi syarat cerita. Hasil sejarah Diponegoro tetap dipertahankan. Data: `data/endings.json`.

Progres, upgrade, ending, bekal, waktu dan checkpoint disimpan otomatis, dengan tombol simpan di peta. Teleport ke gubuk daerah terbuka mempertahankan progres dan mengembalikan patroli biasa. Mulai perjalanan baru meminta konfirmasi sebelum mereset level ke nol dan poin demo ke 600. Save web mengikuti data situs browser; gunakan profil biasa dan pertahankan data situs untuk melanjutkan di perangkat yang sama.

Durasi permainan perlu dinilai lewat playtest karena tes otomatis membaca dialog seketika.

Menu, dialog dengan potret dan pilihan jawaban, catatan sejarah per bab, kucing pendamping, jeda, dan layar selesai tersedia. Panel dialog berada di bawah area permainan, dengan potret setengah badan yang muncul sedikit di atas panel.

Arena memakai sembilan SFX Banaspati, musik pengguna untuk Buto/Banaspati, cue parry/stance break, serta tiga swing Jaka dan tembakan komandan sintetis sementara. Dua belas SFX Buto dan dua belas SFX Headless dibuat melalui kode. Headless/komandan memiliki musik original sendiri; ambience angin dan serangga mengikuti siklus waktu. Ketiga ending memiliki ilustrasi dan epilog yang dapat dilewati. Rincian dan batasan ada di `docs/PERSISTENCE_AND_PRESENTATION.md` dan `docs/BUTO_IJO_SFX.md`. Tidak ada pemakaian fal untuk pack pengganti ini.

Jaka dan NPC pendukung adalah tokoh fiksi; percakapan bukan kutipan historis. Lihat `docs/HISTORY.md` untuk sumber dan pilihan redaksi.

## Mengedit

- `scripts/chapter_one.gd`: dunia, UI, dan alur saat permainan dijalankan. Sebagian besar layout baru terlihat saat runtime.
- `data/chapter_one.json`: dialog, jawaban, dan catatan sejarah.
- `player.gd`: kontrol, combat, dan pergantian animasi Jaka.
- `scripts/jaka_visual.gd`: pemetaan frame Jaka baru. `scripts/actor_visual.gd` tetap mengatur tentara, NPC, dan kucing.
- `tools/prepare_jaka.gd`: menyiapkan frame di `assets/Generated/Jaka/` dari gambar sumber Jaka New. Jalankan lewat Godot `--headless --path . --script res://tools/prepare_jaka.gd`, lalu impor ulang proyek. Tool ini bukan bagian runtime.
- `scripts/combat_particles.gd`, `scripts/stance_meter.gd`: efek pixel dan indikator stance sementara.
- `docs/DEVELOPMENT_TASKS.md`: pekerjaan selesai, placeholder, temuan aset/audio, dan urutan pekerjaan berikutnya.
- `scripts/chapter_two.gd`, `bab_jalur_perlawanan.tscn`: level dan progres Bab 2; memakai UI dan aktor Bab 1.
- `data/chapter_two.json`: dialog, pilihan respons, dan catatan sejarah Bab 2.
- `scripts/chapter_three.gd`, `bab_selarong.tscn`, `data/chapter_three.json`: level, eksplorasi, dan cerita Bab 3.
- `scripts/enemy.gd`: patroli opsional di seluruh bab; tiga kemenangan memberi satu poin.
- `scripts/late_chapter.gd`, `data/chapter_four.json`, `data/chapter_five.json`: cerita Bab 4–5.
- `scripts/upgrade_hut.gd`, `scripts/stamina_meter.gd`, `data/progression.json`: upgrade dan stamina.
- `scripts/commander_boss.gd`: tiga pola chained attack dan reload final boss.
- `game_state.gd`: status sesi.

## Pengujian

Pembaruan 25 November lolos 12 suite runtime, inspeksi render Bab 4–5/arena, dan pemeriksaan paket Web. Build Web lokal di `.godot/web-nov25/` sudah dihasilkan; belum dipush atau dideploy ke GitHub Pages pada pembaruan ini. Runtime browser belum diperiksa melalui alat browser karena koneksinya gagal inisialisasi.

Jalankan executable Godot dengan argumen:

    --headless --path . --log-file chapter-smoke.log res://tests/chapter_smoke.tscn

Tes mencakup prolog, gerak dan lompat, dialog, pilihan jawaban, serangan keris, jeda, penyelesaian bab, dan reset sesi.

Tes combat Jaka:

    --headless --fixed-fps 60 --path . res://tests/jaka_combat.tscn

Mencakup parry jarak dekat/tembakan, frame pertama yang ditahan, cooldown gagal, lima stance, stun dua detik, pemulihan per detik, lari, dan debu pendaratan. Lompat, stun, mati, dash maju/mundur kini memiliki frame khusus.

Tes combo, mouse, UI, dan dash:

    --headless --fixed-fps 60 --path . res://tests/combat_chain_dash.tscn

Memeriksa klik kiri/kanan, klik UI yang tidak memicu serangan, tiga hit tanpa pengulangan saat ditahan, pembatalan combo, Shift dash lalu lari, dash mundur, cooldown, benturan tembok, damage saat dash, dan animasi kalah.

Tes siklus waktu:

    --headless --fixed-fps 60 --path . res://tests/day_night_smoke.tscn

Mencakup durasi empat menit, perpindahan fase yang halus, jeda saat dialog/menu/pause/kalah/ending, kesinambungan waktu antar bab, dan F6 pada debug. Tanpa `--headless`, tambahkan `-- --screenshots=<folder>` untuk menangkap empat fase pada setiap bab.

Tes kedua boss dan platform runtuh:

    --headless --fixed-fps 60 --path . res://tests/boss_trial_smoke.tscn

Untuk mempersiapkan ulang sumber boss, jalankan `--headless --path . --script res://tools/prepare_bosses.gd`, lalu impor ulang proyek. Frame runtime memakai `data/boss_assets.json`; nilai sementara diatur lewat `data/boss_tuning.json`.

Tes Bab 2:

    --headless --fixed-fps 60 --path . --log-file chapter-two-smoke.log res://tests/chapter_two_smoke.tscn

Tes Bab 3:

    --headless --fixed-fps 60 --path . --log-file chapter-three-smoke.log res://tests/chapter_three_smoke.tscn

## Versi web

Workflow `.github/workflows/pages.yml` menjalankan 16 suite dan pemeriksaan save dalam dua proses, mengekspor versi browser dengan Godot 4.7.2, lalu menerbitkannya ke GitHub Pages saat `main` diperbarui. Web export memakai template resmi satu thread. [Mainkan di GitHub Pages](https://bimzdilaga.github.io/JejakTanahJawa/).

Build paket (tidak memerlukan template executable):

    --headless --path . --export-pack "Windows Desktop" ../JejakTanahJawa.pck

Jalankan paket dengan executable Godot dan `--main-pack ../JejakTanahJawa.pck`. Untuk ekspor `.exe` mandiri, pasang export template Godot 4.7.2 dahulu.
