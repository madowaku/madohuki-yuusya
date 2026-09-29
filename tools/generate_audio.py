"""Original, deterministic procedural audio for Window Hero (Python standard library)."""
from pathlib import Path
import math
import random
import struct
import wave

ROOT = Path(__file__).resolve().parents[1] / "assets" / "audio"
RATE = 22050
RNG = random.Random(29)

def write(name, seconds, fn):
    data = bytearray()
    for i in range(int(RATE * seconds)):
        t = i / RATE
        value = max(-1, min(1, fn(t)))
        data.extend(struct.pack("<h", int(value * 22000)))
    with wave.open(str(ROOT / f"{name}.wav"), "wb") as out:
        out.setparams((1, 2, RATE, 0, "NONE", "not compressed"))
        out.writeframes(data)

def bell(t, freq, duration=1.0):
    if t < 0 or t > duration:
        return 0
    attack = min(1, t / 0.01)
    return attack * math.exp(-t * 5) * (math.sin(math.tau * freq * t) * 0.7 + math.sin(math.tau * freq * 2.01 * t) * 0.15)

write("wipe", 0.14, lambda t: math.sin(math.pi * t / 0.14) * (RNG.uniform(-0.11, 0.11) + math.sin(math.tau * (1100*t + 800*t*t)) * 0.09))
write("shine", 1.35, lambda t: sum(bell(t-i*0.11, f) * 0.33 for i, f in enumerate([783.99, 1046.5, 1318.5, 1567.98])))
write("clear", 2.4, lambda t: sum(bell(t-i*0.16, f, 1.5) * 0.26 for i, f in enumerate([523.25, 659.25, 783.99, 1046.5, 987.77, 1318.5])))
write("step", 0.10, lambda t: math.exp(-t * 60) * (math.sin(math.tau * 180 * t) * 0.18 + RNG.uniform(-0.07, 0.07)))
notes = [261.63, 329.63, 392.0, 493.88, 440.0, 392.0, 329.63, 293.66, 261.63, 329.63, 392.0, 523.25, 493.88, 392.0, 293.66, 329.63]
def garden(t):
    section = int(t / 1.5)
    result = 0.0
    for index in range(max(0, section - 2), min(section + 1, len(notes))):
        age = t - index * 1.5
        result += bell(age, notes[index], 3) * 0.24
        result += bell(age - 0.5, notes[index] * 2, 2.5) * 0.07
    return result * min(1, t / 0.3, (24 - t) / 0.3)
write("garden", 24, garden)
print("Generated six original audio files.")
