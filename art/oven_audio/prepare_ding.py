from pathlib import Path
import aud,numpy as np,wave
root=Path(__file__).resolve().parents[2]
s=aud.Sound.file(str(root/'art/oven_audio/freesound-265012-preview.mp3'))
r=int(s.specs[0]);x=s.data().mean(axis=1)
# Remove leading silence, keep the bell's natural decay.
active=np.flatnonzero(np.abs(x)>max(abs(x))*.035)
start=max(0,int(active[0])-int(r*.004))
x=x[start:].copy();x*=.8/max(abs(x))
n=min(int(.06*r),len(x));x[-n:]*=np.linspace(1,0,n)
with wave.open(str(root/'assets/audio/oven_ready.wav'),'wb') as f:
 f.setparams((1,2,r,0,'NONE','not compressed'));f.writeframes((x*32767).astype('<i2').tobytes())
print('Prepared oven bell',len(x)/r,'seconds')
