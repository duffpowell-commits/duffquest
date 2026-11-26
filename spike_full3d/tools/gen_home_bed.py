"""Home ambience bed for the apartment (Nov 25 2026): fridge hum, room tone, a TV murmuring in the
next room. Made from numbers (no recordings), so it's ours. Everything is built over one circular
buffer, so the loop has no seam.
  python3 tools/gen_home_bed.py audio/home_bed.ogg   (needs numpy + ffmpeg)
"""
import subprocess, sys, tempfile, wave
import numpy as np

RATE = 22050
SECONDS = 16
N = RATE * SECONDS
rng = np.random.default_rng(1125)
t = np.arange(N) / RATE

def band(lo, hi, tilt=0.0):
    """Noise between lo and hi Hz (circular, so it loops), optional 1/f^tilt slope."""
    spec = np.fft.rfft(rng.standard_normal(N))
    f = np.fft.rfftfreq(N, 1 / RATE)
    gain = ((f >= lo) & (f <= hi)).astype(float)
    gain[1:] /= f[1:] ** tilt
    out = np.fft.irfft(spec * gain, N)
    return out / np.abs(out).max()

def slow(rate_hz):
    """A smooth random 0..1 envelope that loops (energy only below rate_hz)."""
    e = band(0.05, rate_hz)
    return (e - e.min()) / (e.max() - e.min())

room = band(30, 6000, 1.0) * .05                       # soft room tone
hum = (np.sin(2 * np.pi * 60 * t) * .5 + np.sin(2 * np.pi * 120 * t) * .3
       + np.sin(2 * np.pi * 180 * t) * .12) * .045     # fridge compressor
hum *= .8 + .2 * slow(.3)
syll = slow(5.0) ** 2                                   # speech-like syllables
words = slow(.6)                                        # phrases and pauses
tv = band(250, 2600) * syll * np.clip(words * 1.6 - .3, 0, 1) * .07
laugh = band(400, 3500) * slow(1.5) * (slow(.08) > .82) * .05   # a sitcom laugh now and then
mix = room + hum + tv + laugh
mix = np.convolve(np.concatenate([mix[-200:], mix]), np.ones(3) / 3, "valid")[-N:]  # take off the fizz
mix = (mix / np.abs(mix).max() * .5 * 32767).astype(np.int16)

with tempfile.NamedTemporaryFile(suffix=".wav") as tmp:
    with wave.open(tmp.name, "wb") as w:
        w.setnchannels(1); w.setsampwidth(2); w.setframerate(RATE); w.writeframes(mix.tobytes())
    subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", tmp.name, "-c:a", "libvorbis", "-q:a", "2",
                    sys.argv[1] if len(sys.argv) > 1 else "audio/home_bed.ogg"], check=True)
print("wrote", sys.argv[1] if len(sys.argv) > 1 else "audio/home_bed.ogg")
