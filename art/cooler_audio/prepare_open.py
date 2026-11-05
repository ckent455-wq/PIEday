"""Prepare Freesound 121210 (CC0), selected by the user for the haunted cooler."""
from pathlib import Path
import aud,numpy as np,wave
root=Path(__file__).resolve().parents[2]
s=aud.Sound.file(str(root/'art/cooler_audio/freesound-121210-preview.mp3'))
r=int(s.specs[0]);x=s.data().mean(axis=1)
active=np.flatnonzero(abs(x)>max(abs(x))*.025)
start=max(0,int(active[0])-int(r*.004));x=x[start:].copy()
x*=min(.14/max(float(np.sqrt(np.mean(x*x))),1e-6),.85/max(float(max(abs(x))),1e-6))
n=min(round(.015*r),len(x));x[-n:]*=np.linspace(1,0,n)
with wave.open(str(root/'assets/audio/cooler_open.wav'),'wb') as f:
 f.setparams((1,2,r,0,'NONE','not compressed'));f.writeframes((x*32767).astype('<i2').tobytes())
print('Prepared cooler_open.wav',len(x)/r,'seconds')
