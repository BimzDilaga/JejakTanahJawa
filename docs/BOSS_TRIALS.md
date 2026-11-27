# Arena uji Buto Ijo dan Banaspati

Pembaruan terbaru: [25 November 2026](UPDATE_2026_11_25.md), termasuk dua fase boss, Headless, komandan Bab 5, upgrade dan stamina.

## Cara mencoba

Jalankan `project.godot`, lalu pilih **Arena uji boss** pada menu utama dan tentukan salah satu dari empat boss. Akses latihan tetap tersedia di samping pertemuan cerita melalui rumor.

- A/D: jalan; tahan Shift: lari; Space: lompat.
- Klik kiri: combo keris; klik kanan: parry; H: heal; F: ultimate.
- Shift: dash saat ditekan, lari saat ditahan; S + Shift: dash mundur. Cooldown bersama 1 detik; tetap bisa terkena serangan.
- T: petunjuk pertarungan; Esc: jeda, ulang arena, atau kembali ke menu.
- Pertemuan lewat cerita juga tersedia saat malam: Penjaga sawah di Tegalrejo dan Penjaga singgah di tempat singgah Bab 2. Pilih mengikuti petunjuk, lalu kembali ke perjalanan yang sama setelah pertarungan. Lihat `NIGHT_ENCOUNTERS.md`.
- Setiap percobaan mendapat tiga bekal heal. Waktu dan stok heal sebelum masuk arena dipulihkan saat kembali ke menu.
- Arena dimulai malam. Jam otomatis dihentikan selama percobaan; siklus empat menit pada bab cerita tetap berlaku.
- HP dan stance boss berada di bawah layar, di area tanah. Petunjuk pertarungan ada di kiri atas.

## Atmosfer dan tanah

- Kedua arena serta Bab 1–3 memakai `assets/Background/Tanah Baru.png`. Rumput mengikuti skala sumber; hanya lapisan tanah bawah yang diulang secara terbalik agar memenuhi layar. Segmen berhenti di tepi jurang, sehingga tidak menutupi celah parkour.
- Panorama arena memakai ubin bergantian terbalik dengan sedikit overlap. Lapisan hutan jauh mengisi kedalaman jurang, sedangkan bawah hutan dekat memudar ke lapisan tersebut. Bab 2 memakai kedalaman hutan dan Bab 3 kedalaman tebing yang menjangkau bawah layar.
- Banaspati memakai bias merah-oranye tipis dan cahaya lembut di sekitar api boss. Parameter sementara `FIRE_STRENGTH = 0.58` di `scripts/boss_arena.gd`; filter berada di bawah UI dan tidak memengaruhi Buto Ijo/bab cerita.
- Debu mengembang saat langkah/lompat/mendarat, serpihan saat platform runtuh, percikan dan cincin flash saat hit/parry, serta jejak proyektil/bara Banaspati dibuat dengan kode.
- Batas per arena: 320 partikel combat, 12 flash singkat, dan 80 mote atmosfer. Pause menghentikan efek; retry menghapus partikel combat yang tersisa.

## Aturan yang mengikuti keputusan pengguna

- Parry Jaka 0,4 detik: tahan frame 1; frame 2–6 hanya saat sukses. Sukses tanpa cooldown; gagal cooldown 2 detik.
- Lima tangkisan sukses mengisi lima stance Jaka. Memaksakan tangkisan saat penuh menyebabkan stun 2 detik. Beban stance berkurang satu per detik tanpa parry.
- Heavy Buto Ijo tidak dapat ditangkis. **Mencoba parry heavy menambah dua beban stance dan tetap menerima damage.** Terkena heavy tanpa mencoba parry tidak menambah penalti stance ini. Jika tambahan beban melewati lima, stance break memberi stun dua detik.
- Stance Buto Ijo pecah: enam frame menuju pose berlutut, tahan frame terakhir **4 detik**, lalu reverse enam frame untuk bangkit.
- Banaspati: light dan proyektil kecil dapat ditangkis; pilar, gelombang lantai, dan api pengejar harus dihindari.
- Banaspati di udara kebal. Pemain bertahan dengan menghindari proyektil dan melewati **sembilan platform** terpisah setiap fase udara. Platform runtuh karena diinjak lama atau ditinggalkan di belakang.
- Tembok api besar memakai efek api yang sudah tersedia, disusun menjadi dinding setinggi 620 piksel. Dinding bergerak dari belakang, tetap mengikuti pemain yang melaju jauh, dan berhenti di belakang tanah aman.
- Menjelang akhir parkour, Banaspati mulai turun. Fase bertarung baru dimulai setelah boss selesai mendarat **dan pemain sudah berpijak di tanah aman**. Cooldown terbang dimulai ulang, lalu siklus tanah → udara/parkour → tanah berulang sampai boss dikalahkan.

## Nilai sementara untuk pengujian

Pengguna mengizinkan angka sementara yang mudah diubah. Sumber utama: `data/boss_tuning.json`.

| Pengaturan | Buto Ijo | Banaspati |
|---|---:|---:|
| HP per fase | 72 | 56 |
| Jumlah fase | 2 | 2 |
| Tahan tumbang antar fase | 2 dtk | 2 dtk |
| Tempo fase dua | 1,25× | 1,25× |
| Batas stance boss | 8 | 6 |
| Damage melee ringan | 1 | 1 |
| Damage melee berat | 2 | 2 |
| Beban stance boss dari parry | 2 | 2 |
| Beban stance boss dari hit | 1 | 1 |
| Kecepatan jalan/lari | 65 / 210 | 85 / 170 |
| Ancang-ancang ringan/berat | 0,55 / 0,95 dtk | 0,6 / 1 dtk |
| Recovery antarcombo | 0,75 dtk | 0,9 dtk |
| Tahan stance break | **4 dtk, keputusan pengguna** | 4 dtk, sementara |

Hazard/proyektil sementara memberi satu damage. Banaspati menembak setiap 1,15 detik dengan kecepatan 260. Platform mulai peringatan runtuh setelah kontak 1,8 detik, kemudian jatuh setelah peringatan 0,6 detik. Api belakang maju dengan kecepatan 140, dengan jarak maksimal 360 piksel di belakang pemain. Cooldown skill terbang sementara **16 detik** waktu pertarungan di tanah. Semua angka ini ada di `data/boss_tuning.json`.

Buto Ijo berganti antara light, heavy, combo 1, dan combo 3; combo 2 menutup jarak. Banaspati bergantian memakai combo 1 dan combo 3 di tanah, lalu fase udara sebagai combo 2 saat cooldown siap. Boss menyelesaikan serangan atau kesempatan stance break yang sedang berjalan sebelum terbang; pemicunya tidak lagi bergantung pada kehilangan HP.

Setiap bagian rute sepanjang 4.600 piksel, dengan parkour sekitar 2.340 piksel. Awalnya tersedia empat bagian (36 platform); bagian baru ditambahkan sebelum rute habis agar siklus dapat terus berulang. Seluruh platform, HP, cooldown, dan tembok api dipulihkan saat mencoba ulang.

## Hasil audit aset

- 350 PNG hasil potong di `assets/Generated/Bosses/`; 22 pemetaan animasi Buto Ijo dan 42 Banaspati, termasuk alias placeholder.
- `data/boss_assets.json` menyimpan urutan frame, sumber, dan penanda placeholder. Gambar sumber tidak ditimpa.
- Buto Ijo memakai jalan, light/heavy, ketiga combo, serta gelombang tanah milik pengguna.
- Banaspati memakai jalan, naik/melayang/turun, tiga kelompok serangan, spawn/stance/mati, retikel, proyektil, gelombang, pilar, api pengejar, dan platform retak milik pengguna.
- Sembilan WAV Banaspati digunakan untuk api, tembakan, terbang, benturan, stance break, retak/runtuh, roar, dan laugh. Empat MP3 dengan kontainer tidak cocok sudah dikonversi ke salinan WAV/OGG: dua cue combat dan dua musik boss, dengan musik loop yang berhenti saat kalah/menang dan dimulai lagi saat retry.
- Dua belas WAV Buto dibuat melalui kode dan dipasang pada langkah, serangan, windup/impact, parry, wave, pain, stance break, spawn/tumbang. Fase dua memicu raungan baru. Volume/cooldown per event di `data/buto_sfx.json`; rincian/preview di `BUTO_IJO_SFX.md`.
- Gambar Jaka bernama `Javanese-Inspired Pixel Art Warrior.png` juga ada di folder Buto Ijo. Gambar tersebut bukan animasi boss, sehingga tidak dipetakan sebagai Buto Ijo.
- Beberapa efek alternatif memiliki kotak panduan yang ikut tergambar. Efek tersebut tidak dipakai sebagai projectile/pilar aktif; runtime memakai pemetaan yang sudah diperiksa.

## Placeholder yang masih perlu diganti

- Spawn, stance break, dan mati Buto Ijo sudah memakai tiga lembar hasil generasi, masing-masing enam frame. Stance break tetap menahan pose berlutut 4 detik lalu reverse; animasi mati tidak lagi memutar pose serangan.
- Idle kedua boss menggunakan pose dari animasi yang tersedia; lari Banaspati sementara memakai jalan yang dipercepat.
- Beberapa gerakan pamungkas Banaspati masih memakai efek dan gerak sederhana sebagai pengujian, belum merupakan koreografi final.
- HUD boss, indikator heavy, batas arena, dan tata letak arena adalah placeholder yang dapat diganti.
- Jaka memakai serangan keris khusus, dua sambungan combo, idle yang diminta pengguna, serta animasi lompat/stun/mati dan dash maju/mundur. UI masih dapat diganti aset final.

## Pengujian

`tests/boss_trial_smoke.tscn` memeriksa akses menu, spawn, parry melee nyata, penalti heavy, overflow stance, berlutut 4 detik dan reverse, hit keris/charge ultimate, kematian/victory, percobaan ulang, cooldown terbang berulang, fase udara kebal, penyeberangan sembilan platform dengan input lompat/lari, tembok api pengejar, mendarat di tanah aman, perpanjangan rute, runtuhnya collision, parry projectile, pilar yang tidak bisa ditangkis, menghindari gelombang dengan lompat, pause, posisi bar, filter api khusus Banaspati, dan jumlah mote tetap.

Jalankan dengan Godot:

    --headless --fixed-fps 60 --path . res://tests/boss_trial_smoke.tscn

Untuk screenshot dengan renderer aktif, hilangkan `--headless`, lalu tambahkan:

    -- --screenshots=<folder>

Uji manusia masih diperlukan untuk menilai keseimbangan. Pertemuan cerita melalui rumor malam sudah terhubung di Bab 1, 2 dan 4; komandan berada di Bab 5. Arena latihan menu tidak menghitung kemenangan cerita atau membuka syarat ending. Lihat `PERSISTENCE_AND_PRESENTATION.md` untuk save, teleport, Headless dan presentasi terbaru.
