"""Create original, deterministic PCM game sounds; no external samples needed."""
import math
import random
import struct
import wave
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / 'assets' / 'audio'
OUT.mkdir(parents=True, exist_ok=True)
RATE = 22050
rng = random.Random(13)

def write(name, duration, synth):
    with wave.open(str(OUT / f'{name}.wav'), 'wb') as f:
        f.setnchannels(1)
        f.setsampwidth(2)
        f.setframerate(RATE)
        f.writeframes(b''.join(struct.pack('<h', int(max(-1, min(1, synth(i / RATE))) * 26000))
                               for i in range(int(duration * RATE))))

def sine(freq, t):
    return math.sin(2 * math.pi * freq * t)

write('horn', .48, lambda t: (sine(330, t) + .5 * sine(415, t)) * .28
      * min(1, t * 60) * max(0, 1 - t / .48) * (1 if t < .16 or t > .23 else .15))
write('pickup', .36, lambda t: sine(660 if t < .1 else 990 if t < .2 else 1320, t)
      * .38 * min(1, t * 100) * (1 - t / .36))
write('hit_pothole', .48, lambda t: (.6 * rng.uniform(-1, 1) + .4 * sine(65, t))
      * math.exp(-t * 10) * .7)
write('near_miss', .3, lambda t: sine(600 + t * 1800, t) * .18 * math.sin(math.pi * t / .3))
# Whole-number periods give a seamless loop. Subtle engine pulse, not loud music.
write('background', 4, lambda t: (.10 * sine(55, t) + .05 * sine(110, t)
      + .025 * sine(165, t)) * (.75 + .25 * sine(8, t)))
print('Generated 5 original WAV assets.')
