"""Deterministic, original procedural Buto Ijo SFX. Standard library only; no API calls.

Layered soil/stone transients, filtered air, inharmonic metal and a rough synthetic
creature voice. Generated WAVs are mono so Godot can position them in the arena.
"""
from array import array
import hashlib
import json
import math
from pathlib import Path
import random
import sys
import wave

PROJECT = Path(__file__).resolve().parents[1]
ROOT = PROJECT / "assets/Generated/Audio/ButoIjo"
RATE = 44100
TAU = 2 * math.pi


class Sound:
    def __init__(self, seconds, seed):
        self.samples = [0.0] * round(seconds * RATE)
        self.random = random.Random(seed)

    def region(self, start, seconds):
        offset = round(start * RATE)
        return offset, max(0, min(round(seconds * RATE), len(self.samples) - offset))

    def thump(self, start, amplitude, frequency=70, decay=0.18):
        offset, count = self.region(start, decay * 9)
        phase = 0.0
        for i in range(count):
            t = i / RATE
            phase += TAU * frequency * (1 + 0.6 * math.exp(-t * 24)) / RATE
            envelope = (1 - math.exp(-t * 850)) * math.exp(-t / decay)
            self.samples[offset + i] += amplitude * envelope * (
                math.sin(phase) + 0.2 * math.sin(phase * 1.63))

    def grit(self, start, seconds, amplitude, decay=0.15, low=150, high=5000):
        """Band-passed noise with a short attack and exponential decay."""
        offset, count = self.region(start, seconds)
        slow = fast = 0.0
        slow_a = 1 - math.exp(-TAU * low / RATE)
        fast_a = 1 - math.exp(-TAU * high / RATE)
        for i in range(count):
            t = i / RATE
            noise = self.random.uniform(-1, 1)
            slow += slow_a * (noise - slow)
            fast += fast_a * (noise - fast)
            envelope = (1 - math.exp(-t * 1600)) * math.exp(-t / decay)
            self.samples[offset + i] += amplitude * (fast - slow) * envelope

    def metal(self, start, amplitude, root=580, decay=0.3):
        """Non-harmonic blade modes rather than a musical bell/chord."""
        offset, count = self.region(start, decay * 8)
        modes = [(1.0, 0.40), (1.47, 0.26), (2.13, 0.16), (3.71, 0.09), (5.27, 0.04)]
        for ratio, weight in modes:
            phase = self.random.uniform(0, TAU)
            frequency = root * ratio
            for i in range(count):
                t = i / RATE
                envelope = min(1, t / 0.0015) * math.exp(-t / (decay / math.sqrt(ratio)))
                self.samples[offset + i] += amplitude * weight * math.sin(TAU * frequency * t + phase) * envelope

    def whoosh(self, start, seconds, amplitude, reverse=False, heavy=False):
        offset, count = self.region(start, seconds)
        slow = fast = phase = 0.0
        for i in range(count):
            p = i / max(1, count - 1)
            noise = self.random.uniform(-1, 1)
            cutoff = (1500 if heavy else 3000) + 3000 * math.sin(math.pi * p) ** 2
            fast += (1 - math.exp(-TAU * cutoff / RATE)) * (noise - fast)
            slow += 0.04 * (noise - slow)
            center = 0.57 if reverse else 0.43
            envelope = math.exp(-((p - center) / 0.20) ** 2) * math.sin(math.pi * p)
            phase += TAU * ((380 if heavy else 900) + 1400 * (1 - p if reverse else p)) / RATE
            self.samples[offset + i] += amplitude * envelope * ((fast - slow) * 0.75 + math.sin(phase) * 0.025)

    def creature(self, start, seconds, amplitude, style="roar"):
        """Breath-driven glottal pulses + broad formants; no words or recordings."""
        offset, count = self.region(start, seconds)
        phase = slow = fast = 0.0
        jitter = 0.0
        for i in range(count):
            t = i / RATE
            p = i / max(1, count - 1)
            noise = self.random.uniform(-1, 1)
            jitter = jitter * 0.995 + noise * 0.005
            slow += 0.045 * (noise - slow)
            fast += 0.32 * (noise - fast)
            if style == "pain":
                f0 = 67 - 22 * p + 4 * math.sin(9 * t)
                envelope = math.sin(math.pi * p) ** 0.75 * math.exp(-p * 1.5)
            elif style == "death":
                f0 = 60 - 27 * p + 3 * math.sin(11 * t)
                envelope = math.sin(math.pi * p) ** 0.8 * (1 - p) ** 0.7
            else:
                f0 = 45 + 18 * math.sin(math.pi * p) + 3 * math.sin(TAU * 4.7 * t)
                envelope = math.sin(math.pi * p) ** 0.7
            phase += TAU * f0 * (1 + jitter * 0.12) / RATE
            voiced = 0.0
            for harmonic in range(1, 13):
                frequency = harmonic * f0
                formant = (0.5 * math.exp(-((frequency - 240) / 140) ** 2)
                           + 0.4 * math.exp(-((frequency - 620) / 220) ** 2)
                           + 0.2 * math.exp(-((frequency - 1100) / 300) ** 2))
                voiced += math.sin(phase * harmonic) * (0.12 + formant) / harmonic
            rough = 0.77 + 0.23 * math.sin(phase * 0.51 + jitter * 5)
            breath = (fast - slow) * (0.18 + 0.25 * p)
            self.samples[offset + i] += amplitude * envelope * (voiced * rough + breath)

    def pebbles(self, start, count=8, spread=0.55, amplitude=0.20):
        for i in range(count):
            at = start + spread * (i / max(1, count - 1)) ** 1.4
            level = amplitude * self.random.uniform(0.4, 1) * (1 - i / (count + 2))
            self.grit(at, 0.07, level, 0.012, 500, 9500)
            self.metal(at, level * 0.23, self.random.uniform(1100, 2400), 0.025)

    def finish(self, rms_target, peak_target=0.84, room=False):
        if room:
            dry = self.samples[:]
            for seconds, gain in [(0.043, 0.08), (0.097, 0.05), (0.157, 0.025)]:
                delay = round(RATE * seconds)
                for i in range(delay, len(dry)):
                    self.samples[i] += dry[i - delay] * gain
        previous = filtered = 0.0
        values = []
        edges = []
        for i, value in enumerate(self.samples):
            # DC blocker, gentle saturation and edge fades keep imports click-free.
            filtered = value - previous + 0.997 * filtered
            previous = value
            edge = min(1, i / (RATE * 0.002), (len(self.samples) - 1 - i) / (RATE * 0.025))
            edges.append(max(0, edge))
            values.append(math.tanh(filtered * 1.1) * max(0, edge))
        dc = sum(values) / sum(edges)
        values = [value - dc * edge for value, edge in zip(values, edges)]
        peak = max(map(abs, values)) or 1
        rms = math.sqrt(sum(v * v for v in values) / len(values)) or 1
        gain = min(peak_target / peak, rms_target / rms)
        return array("h", (round(v * gain * 32767) for v in values))


def make_clip(key):
    spec = {
        "footstep_a": (0.72, 182501, 0.13), "footstep_b": (0.76, 182502, 0.13),
        "light_swing": (0.48, 182503, 0.12), "reverse_swing": (0.55, 182504, 0.12),
        "heavy_windup": (0.82, 182505, 0.12), "heavy_impact": (1.55, 182506, 0.18),
        "parry": (0.72, 182507, 0.12), "wave": (1.85, 182508, 0.16),
        "pain": (0.68, 182509, 0.17), "break": (1.48, 182510, 0.17),
        "spawn": (2.35, 182511, 0.20), "death": (2.65, 182512, 0.17),
    }
    seconds, seed, rms = spec[key]
    sound = Sound(seconds, seed)
    if key.startswith("footstep"):
        sound.thump(0, 1.2, 62 if key.endswith("a") else 54, 0.075)
        sound.grit(0, 0.28, 0.5, 0.065, 140, 4600)
        sound.thump(0.035, 0.33, 98, 0.055)
        sound.pebbles(0.045, 6, 0.25, 0.13)
    elif key in ("light_swing", "reverse_swing"):
        reverse = key == "reverse_swing"
        sound.whoosh(0, 0.40 if not reverse else 0.47, 1.1, reverse)
        sound.metal(0.17 if not reverse else 0.23, 0.09, 820 if not reverse else 690, 0.06)
    elif key == "heavy_windup":
        sound.whoosh(0, 0.78, 0.8, True, True)
        sound.grit(0.04, 0.6, 0.24, 0.32, 120, 1600)
        sound.metal(0.12, 0.12, 280, 0.24)
    elif key == "heavy_impact":
        sound.thump(0, 1.5, 49, 0.17)
        sound.thump(0.012, 0.6, 112, 0.095)
        sound.grit(0, 0.7, 0.9, 0.13, 50, 9000)
        sound.metal(0.003, 0.85, 470, 0.19)
        sound.pebbles(0.06, 15, 0.85, 0.32)
    elif key == "parry":
        sound.grit(0, 0.13, 0.7, 0.019, 900, 13000)
        sound.metal(0.001, 1.1, 1130, 0.19)
        sound.metal(0.016, 0.34, 670, 0.13)
    elif key == "wave":
        sound.thump(0, 0.8, 43, 0.20)
        for i in range(8):
            at = i * 0.11
            level = (1 - i / 10) * 0.75
            sound.thump(at, level, 54 - i * 2.3, 0.14)
            sound.grit(at, 0.38, level * 0.6, 0.07, 50, 3700)
        sound.pebbles(0.09, 17, 1.20, 0.21)
    elif key == "pain":
        sound.creature(0, 0.60, 1.1, "pain")
        sound.grit(0.005, 0.17, 0.24, 0.065, 300, 2800)
    elif key == "break":
        sound.metal(0, 0.6, 390, 0.21)
        sound.creature(0.04, 0.52, 0.55, "pain")
        sound.thump(0.20, 1.0, 61, 0.12)
        sound.grit(0.20, 0.45, 0.48, 0.08, 80, 4200)
        sound.pebbles(0.28, 10, 0.55, 0.22)
    elif key == "spawn":
        sound.grit(0, 0.45, 0.45, 0.18, 180, 2200)
        sound.creature(0.08, 1.92, 1.25)
        sound.thump(0.24, 0.35, 40, 0.20)
    elif key == "death":
        sound.creature(0, 1.5, 0.95, "death")
        sound.thump(0.60, 1.1, 43, 0.20)
        sound.grit(0.60, 0.8, 0.75, 0.14, 60, 4700)
        sound.metal(0.77, 0.66, 360, 0.28)
        sound.metal(0.91, 0.24, 640, 0.17)
        sound.pebbles(0.70, 13, 1.15, 0.22)
    return sound.finish(rms, room=key in ("heavy_impact", "parry", "spawn", "death"))


def save(path, pcm):
    path.parent.mkdir(parents=True, exist_ok=True)
    output_pcm = array("h", pcm)
    if sys.byteorder != "little":
        output_pcm.byteswap()
    with wave.open(str(path), "wb") as output:
        output.setparams((1, 2, RATE, len(pcm), "NONE", "not compressed"))
        output.writeframes(output_pcm.tobytes())


def validate(pcm):
    values = [v / 32768 for v in pcm]
    peak = max(map(abs, values))
    rms = math.sqrt(sum(v * v for v in values) / len(values))
    assert 0.02 < rms < 0.25 and peak <= 0.85, (peak, rms)
    assert abs(sum(values) / len(values)) < 0.002, "Unexpected DC offset"
    assert pcm[0] == 0 and pcm[-1] == 0, "Edges must fade to silence"
    return {"duration_seconds": round(len(pcm) / RATE, 3),
            "peak_dbfs": round(20 * math.log10(peak), 2),
            "rms_dbfs": round(20 * math.log10(rms), 2)}


def main():
    manifest_path = PROJECT / "data/buto_sfx.json"
    manifest = json.loads(manifest_path.read_text(encoding="utf-8"))
    preview = array("h")
    timeline = []
    report = {}
    for key, definition in manifest["clips"].items():
        pcm = make_clip(key)
        report[key] = validate(pcm)
        path = ROOT / definition["file"]
        save(path, pcm)
        report[key]["sha256"] = hashlib.sha256(path.read_bytes()).hexdigest()
        timeline.append({"key": key, "start_seconds": round(len(preview) / RATE, 3), **report[key]})
        # Preview is louder than the in-game mix for inspection; no live event levels are changed.
        preview.extend(pcm)
        preview.extend([0] * round(RATE * 0.55))
    save(PROJECT / ".godot/audio-review/buto-ijo-sfx-preview.wav", preview)
    report_path = PROJECT / "docs/BUTO_IJO_SFX_REPORT.json"
    report_path.write_text(json.dumps({"generator": "procedural_stdlib_v1", "sample_rate": RATE,
                                      "channels": 1, "bits_per_sample": 16,
                                      "preview_timeline": timeline, "clips": report}, indent=2) + "\n", encoding="utf-8")
    manifest.update(status="ready_procedural", checked_date="2026-11-25",
                    generator="tools/prepare_buto_sfx.py", format="WAV PCM16 mono 44100Hz",
                    note="Original code-generated SFX, authorized by user after fal billing failed. No AI audio/API used.")
    manifest_path.write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
    print("BUTO_SFX_PREPARED: 12 original procedural WAVs; validated headroom, DC, edge fades and duration.")
    print(json.dumps({key: stats["duration_seconds"] for key, stats in report.items()}))


if __name__ == "__main__":
    main()
