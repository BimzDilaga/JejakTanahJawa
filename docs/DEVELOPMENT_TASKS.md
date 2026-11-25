# Daftar pekerjaan — 23 November 2026

Status terkini menggantikan daftar lama di bawah: [Pembaruan 25 November 2026](UPDATE_2026_11_25.md) dan [Save dan presentasi](PERSISTENCE_AND_PRESENTATION.md). Lima bab/ending bergambar, upgrade/stamina, save/load, teleport progresif, menu ilustrasi empat karakter, musik/ambience khusus dan dua belas SFX per Buto/Headless sudah dibuat. Headless memiliki 15 lembar dan ukuran sekitar 1,2 kali Jaka. Space tetap dapat memulai lompat saat dash masih berpijak. Lanjutan utama: art Library asli, UI final pengguna dan playtest keseimbangan/timbre. Daftar bertanggal 23 November di bawah dipertahankan sebagai riwayat.

Dasar: pemeriksaan folder dan kode proyek, lalu keputusan pengguna di chat. Pembaruan 24 November: arena uji Buto Ijo/Banaspati sudah ditambahkan sesuai persetujuan pengguna; rincian dan nilai sementara ada di `BOSS_TRIALS.md`.

## Selesai pada pembaruan Jaka

- [x] Hubungkan tujuh lembar dari `assets/Animasi Karakter/Jaka New/`.
- [x] Siapkan 56 PNG frame gameplay terpisah beserta potret dialog di `assets/Generated/Jaka/`, termasuk idle dari `Javanese-Inspired Pixel Art Warrior.png` dan enam frame Attack terbaru; sumber tidak ditimpa.
- [x] Jalan 8 frame, lari 8, heal 8, kena hit 3, parry 6, ultimate 8, efek ultimate 8.
- [x] Tahan Shift untuk berlari, lepas untuk berjalan. Gunakan filter nearest untuk sprite Jaka.
- [x] Pakai keris; serangan biasa kini memakai enam frame dari lembar Attack terbaru, dengan frame kontak disamakan dengan event damage.
- [x] Parry K: tahan frame pertama selama jendela 0,4 detik. Mainkan frame 2–6 hanya setelah tangkisan sukses.
- [x] Flash putih pada awal pose tangkis dan saat sukses, cepat memudar, disertai percikan.
- [x] Sukses tidak memberikan cooldown; jendela selesai setelah satu serangan ditangkis. Tangkisan berikutnya membutuhkan tekan K lagi.
- [x] Gagal menangkap serangan memulai cooldown 2 detik setelah jendela selesai.
- [x] Setiap sukses menambah 1 stance. Sukses kelima aman; mencoba parry pada 5/5 menyebabkan stun 2 detik.
- [x] Stance pulih satu poin setiap detik tanpa parry. Percobaan parry memulai ulang hitungan pemulihan. Pemulihan tetap berjalan selama stun; tidak ada reset penuh instan.
- [x] HUD placeholder lima slot dengan peringatan pada 4/5 dan 5/5, cooldown, dan waktu stun.
- [x] Debu lompat, langkah, pendaratan; percikan benturan/parry; jejak ultimate. Pembaruan atmosfer: 320 partikel combat dan 12 flash, dengan debu mengembang dan serpihan.
- [x] Pertahankan heal satu hati dan ultimate dash yang mengisi dari hit ke tentara.
- [x] Tambahkan pengujian parry, stance, stun, proyektil nyata, kontrol Shift, dan debu pendaratan.

## Berikutnya: menyelesaikan visual Jaka

- [x] Ganti placeholder lompat dengan enam frame khusus yang cocok desain terbaru.
- [x] Ganti serangan biasa sementara dengan tebasan keris khusus dari `Jaka New/Attack`.
- [x] Siapkan enam frame stance break/stun dan enam frame kalah Jaka. Stance break bangkit melalui reverse dalam durasi stun 2 detik.
- [x] Pasang combo tiga serangan, buffer klik lanjutan, pembatalan melalui parry/dash, serta hit sekali per ayunan.
- [x] Dash pendek maju/mundur dengan animasi khusus, durasi 0,18 detik, kecepatan sementara 640 px/detik, cooldown bersama 1 detik; tanpa kekebalan/damage.
- [x] Kontrol terbaru: klik kiri serang, klik kanan parry, Shift dash sekali saat ditekan lalu lari jika ditahan, S+Shift dash mundur.
- [x] Idle memakai gambar berdiri `Javanese-Inspired Pixel Art Warrior.png` sesuai permintaan terbaru. Pose awal ultimate tidak lagi dipakai untuk idle.
- [x] Ganti ultimate RGB dengan delapan frame transparan yang bersih; sumber asli tetap disimpan.
- [ ] Playtest langsung untuk menilai rasa tangkisan dan kenyamanan jeda antarserangan.

## Berikutnya: audio

Empat file berakhiran `.mp3` ternyata memiliki header kontainer ISO BMFF (`ftypdash`), sehingga decoder MP3 Godot menolaknya:

- `assets/SFX & Soundtrack/Mechanique game/Parry.mp3`
- `assets/SFX & Soundtrack/Mechanique game/Boss Stance Break.mp3`
- Soundtrack Banaspati: `Donkgedank - Fight Fire (Royalty Free Epic Backsound Nusantara).mp3`
- Soundtrack Buto Ijo: `Donkgedank - Akusara (Epic Kolosal Backsound) Royalty Free.mp3`

- [x] Konversikan empat sumber ISO BMFF menjadi dua WAV dan dua OGG; sumber tetap disimpan. Tool: `tools/prepare_combat_audio.ps1`.
- [x] Pasang SFX parry sukses dan stance break boss pada event combat.
- [x] Pasang musik loop per arena, pause dan stop/retry mengikuti pertarungan.
- [ ] Tambahkan ambience malam khusus; musik boss bukan pengganti ambience dunia.
- [x] Permintaan terbaru mengganti jalur ini dengan generasi sendiri: 12 SFX Buto sintetis sudah terpasang. Generator, preview, dan hasil ukur di `BUTO_IJO_SFX.md`. Fal tidak dipanggil ulang.

Audio runtime berada di `assets/Generated/Audio/` dan ikut paket. Sumber audio dan lembar gambar mentah tetap tersedia di proyek, dikecualikan dari paket.

## Berikutnya: Buto Ijo

Desain, jalan, light/heavy, projectile gelombang tanah, dan tiga kelompok chained attack sudah terhubung. Penjaga sawah di Tegalrejo membuka pertemuan melalui rumor saat malam; arena uji dari menu tetap tersedia.

- [x] Potong dan petakan frame serta fase ancang-ancang, hit, dan recovery untuk arena uji.
- [x] Penanda merah untuk serangan berat yang tidak bisa di-parry.
- [x] Stance boss dan enam frame khusus menuju pose berlutut.
- [x] Tahan frame berlutut terakhir 4 detik, lalu reverse enam frame untuk berdiri.
- [x] Generate dan potong enam frame khusus untuk spawn, mati, dan stance break di `assets/Generated/Bosses/`; sumber versi pertama disimpan pada `Sources/`.
- [x] Combo kedua sebagai penutup jarak dan combo ketiga sebagai ultimate.
- [x] Pengguna memastikan: mencoba parry heavy menambah 2 beban stance Jaka dan tetap terkena damage; melebihi batas menyebabkan stun 2 detik.
- [x] Pengguna mengizinkan HP/damage/stance sementara yang mudah diubah di `data/boss_tuning.json`.
- [ ] Finalkan keseimbangan melalui playtest.

## Berikutnya: Banaspati

Folder sudah memiliki jalan di tanah, animasi terbang, tiga kelompok chained attack, projectile/penanda, platform runtuh, spawn, stance, dan mati.

- [x] Petakan gambar gerak, terbang, serangan, stance/spawn/mati, platform, dan efek yang dipakai.
- [x] Fase tanah dapat diserang, fase naik/terbang/turun kebal, lalu terbuka lagi setelah mendarat.
- [x] Sembilan platform per bagian rute (pembaruan permintaan terbaru), runtuh saat diinjak lama atau ditinggalkan di belakang. Tembok api besar menggiring pemain sampai tanah aman.
- [x] Cooldown terbang sementara 16 detik, dimulai ulang setelah mendarat. Fase udara/parkour berulang, dengan rute yang diperpanjang saat dibutuhkan.
- [x] Proyektil dengan penanda dan rute parkour yang telah diuji memakai input jalan/lari/lompat.
- [x] Pengguna menyetujui angka runtuh sementara dan parry light/proyektil kecil; pilar serta lantai tidak bisa di-parry. Retry memulihkan seluruh rute.
- [x] Sembilan SFX WAV yang tersedia digunakan untuk arena Banaspati.
- [ ] Finalkan keseimbangan dan koreografi ultimate; beberapa gerakan masih sederhana.

Ada satu file jalan Banaspati juga di folder Buto Ijo. Periksa pemetaan duplikatnya; jangan hapus sumber tanpa alasan.

## Berikutnya: Headless Swordsman Belanda

- [ ] Masukkan desain yang diberikan di chat; belum ditemukan folder animasi boss ini dalam inventaris `Boss Urban Legend` saat pemeriksaan.
- [x] Siapkan 15 lembar gerak, serangan, tiga combo, stance break, spawn dan mati dari desain chat.
- [x] Pertemuan di Desa Terdampak malam hari, dengan smoke step, tebasan rendah dan leap slam.

Menggantikan Wewe Gombel. Genderuwo hanya tambahan jika waktu cukup. Bos Belanda RAPID/FLINTSHOT/FINALSALVO tetap terpisah untuk bab penutup.

## Berikutnya: dunia dan rumor

- [x] Siklus pagi–siang–sore–malam dengan filter transisi halus di Bab 1–3. HUD dan dialog tidak ikut diwarnai.
- [x] Durasi sesuai jawaban pengguna: satu siklus 4 menit waktu aktif, sekitar satu menit per fase. Awal sore mengikuti prolog; waktu diteruskan antar bab dan berhenti saat menu/dialog/pause/kalah/akhir bab.
- [x] F6 khusus debug/editor untuk pratinjau fase berikutnya; tes otomatis dan screenshot empat fase di ketiga bab.
- [x] Pasang matahari/bulan serta bintang melalui kode, sesuai izin aset sementara.
- [x] Pasang saksi rumor malam Buto Ijo di Tegalrejo dan Banaspati di tempat singgah Bab 2, dengan pilihan masuk/tunda serta kembali ke perjalanan yang sama.
- [x] Rumor membuka petunjuk investigasi: seretan pedang Buto Ijo di Tegalrejo dan jejak bara Banaspati di tepi jurang Bab 2. Periksa jejak lalu pilih masuk/tunda. Headless Swordsman belum memiliki pertemuan runtime.
- [x] Urban boss opsional untuk alur biasa; ketiganya wajib untuk ending rahasia bersama kemenangan komandan.
- [x] Tambah mote/kabut tipis, bara Banaspati, jejak proyektil, debu boss, dan serpihan platform. Filter merah-oranye Banaspati tidak mewarnai UI.
- [x] Gunakan `Tanah Baru.png` di Bab 1–3 dan arena, isi kedalaman hutan tanpa bidang kosong, serta pindahkan bar boss ke bawah.

## Perubahan lingkup setelah catatan awal

Pengguna kemudian mengizinkan upgrade heart/attack/speed/stamina, gubuk tiap bab, peta/teleport, reset, Bab 4–5 dan tiga ending. Semuanya sudah diterapkan; aturan dan tes terkini tercatat pada dua dokumen di awal daftar ini. Art Headless asli dari Library belum tersedia, sehingga versi generasi dari desain chat tetap dipakai.
