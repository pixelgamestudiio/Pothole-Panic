"""Original rain-bed synthesis; does not modify the existing game sounds."""
import math
import random
import struct
import wave
from pathlib import Path

rate = 22050
count = rate * 6
rng = random.Random(721)
low = 0.0
samples = []
for i in range(count):
    noise = rng.uniform(-1, 1)
    low = low * 0.88 + noise * 0.12
    # Quiet continuous rainfall with a slow swell and a click-free loop seam.
    envelope = min(1, i / 300, (count - 1 - i) / 300)
    value = (noise * 0.11 + low * 0.32) * (0.85 + 0.15 * math.sin(2 * math.pi * i / count))
    samples.append(struct.pack('<h', int(value * envelope * 32767)))
target = Path(__file__).resolve().parents[1] / 'assets/audio/rain.wav'
with wave.open(str(target), 'wb') as output:
    output.setnchannels(1)
    output.setsampwidth(2)
    output.setframerate(rate)
    output.writeframes(b''.join(samples))
print(f'Generated {target.name}: 6 seconds of original rain ambience.')
