"""Isolate a short mop-friction section from Freesound 395603 (CC0)."""
from pathlib import Path
import aud,numpy as np,wave
root=Path(__file__).resolve().parents[2]
s=aud.Sound.file(str(root/'art/mop_audio/freesound-395603-preview.mp3'))
r=int(s.specs[0]);x=s.data().mean(axis=1)
# Keep sustained friction, excluding the opening handling/bucket sequence.
x=x[round(12.05*r):round(13.65*r)].copy()
f=np.fft.rfftfreq(len(x),1/r);spec=np.fft.rfft(x)
# Reduce low handling thuds and thin high-frequency clinks.
high=1/(1+(160/np.maximum(f,1))**4);low=1/(1+(f/5500)**6)
x=np.fft.irfft(spec*high*low,n=len(x))
x*=min(.12/float(np.sqrt(np.mean(x*x))),.8/float(np.max(abs(x))))
n=round(.012*r);x[:n]*=np.linspace(0,1,n);x[-n:]*=np.linspace(1,0,n)
with wave.open(str(root/'assets/audio/mop_scrub.wav'),'wb') as out:
 out.setparams((1,2,r,0,'NONE','not compressed'));out.writeframes((x*32767).astype('<i2').tobytes())
print('Prepared mop_scrub.wav:',len(x)/r,'seconds')
