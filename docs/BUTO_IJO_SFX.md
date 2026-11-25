# Pack SFX Buto Ijo — 25 November 2026

Pengguna meminta melanjutkan generasi sendiri setelah fal tidak berhasil. Pack kini dibuat lewat sintesis audio pada kode, tanpa API, rekaman pihak lain, atau biaya fal. Ini pack sintetis sementara yang dapat diganti audio final nanti.

| Event | Isi suara | Durasi |
|---|---|---:|
| footstep_a / footstep_b | Dua variasi langkah raksasa, tanah dan kerikil | 0,72 / 0,76 dtk |
| light_swing / reverse_swing | Dua arah ayunan pedang besi | 0,48 / 0,55 dtk |
| heavy_windup | Desir berat dan getaran senjata saat ancang-ancang | 0,82 dtk |
| heavy_impact | Dentuman rendah, besi, batu dan puing | 1,55 dtk |
| parry | Benturan keris/pedang dengan dering pendek | 0,72 dtk |
| wave | Retakan tanah beruntun dan gemuruh | 1,85 dtk |
| pain | Geraman pendek sintetis | 0,68 dtk |
| break | Getaran pedang, geraman dan lutut menghantam tanah | 1,48 dtk |
| spawn | Napas dan raungan rendah, juga dipakai saat fase dua bangkit | 2,35 dtk |
| death | Geraman melemah, tubuh tumbang dan pedang jatuh | 2,65 dtk |

Semua sumber WAV: PCM16 mono 44,1 kHz, tidak loop. Godot mengimpor dengan kompresi audio bawaan, sehingga format resource runtime dapat berbeda dari PCM sumber. Audio arena bersifat positional, dibatasi 12 suara bersamaan, dengan volume/cooldown per event pada `data/buto_sfx.json`. Langkah memakai -22 dB, benturan -15 dB, parry -16 dB; suara lain -17 sampai -21 dB. Parry override mengikuti metadata mix yang sama, sementara parry di luar Buto mempertahankan cue biasa.

File runtime: `assets/Generated/Audio/ButoIjo/`. Generator: `tools/prepare_buto_sfx.py` (Python standard library). Seed tetap, sehingga output dapat disiapkan ulang secara identik. Tidak mengubah sumber audio pengguna atau musik yang sudah terpasang.

Jalankan dari root proyek:

    python tools/prepare_buto_sfx.py

Lalu impor proyek Godot. Generator memeriksa peak/headroom, RMS, offset DC dan fade keheningan di kedua ujung. Nilai ukur serta SHA256 tiap WAV: `BUTO_IJO_SFX_REPORT.json`. Semua sumber memiliki peak di bawah -1,5 dBFS. Timbre dan keseimbangan akhir masih perlu didengar saat playtest.

Preview gabungan 12 klip (urut tabel, jeda 0,55 detik) tersedia di `.godot/audio-review/buto-ijo-sfx-preview.wav`. Preview lebih keras daripada mix pertarungan; tidak termasuk paket runtime karena folder `.godot` diabaikan.

Tes `tests/buto_audio.tscn` memeriksa 12 stream terdecode, format mono/one-shot, data berbeda, metadata volume, pemicu langkah/light/reverse/heavy/pain/wave/stun/spawn/tumbang, pemilihan stream parry dari serangan nyata, rate limit, raungan fase dua, dan reset cooldown saat retry. Pack juga diperiksa dalam ekspor Web. Tes headless memeriksa routing dan resource; tidak menilai timbre lewat pendengaran.

Rencana prompt fal sebelumnya di `BUTO_IJO_SFX_PACK_PLAN.json` dipertahankan sebagai referensi; tidak ada job fal baru dijalankan untuk pack ini.

## Pemutaran dalam game

SFX sudah dipasang di arena menu maupun pertemuan cerita melalui loader/event boss yang sama. Voice ditempatkan pada container `World/BossSFX`, sehingga batas 12 suara dan pembersihan saat retry tetap menghitung voice yang namanya otomatis diubah Godot. Retry menghentikan dan melepas semua voice lama sebelum memutar spawn baru.

Tes native `tests/boss_audio_playback.tscn` dijalankan dengan renderer Compatibility dan driver audio Dummy: player audio benar-benar aktif, mixer merekam PCM yang berisi suara, voice selesai dibersihkan, 20 permintaan hanya membuat 12 voice, dan retry menyisakan satu spawn baru. Hasil `BOSS_AUDIO_PLAYBACK failures=0`; rekaman pemeriksaan di `.godot/audio-review/buto-live-mix.wav`. Driver Dummy menguji jalur mixer tanpa mengeluarkan suara ke speaker.
