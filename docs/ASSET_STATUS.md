# Status integrasi aset — 18 November 2026

## Pembaruan terbaru — 25 November 2026

Lima bab, tiga epilog bergambar, dua fase Buto/Banaspati, 15 lembar komandan, 15 lembar Headless berbasis desain chat, panorama Magelang, menu ilustrasi empat karakter, matahari/bulan, ultimate transparan Jaka serta SFX swing telah ditambahkan. Pack Buto dan Headless masing-masing berisi **12 WAV sintetis**, dengan musik khusus Headless/komandan dan ambience malam. Save/load serta peta teleport progresif kini berfungsi. Headless diperkecil menjadi sekitar 1,2 kali tinggi Jaka. Gambar asli dari ChatGPT Library belum dapat diambil; sumber generasi tetap terpisah. Rincian: [PERSISTENCE_AND_PRESENTATION.md](PERSISTENCE_AND_PRESENTATION.md), [UPDATE_2026_11_25.md](UPDATE_2026_11_25.md). Catatan lama di bawah adalah riwayat, bukan daftar pekerjaan terbaru.

## Pembaruan Jaka — 23 November 2026 (menggantikan aturan lama di bawah)

- Runtime Jaka kini memakai `scripts/jaka_visual.gd` dan PNG hasil persiapan di `assets/Generated/Jaka/`, dari tujuh lembar `Jaka New`. Gambar sumber tetap utuh.
- Jalan/lari/heal/ultimate masing-masing 8 frame, kena hit 3, parry keris 6, efek ultimate 8. Potret dialog juga berasal dari desain terbaru.
- Idle diperbarui 24 November: gambar asli `Jaka New/Javanese-Inspired Pixel Art Warrior.png`, dipotong ke kanvas gameplay dengan kaki dan tinggi yang konsisten. Frame runtime: `assets/Generated/Jaka/idle_01.png`.
- Serangan pertama memakai enam frame `Jaka New/Attack/Jaka’s Keris Slash Animation.png`; combo kedua/ketiga memakai hasil generasi. Lompat, stance break, kalah, dash maju dan mundur kini memiliki frame khusus. Sumber dan cara menyiapkan: `COMBAT_POLISH.md`.
- Parry: frame pertama ditahan 0,4 detik, frame 2–6 hanya setelah sukses. Sukses tanpa cooldown, gagal cooldown 2 detik. Setiap sukses menambah satu stance sampai 5; mencoba lagi ketika penuh memberi stun 2 detik. Stance pulih satu poin per detik tanpa parry.
- HUD lima slot stance dan partikel debu/benturan/parry/ultimate dibuat lewat kode.
- Pada pembaruan 23 November, sumber boss belum terhubung. Integrasi arena uji dan AI Buto Ijo/Banaspati selesai pada pembaruan 24 November yang dicatat di bawah.
- Empat audio `.mp3` berisi kontainer ISO BMFF sudah dikonversi ke WAV/OGG dan terhubung: parry, stance break boss, musik Buto Ijo, musik Banaspati. File sumber dipertahankan dan dikecualikan dari ekspor.
- Daftar pekerjaan terperinci: `docs/DEVELOPMENT_TASKS.md`.

Catatan bertanggal sebelumnya di bawah adalah riwayat integrasi, termasuk senjata bambu dan cooldown lama.

## Filter waktu

- `scripts/day_night_cycle.gd` dan `shaders/day_night.gdshader`: filter dunia pada CanvasLayer 5; UI tetap pada layer 10.
- Siklus pagi–siang–sore–malam berlangsung 240 detik waktu aktif sesuai keputusan pengguna. Transisi halus; jam berjalan lintas bab dalam sesi.
- Waktu berhenti saat dialog, pause, menu, kalah, dan akhir bab. Perjalanan baru dimulai sore sesuai prolog.
- HUD menampilkan fase waktu. F6 hanya pada debug/editor untuk melihat fase berikutnya.
- Tidak membutuhkan aset gambar baru pada tahap filter ini. Matahari/bulan dan pertemuan boss lewat rumor masih pekerjaan berikutnya.

## Arena uji boss — 24 November 2026

- Buto Ijo/Banaspati dapat dicoba dari panel Urban Legend / Arena Uji pada menu utama.
- 350 PNG hasil potong dan 64 pemetaan animasi/alias disiapkan lewat `tools/prepare_bosses.gd`; sumber asli dipertahankan.
- Buto memakai light/heavy/tiga combo, stance break berlutut 4 detik lalu reverse, serta gelombang tanah. Spawn/mati dan transisi berlutut kini memakai tiga lembar hasil generasi, enam frame per animasi.
- Banaspati memakai aset tanah/terbang/naik/turun, combo, spawn/stance/mati, projectile/retikel/pilar/gelombang/api belakang, dan platform runtuh. Lari serta beberapa gerakan ultimate masih sementara.
- Sembilan SFX WAV Banaspati dipakai dari salinan `assets/Generated/Audio/Banaspati/`; MP3 lama yang tidak cocok tetap tidak dipakai.
- Nilai sementara telah diizinkan pengguna dan dicatat di `data/boss_tuning.json`; audit dan batasan ada di `docs/BOSS_TRIALS.md`.
- Banaspati kini memiliki sembilan platform per fase udara, tembok api besar dari aset yang ada, tanah aman untuk bertarung, dan cooldown terbang sementara 16 detik. Rute bertambah agar siklus dapat terus berulang.

## Pembaruan ini
- Background/gapura/gapura awal.png dan gapura akhir.png: gerbang masuk/keluar Tegalrejo. Latar putih dibersihkan saat runtime; sumber tidak diubah.
- Arsip lari, lompat, tertembak: animasi gerak dan reaksi terkena serangan Jaka.
- Asset in game/heart/hearts_only.png: ikon hati dinamis, lima slot mengikuti HP maksimum yang sudah ada.
- Asset in game/heart/jaka_and_cat_only.png: identitas HUD.
- Asset in game/gun efect.png: efek tembakan tentara, bukan senjata Jaka.
- Background/Forest/forest_ground.png.png: tanah pada bagian hutan Bab 2.
- Ekspor menyertakan semua arsip animasi Jaka yang dipakai runtime.

## Sudah terhubung sebelumnya
- WAIFU .png sebagai Sari, Jaka, kucing, sesepuh, utusan, warga, dan penjaga.
- Arsip parry, heal, ulti; serangan bambu memakai tiga frame awal ulti.
- Animasi tentara berjalan, menembak, dan mati.
- Lapisan langit, gunung, desa, tanah Tegalrejo; langit dan pepohonan hutan; panorama karst pada ujung Bab 2.

## Tetap disimpan, belum dipasang
- pesan.png: pengguna akan membuat UI dan menentukan asetnya kemudian; placeholder dipertahankan.
- Peta tegal rejo.png: menunggu sistem peta yang masih direncanakan.
- Animasi BOSBELANDA (RAPID, FLINTSHOT, FINALSALVO) dan gambar bos lama: disimpan untuk bab penutup Magelang, sesuai keputusan pengguna.
- Latar permukiman terdampak: disimpan untuk Bab 4.
- Lima gambar peta bab dan gambar inventory/HUD baru: disimpan sebagai sumber; UI peta, teleport, inventory, dan upgrade masih menunggu rancangan serta aset final.
- Animasi kecapean: menunggu aturan stamina.
- Variasi pose WAIFU dan lembar NPC generik: belum ditetapkan pemetaan adegan/animasi; karakter cerita saat ini dipertahankan.
- Forest foreground: ilustrasi bingkai penuh; belum ditaruh di atas arena agar tidak menutup pijakan dan tentara.
- Panorama alternatif dan tanah.png: alternatif visual, bukan lapisan tambahan wajib pada latar yang sudah dipakai.
- Hasil finalnya.png: referensi komposisi HUD; implementasi menggunakan hati dan portrait terpisah agar jumlah hati dinamis.
- Animasi_Menembak.png milik Jaka tidak dipakai, sesuai keputusan bahwa Jaka menggunakan bambu runcing.
- Strip animasi lama dan ZIP duplikat tetap disimpan sebagai sumber; tidak ditumpuk dengan versi yang sudah aktif.

Sistem level, upgrade, stamina, dan teleport masih dalam perencanaan.

## Bab 3: Selarong
- `sky.png`, panorama tebing karst, gambar gua, dan potongan tanah Selarong kini membentuk latar Bab 3 yang dapat dimainkan.
- `Penjaga Selarong.png` dan `Pangeran Diponegoro.png` dipakai sebagai NPC dan potret dialog setengah badan.
- Bab 3 memakai animasi Jaka dan Taby yang sudah aktif. Tidak ada NPC warga berjalan atau patroli tentara di kawasan ini.

## Perbaikan jalan/lari
- A/D berjalan (160 px/detik); tahan Shift untuk lari (260 px/detik), lepas untuk berjalan kembali.
- Animasi jalan memakai arsip jalan_10framer yang diekstrak dari ZIP ulti. File sumber tetap disimpan.
- Potongan matte hitam besar dan serpihan terpisah pada animasi gerak dibersihkan saat runtime.
- Tes memeriksa kecepatan dan animasi sebelum, selama, dan sesudah menahan Shift; parkour diuji pada kecepatan lari.

## Migrasi folder — 13 November 2026
- Sumber aktif sekarang PNG dalam folder lari, jalan_10framer, lompat, tertembak, parry_10_frames, heal, dan ulti. Catatan ZIP di atas adalah riwayat; runtime tidak lagi membutuhkannya.
- Masing-masing animasi membaca sepuluh frame dengan urutan eksplisit agar konsisten saat diekspor.
- Parry memakai parry_01.png sampai parry_10.png pada 25 FPS (0,4 detik), tombol K dan cooldown 1 detik.
- Pembersihan bercak lari, mode tahan Shift, dan tiga frame serangan bambu dipertahankan.

## Taby dan warga desa
- Taby memakai sepuluh frame dari masing-masing Jalan.png, Lompat.png, dan Menjilat.png; gambar dipotong saat runtime. Jalan saat mengikuti Jaka, lompat saat Jaka melompat, menjilat ketika berhenti.
- Dua warga berjalan di Tegalrejo Bab 1 dan satu di tepi desa Bab 2 memakai lembar NPC laki-laki/perempuan. Hutan dan jalur patroli tidak memiliki warga berjalan.

## Pembaruan 24 November 2026 — arena dan atmosfer

- Buto Ijo dan Banaspati dapat dicoba melalui panel arena uji di menu. Potongan runtime: 350 PNG pada `assets/Generated/Bosses/`, pemetaan pada `data/boss_assets.json`.
- Banaspati memakai sembilan SFX WAV yang tersedia, platform runtuh, efek api, fase udara, spawn, stance break, dan mati. Spawn/stance break/mati Buto Ijo memiliki frame khusus; rincian ada pada `BOSS_TRIALS.md`.
- `assets/Background/Tanah Baru.png` menggantikan visual tanah di Bab 1–3 dan kedua arena. Lapisan tanah bawah diperpanjang tanpa meregangkan rumput. Collider dan celah parkour tetap sesuai rute.
- Arena memakai panorama bertumpuk dan sambungan mirror dengan overlap. Hutan jauh mengisi kedalaman di bawah platform, termasuk jurang Bab 2. Bab 3 mendapat lapisan tebing jauh untuk menutup bidang langit di bawah jurang.
- Debu langkah/lompat/mendarat, percikan, cincin parry/hit, serpihan platform, mote/kabut, serta bara dan jejak api dibuat dengan kode. Banaspati mendapat filter merah-oranye tipis; HUD boss dipindahkan ke bawah layar.
- Jaka versi terbaru menggunakan keris serta parry enam frame dengan stance lima, pemulihan satu per detik, gagal cooldown dua detik, dan stance break stun dua detik. Catatan parry sepuluh frame/cooldown satu detik di bagian migrasi adalah riwayat.

## Audit visual Selarong — 24 November 2026

- Aset hasil imagegen pada `assets/Generated/Selarong/`: teropong, pijakan kapur berlumut, batu pengamat yang bertumpu ke tanah, gubuk, dan panorama lembah.
- Teropong terpasang pada pos pengamat dengan petunjuk E; dialog pengamatan mengikuti fungsi alat itu. Gubuk menggantikan bentuk geometris sementara.
- Pijakan memakai permukaan lumut yang disejajarkan dengan collider. Panorama lembah sepenuhnya opaque, ubin mirror saling overlap, dan gambar mencapai bawah viewport di seluruh rute.
- Rincian audit, asal gambar, prompt, dan cara verifikasi: `SELARONG_VISUAL_AUDIT.md` dan `SELARONG_ASSET_PROMPTS.json`.

## Rumor malam dan chained attack

- Dua saksi diam muncul malam hari di lokasi aman: Penjaga sawah Tegalrejo untuk Buto Ijo, Penjaga singgah Bab 2 untuk Banaspati. Pertemuan dapat ditunda dan perjalanan dipulihkan setelah kembali dari boss.
- Serangan biasa memakai enam PNG baru `assets/Generated/Jaka/attack_01.png` sampai `attack_06.png`.
- Chained attack tiga hit sudah berfungsi: lembar Attack pengguna sebagai hit pertama, baris 2/3 dari spritesheet image_gen sebagai sambungan. Sumber `assets/Generated/Jaka/Concepts/chained-combo-sheet-v1.png` tetap disimpan; frame runtime dipotong terpisah. Klik kiri berulang untuk menyambung, klik kanan untuk parry, Shift untuk dash lalu lari saat ditahan.
- Prompt audio Headless Swordsman/Buto Ijo dan rencana pack 12 SFX tersedia di docs. Generasi SFX AI tertahan saldo fal habis; audio sumber yang sudah tersedia kini dikonversi dan terpasang sebagai cue combat dan musik boss.
