# Save, peta, audio, dan presentasi — 25 November 2026

## Perjalanan tersimpan

Menu **Lanjutkan perjalanan** membuka progres terakhir. Permainan menyimpan perubahan misi, checkpoint, upgrade, poin, bekal, kemenangan boss cerita, ending, waktu, dan keadaan Jaka. Autosave berkala setiap 15 detik waktu aktif; tombol **Simpan perjalanan** tersedia di peta. Slot memakai JSON ber-checksum dengan cadangan revisi valid sebelumnya. Memulai perjalanan baru meminta konfirmasi sebelum mengganti slot.

Tekan **M** atau tombol **Peta** dari HUD/menu. Selesaikan bab untuk membuka daerah berikutnya. Teleport menuju gubuk di daerah terbuka, mempertahankan tujuan dan upgrade sambil mengembalikan patroli biasa. Teleport tidak memulihkan HP secara gratis. Daerah yang sudah selesai tetap dapat dikunjungi untuk mencari urban boss yang terlewat. Pilihan ending juga menyediakan akses peta.

Arena latihan menu terpisah dari progres cerita. Bekal latihan dan kemenangan latihan tidak masuk ke slot perjalanan. Pertemuan melalui rumor menyimpan perjalanan sebelum masuk; kembali mengembalikan posisi, misi, waktu dan bekal asal. Menyimpan di tengah arena mencatat perjalanan asal tersebut.

Web menyimpan data di penyimpanan situs browser. Uji Chrome dengan profil QA terpisah berhasil: beli hati menjadi empat dengan sisa 598 poin, tutup proses browser, buka lagi dan lanjutkan; empat hati dan 598 poin tetap ada. Menghapus data situs/profil menghapus slot web. Godot menjelaskan persyaratan IndexedDB dan keterbatasan mode privat di [dokumentasi ekspor Web](https://docs.godotengine.org/en/4.5/tutorials/export/exporting_for_web.html#using-cookies).

## Headless Swordsman

Lima belas lembar dari referensi desain pengguna menyediakan idle/jalan/lari/light/heavy/lunge/stagger/mati serta spawn, hurt, backhand, low spin, vanish, leap slam dan ultimate. Sumber mentah disimpan terpisah dari potongan runtime.

Tiga pola berisi 5/4/5 gerakan. Smoke step mengunci sasaran saat ancang-ancang; tebasan rendah dapat dilompati; lompatan memiliki kontak tertunda saat mendarat. Kebal hanya selama smoke step, lalu terbuka untuk balasan. Stance break tetap berlutut empat detik sebelum reverse.

Sesuai koreksi terbaru, skala visual **0,62** dari ukuran persiapan: tinggi idle sekitar 1,2 kali Jaka termasuk asap. Kaki tetap berada di tanah; collider dan jangkauan serangan disesuaikan. HP 64/satu fase dan tuning combat masih sementara. Gambar asli dari ChatGPT Library belum berhasil diambil; versi generasi berbasis desain chat dipakai tanpa menimpa sumber pengguna.

## Gambar menu dan ending

`assets/Generated/Menu/title-keyart-v1.png` adalah satu ilustrasi hasil image_gen dari referensi: Jaka di depan/tengah, Diponegoro, Sari, Lasmi, latar Tegalrejo senja serta petunjuk tiga legenda di kejauhan. Karakter dan latar tidak disusun memakai gambar kode. UI diletakkan di sisi kiri yang gelap; empat arena latihan berada dalam pilihan terpisah.

Judul memakai font Cormorant Garamond dari [Google Fonts](https://github.com/google/fonts/tree/main/ofl/cormorantgaramond), berlisensi SIL OFL. Font serta lisensinya disertakan agar browser tidak bergantung pada font sistem. Menu memiliki pengaturan volume utama, musik, SFX dan lingkungan; pilihan disimpan terpisah dari progres.

Ketiga ending memiliki ilustrasi sendiri dan epilog berparagraf. E/Space melanjutkan; Esc atau tombol lewati menuju kartu ending penuh. Persyaratan dan hasil sejarah tetap mengikuti `UPDATE_2026_11_25.md`. Animasi ultimate Jaka diganti delapan frame transparan dengan baseline konsisten; sumber RGB sebelumnya tetap utuh.

## Audio

Dua belas SFX Headless, tiga musik original bernuansa perkusi perunggu, ambience jangkrik/katak/angin malam dan angin siang dibuat secara sintetis dengan `tools/prepare_world_audio.py`. Musik khusus dipasang pada Headless dan komandan; epilog/menu memakai komposisi ketiga. Ini komposisi baru yang terinspirasi gamelan, bukan rekonstruksi laras atau rekaman tradisional. Musik pengguna untuk Buto/Banaspati tetap dipakai.

Pack Buto berisi 12 SFX sintetis, Banaspati sembilan SFX sumber pengguna, Jaka tiga ayunan keris sementara. Tidak ada job fal baru. Keempat bus audio mengikuti slider, jeda, transisi dan pembersihan arena. Mixer native telah merekam SFX Buto yang benar-benar diputar, termasuk pemeriksaan batas voice dan retry.

## Verifikasi dan batas praktis

Perangkat sentuh menampilkan 11 tombol aksi, jeda, dan fullscreen; dialog memakai tombol Lanjut. TouchScreenButton mendukung multitouch untuk gerak + dash + lompat. Windows memiliki tombol fullscreen di menu dan F11; browser meminta fullscreen melalui klik pengguna. Uji perangkat Android fisik tetap belum dilakukan.

Tujuh belas suite menguji bab, combat, parry, platform Banaspati, fase boss, rumor, upgrade, ending, save/restore, menu, audio dan multitouch. Tes tambahan menulis/membaca slot dalam dua proses Godot yang berbeda. Screenshot renderer memeriksa framing menu, peta terkunci/terbuka, ukuran Headless, ultimate dan ketiga epilog. Versi Web diuji lewat proses Chrome terpisah untuk persistensi; paket ekspor juga diperiksa untuk aset runtime dan pengecualian sumber mentah.

Angka damage, tempo dan koreografi tetap perlu playtest manusia. UI gubuk/peta/combat masih dapat diganti dengan aset final pengguna. Berkas Library Headless tetap dapat menggantikan versi sekarang saat tersedia.
