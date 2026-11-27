# Combat, boss, audio, dan cerita — 24 November 2026

Aturan terbaru 25 November ada di [UPDATE_2026_11_25.md](UPDATE_2026_11_25.md): lima bab, tiga ending, upgrade/stamina, dua fase boss, dan aset final boss. Ringkasan di bawah mempertahankan rincian combat sebelumnya.

## Kontrol terkini

| Aksi | Tombol |
|---|---|
| Jalan | A/D atau panah |
| Dash maju | Tekan Shift |
| Lari | Tahan Shift setelah dash, bersama arah gerak |
| Dash mundur tanpa berbalik | S + Shift |
| Lompat | Space |
| Combo keris | Klik kiri berulang |
| Parry | Klik kanan |
| Heal / ulti | H / F |
| Bicara / catatan / jeda | E / T / Esc |

Ulti aktif kebal damage dan otomatis menangkis serangan masuk tanpa menambah stance Jaka atau cooldown parry manual. Hit, knockback dan aksi combat lain tidak memutusnya; satu target hanya terkena damage/stun sekali. Kekebalan berakhir tepat saat durasi ulti selesai. Aturan dash gerak biasa tidak berubah: hit tetap dapat membatalkannya.

Klik yang diterima tombol UI tidak masuk ke combat. Menahan klik kiri tidak menghasilkan serangan otomatis. Melepas Shift kembali berjalan. Dash hanya terjadi saat Shift baru ditekan, sehingga tidak berulang selama ditahan.

## Combat Jaka

- Hit pertama memakai Attack terbaru milik pengguna. Hit kedua/ketiga memakai frame hasil generasi yang dipotong dan dinormalisasi.
- Durasi tiga ayunan sementara: 0,34 / 0,38 / 0,44 detik. Kontak: 0,15 / 0,17 / 0,22 detik. Damage dasar 1 ditambah upgrade attack, jangkauan 145, satu hit per target per ayunan. Stamina dan peningkatan atribut di `data/progression.json`.
- Klik baru setelah 0,1 detik dalam ayunan mengantre satu sambungan. Tidak dapat melewati tiga hit. Parry, dash, damage, dialog, stun dan retry menghapus antrean.
- Dash 0,18 detik × 640 px/detik, sekitar 115 piksel. Cooldown 1 detik dihitung sejak mulai dan dipakai bersama maju/mundur. Space dapat memulai lompat saat dash maju/mundur masih berpijak, mempertahankan dorongan horizontal dan memakai stamina lompat biasa. Tidak menambah double jump. Dash tidak memberi damage, charge ulti, atau kekebalan. Damage menginterupsi dash; collider dan gravitasi tetap berlaku.
- Lompat, stun, kalah, dash maju/mundur memiliki masing-masing enam frame. Stun Jaka tetap total 2 detik, berlutut lalu reverse untuk bangkit. Kalah menahan frame terakhir.
- Buto Ijo memiliki enam frame asli hasil generasi untuk spawn, stance break, dan mati. Berlutut 4 detik lalu reverse tetap mengikuti aturan pengguna.

## Aset dan audio

- Art dibuat melalui built-in image_gen dengan referensi karakter asli. Sumber tidak ditimpa. Raw Jaka: `assets/Generated/Jaka/Concepts/`; raw Buto: `assets/Generated/Bosses/Sources/`. Frame runtime berada satu folder di atasnya.
- Prompt dash lengkap: `JAKA_DASH_ASSET_PROMPTS.json`; spesifikasi aset tambahan: `COMBAT_POLISH_ASSETS.json`; prompt combo: `JAKA_CHAINED_ATTACK_PROMPT.md`.
- Siapkan ulang hasil cutting: Godot `--headless --path . --script res://tools/prepare_combat_polish.gd`, lalu impor ulang proyek. Tool persiapan penuh Jaka/boss juga memanggil persiapan art tambahan ini.
- Dua sumber audio mekanik dikonversi menjadi WAV mono 44,1 kHz; dua musik menjadi OGG Vorbis stereo 44,1 kHz. Sumber dengan ekstensi `.mp3` yang sebenarnya ISO BMFF tetap utuh. Tool reproduksi: `tools/prepare_combat_audio.ps1 -Ffmpeg <path-executable>`.
- Cue parry: sukses saja, pool maksimal empat voice. Cue stance break boss: ketika mulai berlutut. Musik per arena loop, dijeda bersama gameplay, berhenti saat kalah/menang, mulai ulang saat retry. Node audio dibersihkan bersama scene/retry.
- Musik yang disediakan: Buto Ijo memakai Donkgedank — Akusara; Banaspati memakai Donkgedank — Fight Fire. Atas permintaan terbaru, Buto kini memakai 12 SFX sintetis lewat kode; rincian pada `BUTO_IJO_SFX.md`. Tidak ada job fal baru untuk pengganti ini.

## Cerita dan batas pekerjaan

Rumor malam membuka petunjuk yang diperiksa terpisah: seretan pedang Buto Ijo, jejak bara Banaspati dan petunjuk Headless di Desa Terdampak. Memilih mendekati sumber membuka arena. Kembali memulihkan perjalanan yang sama; hasil boss disimpan permanen bersama slot. Rincian: `NIGHT_ENCOUNTERS.md`.

Save/load, teleport, tujuh lembar gerak tambahan Headless, audio khusus, ambience malam, ultimate transparan, tiga epilog bergambar dan menu ilustrasi sudah masuk; rincian `PERSISTENCE_AND_PRESENTATION.md`. Art asli Headless dari Library dan keseimbangan akhir melalui playtest masih terbuka. Ketiga urban boss opsional untuk alur biasa, wajib untuk ending rahasia; komandan wajib untuk ketiga ending.

## Verifikasi

Tes `combat_chain_dash`, `jaka_combat`, `boss_trial_smoke`, `night_encounters`, ketiga chapter smoke, `day_night_smoke`, dan `selarong_visual_audit` memeriksa runtime. `combat_polish_review` menangkap cutting/screenshot dengan renderer aktif. Paket ekspor diperiksa terpisah agar audio, frame dan data investigasi tersedia tanpa sumber mentah.
