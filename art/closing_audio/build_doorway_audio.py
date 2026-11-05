"""Original mono effects for PIEday's trash/doorway sequence. No recordings used."""
from pathlib import Path
import math, random, struct, wave
RATE = 44100
OUT = Path(__file__).resolve().parents[2] / 'assets' / 'audio'
rng = random.Random(2044)

def save(name, data):
    peak = max(abs(v) for v in data) or 1
    data = [v / peak * .78 for v in data]
    with wave.open(str(OUT / (name + '.wav')), 'wb') as f:
        f.setparams((1, 2, RATE, 0, 'NONE', 'not compressed'))
        f.writeframes(b''.join(struct.pack('<h', round(v * 32767)) for v in data))

low = 0
bag = []
for i in range(int(.72 * RATE)):
    t = i / RATE
    n = rng.uniform(-1, 1)
    low += .12 * (n - low)
    impact = .65 * math.sin(2*math.pi*72*t) * math.exp(-t*24)
    hollow = sum(math.sin(2*math.pi*hz*t)*math.exp(-t*decay)*amp for hz,decay,amp in [(137,19,.22),(391,23,.09),(663,28,.05)])
    rustle = (n-low) * (.12*math.exp(-t*8) + .07*math.exp(-((t-.19)/.035)**2) + .04*math.exp(-((t-.32)/.05)**2))
    bag.append((impact+hollow+rustle) * min(1,t/.003) * min(1,(.72-t)/.06))
save('trash_bag_drop', bag)

low = 0
shadow = []
for i in range(int(1.15 * RATE)):
    t = i / RATE
    n = rng.uniform(-1,1)
    low += .035 * (n-low)
    attack = min(1,t/.012)
    tail = max(0,1-t/1.15)**1.8
    bass = .38*math.sin(2*math.pi*(84*t-19*t*t))*math.exp(-t*8)
    dissonance = sum(math.sin(2*math.pi*hz*t + .7*math.sin(t*31))*amp for hz,amp in [(233,.065),(247,.055),(349,.035)]) * math.exp(-t*6)
    air = (n-low)*.16*(.4+.6*math.sin(math.pi*min(1,t/.7))**2)
    breath = low*.55
    shadow.append((bass+dissonance+air+breath) * attack * tail)
save('shadow_dissipate', shadow)
print('Generated trash impact and shadow sting/breath effects')
