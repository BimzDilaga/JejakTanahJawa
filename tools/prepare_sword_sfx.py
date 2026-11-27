"""Split the supplied sword recording at silence gaps, preserving source order."""
from pathlib import Path
import argparse
import array
import hashlib
import json
import math
import re
import subprocess
import wave

ROOT = Path(__file__).resolve().parents[1]
DEFAULT_SOURCE = ROOT / 'assets/SFX & Soundtrack/Mechanique game/sword slash (sound effects) mani creation.mp3'

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--ffmpeg', required=True)
    parser.add_argument('--source', type=Path, default=DEFAULT_SOURCE)
    args = parser.parse_args()
    audit = ROOT / '.godot/audio-review'
    audit.mkdir(parents=True, exist_ok=True)
    decoded = audit / 'sword-source.wav'
    subprocess.run([args.ffmpeg,'-hide_banner','-loglevel','error','-nostdin','-y','-i',str(args.source),'-vn','-ac','1','-ar','44100','-c:a','pcm_s16le',str(decoded)],check=True)
    probe = subprocess.run([args.ffmpeg,'-hide_banner','-nostdin','-i',str(decoded),'-af','silencedetect=noise=-38dB:d=0.12','-f','null','NUL'],capture_output=True,text=True,encoding='utf-8',errors='replace',check=True)
    with wave.open(str(decoded),'rb') as stream:
        rate=stream.getframerate()
        data=array.array('h',stream.readframes(stream.getnframes()))
    length=len(data)/rate
    intervals=[]
    end_of_silence=0.0
    for event,value in re.findall(r'silence_(start|end):\s*([0-9.]+)',probe.stderr):
        at=float(value)
        if event=='start' and at-end_of_silence>0.12:
            intervals.append((max(0.0,end_of_silence-0.025),min(length,at+0.08)))
        elif event=='end':
            end_of_silence=at
    if length-end_of_silence>0.12 and (not intervals or intervals[-1][1]<length-0.12):
        # The supplied recording ends in silence; retain a final sound only if
        # the last detector event was silence_end followed by non-silent audio.
        events=re.findall(r'silence_(start|end):\s*([0-9.]+)',probe.stderr)
        if events and events[-1][0]=='end' and length-float(events[-1][1])>0.12:
            intervals.append((max(0.0,end_of_silence-0.025),length))
    if len(intervals)<3:
        raise RuntimeError(f'Only {len(intervals)} sounds found; inspect the source before changing combo audio.')
    output=ROOT/'assets/Generated/Audio/Combat/SwordSlashes'
    output.mkdir(parents=True,exist_ok=True)
    clips=[]
    preview=array.array('h')
    for number,(begin,end) in enumerate(intervals,1):
        samples=data[round(begin*rate):round(end*rate)]
        peak=max(abs(s) for s in samples)
        assert peak>100 and len(samples)/rate<3.0
        gain=32767*10**(-1.5/20)/peak
        fade_in=round(rate*0.002)
        fade_out=round(rate*0.010)
        normalized=array.array('h')
        for index,sample in enumerate(samples):
            fade=min(1.0,index/max(1,fade_in),(len(samples)-1-index)/max(1,fade_out))
            normalized.append(round(sample*gain*max(0,fade)))
        target=output/f'slash-{number:02}.wav'
        with wave.open(str(target),'wb') as clip:
            clip.setnchannels(1)
            clip.setsampwidth(2)
            clip.setframerate(rate)
            clip.writeframes(normalized.tobytes())
        preview.extend(normalized)
        preview.extend([0]*round(rate*0.30))
        clips.append({'number':number,'file':'res://'+target.relative_to(ROOT).as_posix(),'source_start_seconds':round(begin,6),'source_end_seconds':round(end,6),'seconds':round(len(normalized)/rate,6),'peak_db':round(20*math.log10(max(abs(s) for s in normalized)/32768),3)})
    with wave.open(str(audit/'sword-slashes-preview.wav'),'wb') as stream:
        stream.setnchannels(1)
        stream.setsampwidth(2)
        stream.setframerate(rate)
        stream.writeframes(preview.tobytes())
    manifest={'source':'assets/SFX & Soundtrack/Mechanique game/'+args.source.name,'source_sha256':hashlib.sha256(args.source.read_bytes()).hexdigest(),'source_seconds':length,'format':'WAV PCM16 mono 44100 Hz','silence_threshold_db':-38,'clips':clips,'combo':{f'swing_{i}':clips[i-1]['file'] for i in range(1,4)},'note':'Original source order. First three sounds are Jaka combo hits 1, 2, 3; remaining cuts retained for review. Source preserved; 2ms/10ms edge fades, peak -1.5 dB.'}
    (ROOT/'data/sword_slashes.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
    print('SWORD_SFX_READY',len(clips),'clips; source preserved; combo 1/2/3 mapped in source order',flush=True)
    for clip in clips:
        print(clip['number'],clip['source_start_seconds'],clip['source_end_seconds'],clip['seconds'],clip['peak_db'],flush=True)

if __name__=='__main__':
    main()
