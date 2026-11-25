"""Original synthetic game music, ambience and Headless SFX. No recordings or API.

Music uses an original five-tone bronze-percussion palette inspired by gamelan;
it is not a reconstruction of a traditional composition or historical tuning.
Requires numpy for synthesis and ffmpeg with libvorbis for runtime OGG loops.
"""
import argparse
import hashlib
import json
import math
from pathlib import Path
import subprocess
import wave

import numpy as np
from prepare_buto_sfx import Sound, save

ROOT = Path(__file__).resolve().parents[1]
RATE = 44100
TAU = math.tau
report = {}


def add(buffer, signal, at, gain=1.0, pan=0.0):
    start = round(at * RATE) % len(buffer)
    signal = signal.astype(np.float32) * gain
    if buffer.ndim == 2:
        signal = signal[:, None] * np.array([math.sqrt((1-pan)/2), math.sqrt((1+pan)/2)])
    # Wrap releases into the beginning so the musical loop contains its own tails.
    first = min(len(signal), len(buffer)-start)
    buffer[start:start+first] += signal[:first]
    remaining = len(signal)-first
    if remaining: buffer[:remaining] += signal[first:]


def bronze(frequency, seconds=1.25, gong=False):
    t = np.arange(round(seconds*RATE), dtype=np.float64)/RATE
    signal = np.zeros_like(t)
    for ratio, level in [(1,0.60),(1.53,0.23),(2.07,0.14),(2.79,0.08),(3.92,0.035)]:
        decay = (seconds/3.3 if gong else seconds/4.7)/math.sqrt(ratio)
        vibrato = 0.002*np.sin(TAU*3.1*t) if gong else 0
        signal += level*np.sin(TAU*frequency*ratio*t+vibrato)*np.exp(-t/decay)
    return np.tanh(signal*1.1)*np.minimum(1,t/0.002)


def drum(seed, bass=False):
    rng = np.random.default_rng(seed)
    t = np.arange(round(RATE*0.25))/RATE
    phase = TAU*((70 if bass else 140)*t+45*(1-np.exp(-t*35))/35)
    body = np.sin(phase)*np.exp(-t/(0.075 if bass else 0.040))
    skin = rng.standard_normal(len(t))*np.exp(-t/0.018)*0.11
    return (body+skin)*np.minimum(1,t/0.0015)


def write_wav(path, data, peak=0.78, target=0.13):
    data = data - np.mean(data, axis=0)
    max_value = float(np.max(np.abs(data))) or 1
    rms = float(np.sqrt(np.mean(data*data))) or 1
    data *= min(peak/max_value, target/rms)
    pcm = np.rint(np.clip(data,-0.98,0.98)*32767).astype('<i2')
    path.parent.mkdir(parents=True, exist_ok=True)
    with wave.open(str(path),'wb') as output:
        output.setparams((1 if data.ndim==1 else 2,2,RATE,len(data),'NONE','not compressed'))
        output.writeframes(pcm.tobytes())
    return {"seconds":round(len(data)/RATE,3),"peak_dbfs":round(20*math.log10(float(np.max(np.abs(data))) or 1e-9),2)}


def music(name, bpm, calm=False):
    beat = 60/bpm
    duration = beat*64
    output = np.zeros((round(duration*RATE),2),dtype=np.float32)
    scale = [146.8,169.2,195.8,224.4,259.6]
    patterns = [[0,2,1,4,2,1,3,1],[0,1,3,2,4,2,1,0],[2,4,3,1,0,1,2,1],[0,3,2,4,1,2,1,0]]
    for bar in range(16):
        base = bar*4*beat
        add(output,bronze(48.5,3.6,True),base,0.43 if calm else 0.65,0)
        add(output,bronze(scale[bar%5]/2,2.0,True),base+2*beat,0.16 if calm else 0.27,-0.15)
        for index,note in enumerate(patterns[(bar//4)%4]):
            if calm and index%2: continue
            add(output,bronze(scale[note]*(2 if index%3==0 else 1),0.95),base+index*beat/2,0.13 if calm else 0.19,0.30 if index%2 else -0.30)
        if not calm:
            for index in [0,1.5,2,2.75,3.5]:
                add(output,drum(1825+bar*8+round(index*2),index in [0,2]),base+index*beat,0.27 if index in [0,2] else 0.13,0.12 if index%1 else -0.1)
            if name=="commander-last-march":
                for index in range(4):
                    add(output,bronze(scale[(bar+index)%5]*2,0.32),base+(index+0.5)*beat,0.075,0.3)
    path=ROOT/'.godot/audio-sources'/f'{name}.wav'
    report[name]=write_wav(path,output,target=0.10 if calm else 0.13)
    return path


def ambience(name, seed, insects=True):
    rng=np.random.default_rng(seed)
    length=RATE*24
    frequencies=np.fft.rfftfreq(length,1/RATE)
    spectrum=rng.standard_normal(len(frequencies))+1j*rng.standard_normal(len(frequencies))
    spectrum/=np.maximum(frequencies,30)**0.9
    spectrum[frequencies>2200]=0
    spectrum[0]=0
    wind=np.fft.irfft(spectrum,n=length)
    wind/=np.max(np.abs(wind))
    t=np.arange(length)/RATE
    output=np.column_stack((wind*np.sin(TAU*t/24+0.4)*0.014+wind*0.025,wind*np.sin(TAU*t/24-0.3)*0.014+wind*0.025)).astype(np.float32)
    if insects:
        for cluster in range(14):
            at=cluster*1.71+rng.uniform(-0.1,0.1)
            frequency=rng.uniform(3800,5600)
            for pulse in range(3):
                tone_t=np.arange(round(RATE*0.045))/RATE
                signal=np.sin(TAU*frequency*tone_t)*np.sin(np.pi*tone_t/0.045)**2
                add(output,signal,at+pulse*0.095,0.05,rng.uniform(-0.8,0.8))
        for at in [3.7,10.3,18.9]:
            frog_t=np.arange(round(RATE*0.36))/RATE
            signal=np.sin(TAU*(270*frog_t+10*np.sin(TAU*5*frog_t)))*np.sin(np.pi*frog_t/0.36)**2
            add(output,signal,at,0.027,-0.6)
    path=ROOT/'.godot/audio-sources'/f'{name}.wav'
    report[name]=write_wav(path,output,peak=0.6,target=0.055)
    return path


def headless():
    manifest=json.loads((ROOT/'data/headless_sfx.json').read_text())
    durations=[0.42,0.44,0.42,0.48,0.78,1.20,0.65,0.78,0.52,1.15,1.8,2.0]
    for index,(key,definition) in enumerate(manifest['clips'].items()):
        sound=Sound(durations[index],183000+index)
        if key.startswith('step'):
            sound.thump(0,0.8,108 if key=='step_a' else 91,0.045)
            sound.grit(0,0.18,0.5,0.045,240,5200)
        elif key.startswith('swing') or key=='windup':
            sound.whoosh(0,durations[index]*0.9,1.0,key!='swing_a',key=='windup')
            sound.metal(0.10,0.13,900,0.13)
        elif key=='parry':
            sound.grit(0,0.12,0.6,0.013,1600,12000)
            sound.metal(0.002,1.0,1390,0.18)
        elif key in ('smoke','spawn','pain'):
            sound.whoosh(0,durations[index]*0.92,0.85,True,True)
            sound.metal(0.03,0.13,190 if key=='spawn' else 340,0.32)
        else:
            sound.thump(0.09,0.9,80,0.12)
            sound.metal(0,0.65,610,0.23)
            sound.grit(0.10,0.4,0.5,0.09,120,4600)
            sound.whoosh(0,durations[index]*0.85,0.35,True,True)
        pcm=sound.finish(0.13,room=key in ('spawn','death','parry'))
        save(ROOT/'assets/Generated/Audio/Headless'/definition['file'],pcm)


def main():
    parser=argparse.ArgumentParser()
    parser.add_argument('--ffmpeg',required=True)
    args=parser.parse_args()
    headless()
    loops=[('Music',music('headless-smoke-and-bronze',80)),('Music',music('commander-last-march',106)),('Music',music('ending-memory',72,True)),('Ambience',ambience('night-village',1825)),('Ambience',ambience('day-wind',1830,False))]
    for folder,source in loops:
        target=ROOT/'assets/Generated/Audio'/folder/(source.stem+'.ogg')
        target.parent.mkdir(parents=True,exist_ok=True)
        subprocess.run([args.ffmpeg,'-y','-hide_banner','-loglevel','error','-i',str(source),'-c:a','libvorbis','-q:a','4',str(target)],check=True)
        report[source.stem]['sha256']=hashlib.sha256(target.read_bytes()).hexdigest()
    (ROOT/'docs/WORLD_AUDIO_REPORT.json').write_text(json.dumps({'original_synthetic_audio':True,'note':'Original gamelan-inspired five-tone compositions; not historical tuning reconstruction. All events and loops generated from code without third-party recordings.','loops':report},indent=2)+'\n')
    print('WORLD_AUDIO_PREPARED: 12 Headless SFX, three original music loops, night insects and day wind.')


if __name__=='__main__': main()
