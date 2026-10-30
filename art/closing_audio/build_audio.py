"""Generate original, quiet mono effects for the closing encounters."""
import math, random, struct, wave
from pathlib import Path

OUT = Path(__file__).resolve().parents[2] / 'assets' / 'audio'
RATE = 22050
rng = random.Random(9017)

def save(name, duration, sample):
 with wave.open(str(OUT / (name + '.wav')), 'wb') as wav:
  wav.setnchannels(1)
  wav.setsampwidth(2)
  wav.setframerate(RATE)
  wav.writeframes(b''.join(struct.pack('<h', int(max(-1, min(1, sample(i / RATE))) * 24000)) for i in range(int(duration * RATE))))

def knock(t):
 total = 0
 for start in [0.0, 0.32, 0.77]:
  u = t - start
  if 0 <= u < 0.25:
   total += math.exp(-u * 30) * (0.5 * math.sin(2 * math.pi * 155 * u) + 0.22 * math.sin(2 * math.pi * 347 * u) + rng.uniform(-0.12, 0.12))
 return total

def step(t):
 return math.exp(-t * 24) * (math.sin(2 * math.pi * 85 * t) * 0.42 + rng.uniform(-0.2, 0.2)) * min(1, t * 450)

def creak(t):
 envelope = math.sin(math.pi * min(1, t / 1.3)) ** 2
 return envelope * (0.22 * math.sin(2 * math.pi * (180 * t + 38 * t * t) + 2 * math.sin(t * 33)) + rng.uniform(-0.025, 0.025))

save('closing_knocks', 1.3, knock)
save('closing_footstep', 0.38, step)
save('closing_creak', 1.3, creak)
