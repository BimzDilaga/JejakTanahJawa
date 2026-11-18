# Status integrasi aset — 18 November 2026

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
