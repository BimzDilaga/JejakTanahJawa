"""Temporary Jaka/commander SFX. Buto Ijo has a separate procedural generator."""
from array import array
from pathlib import Path
import math
import random
import wave

ROOT = Path(__file__).resolve().parents[1] / 'assets/Generated/Audio/Temporary'
RATE = 44100

def save(name, seconds, seed, gun=False):
    rng = random.Random(seed)
    samples = []
    low = 0.0
    for index in range(round(RATE * seconds)):
        t = index / RATE
        p = t / seconds
        noise = rng.uniform(-1, 1)
        low = low * 0.82 + noise * 0.18
        if gun:
            value = (noise-low)*math.exp(-t*43)*0.65 + math.sin(2*math.pi*105*t)*math.exp(-t*30)*0.30
        else:
            envelope = math.exp(-((p-0.43)/0.23)**2)*math.sin(math.pi*p)
            value = (noise-low)*envelope*0.65 + math.sin(2*math.pi*(2400*t-1800*t*t))*math.exp(-t*27)*0.07
        edge = min(1.0, t/0.002, (seconds-t)/0.004)
        samples.append(value*max(0.0,edge))
    peak = max(abs(v) for v in samples) or 1
    pcm = array('h',(round(v/peak*0.70*32767) for v in samples))
    ROOT.mkdir(parents=True,exist_ok=True)
    with wave.open(str(ROOT/name),'wb') as output:
        output.setparams((1,2,RATE,len(pcm),'NONE','not compressed'))
        output.writeframes(pcm.tobytes())

if __name__ == '__main__':
    for i, seconds in enumerate((0.22,0.25,0.31),1):
        save(f'keris-swing-{i}.wav',seconds,1825+i)
    save('flintlock-shot.wav',0.28,1830,gun=True)
    print('TEMPORARY_SFX_PREPARED: three keris swings and one commander shot; no Buto AI replacements.')
