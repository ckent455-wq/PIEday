"""Prepare the user's selected Freesound CC0 soda pour for the 1.8-second fill.
Run with Blender Python (aud decodes the MP3 preview).
"""
from pathlib import Path
import aud, numpy as np, wave
ROOT=Path(__file__).resolve().parents[2]
sound=aud.Sound.file(str(ROOT/'art/soda_audio/freesound-700351-preview.mp3'))
rate=int(sound.specs[0])
x=sound.data().mean(axis=1)
x=x[round(.15*rate):round(1.95*rate)].copy()
gain=min(.12/float(np.sqrt(np.mean(x*x))), .85/float(np.max(np.abs(x))))
x*=gain
attack=round(.008*rate); release=round(.045*rate)
x[:attack]*=np.linspace(0,1,attack)
x[-release:]*=np.linspace(1,0,release)
with wave.open(str(ROOT/'assets/audio/soda_pour.wav'),'wb') as f:
 f.setparams((1,2,rate,0,'NONE','not compressed'))
 f.writeframes((np.clip(x,-1,1)*32767).astype('<i2').tobytes())
print('Prepared soda_pour.wav',len(x)/rate,'seconds; gain',round(gain,2))
