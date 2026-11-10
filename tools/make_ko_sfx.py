#!/usr/bin/env python3
"""Knockout cutscene sound effects, made from scratch (numpy/scipy synthesis, no samples).

    python3 tools/make_ko_sfx.py            # -> assets/sfx/ko/*.ogg (then run godot --import)

Every sound is peak-normalised to -3 dBFS before encoding (ffmpeg libvorbis, q5); the script
decodes each .ogg again and fails if any file comes back above -1 dBFS (vorbis overshoot).
Seeded RNG, so a rerun gives the same files. Cue times live in scripts/knockout.gd (SFX_CUES).
"""
import os
import subprocess
import sys
import tempfile
import wave

import numpy as np
from scipy import signal

SR = 44100
PEAK_DB = -3.0
OUT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "assets", "sfx", "ko")
rng = np.random.default_rng(1977)


# ------------------------------------------------------------------ helpers

def t_axis(dur):
    return np.arange(int(dur * SR)) / SR


def noise(dur):
    return rng.standard_normal(int(dur * SR))


def bp(x, lo, hi, order=2):
    sos = signal.butter(order, [lo, hi], btype="band", fs=SR, output="sos")
    return signal.sosfilt(sos, x)


def lp(x, f, order=2):
    return signal.sosfilt(signal.butter(order, f, btype="low", fs=SR, output="sos"), x)


def hp(x, f, order=2):
    return signal.sosfilt(signal.butter(order, f, btype="high", fs=SR, output="sos"), x)


def sweep_bp(x, f_curve, q=2.0):
    """Band-pass with a moving centre (state-variable filter, per sample)."""
    y = np.zeros_like(x)
    low = band = 0.0
    damp = 1.0 / q
    for i in range(len(x)):
        f = 2.0 * np.sin(np.pi * min(f_curve[i], SR * 0.2) / SR)
        high = x[i] - low - damp * band
        band += f * high
        low += f * band
        y[i] = band
    return y


def glide_sine(f0, f1, dur, curve=4.0):
    t = t_axis(dur)
    f = f1 + (f0 - f1) * np.exp(-curve * t / dur)
    return np.sin(2 * np.pi * np.cumsum(f) / SR)


def env_exp(dur, decay, attack=0.002):
    t = t_axis(dur)
    a = np.clip(t / max(attack, 1e-4), 0, 1)
    return a * np.exp(-t / decay)


def place(buf, x, at):
    i = int(at * SR)
    n = min(len(x), len(buf) - i)
    if n > 0:
        buf[i:i + n] += x[:n]
    return buf


def fade(x, fin=0.005, fout=0.05):
    x = x.copy()
    a, b = int(fin * SR), int(fout * SR)
    if a:
        x[:a] *= np.linspace(0, 1, a)
    if b:
        x[-b:] *= np.linspace(1, 0, b) ** 2
    return x


def stereo(x, pan=0.0):
    """pan -1 left .. 1 right (constant power); pan may be an array."""
    p = (np.asarray(pan) + 1) * np.pi / 4
    return np.stack([x * np.cos(p), x * np.sin(p)], axis=1)


def ks_pluck(freq, dur, damp=0.996, bright=0.5):
    """Karplus-Strong string (upright bass / guitar pluck)."""
    n = int(dur * SR)
    period = int(SR / freq)
    buf = lp(rng.uniform(-1, 1, period), 200 + 3000 * bright)
    out = np.zeros(n)
    for i in range(n):
        j = i % period
        v = buf[j]
        out[i] = v
        buf[j] = damp * 0.5 * (v + buf[(j + 1) % period])
    return out


def rhodes(freq, dur):
    """Electric-piano-ish FM tone: bell attack that mellows out."""
    t = t_axis(dur)
    idx = 1.8 * np.exp(-t / 0.25) + 0.25
    mod = np.sin(2 * np.pi * freq * t)
    tone = np.sin(2 * np.pi * freq * t + idx * mod)
    tine = 0.15 * np.sin(2 * np.pi * freq * 7.0 * t) * np.exp(-t / 0.06)
    trem = 1 + 0.12 * np.sin(2 * np.pi * 4.5 * t)
    return (tone + tine) * np.exp(-t / 1.6) * trem


def note(name):
    names = {"C": 0, "C#": 1, "D": 2, "D#": 3, "E": 4, "F": 5, "F#": 6, "G": 7, "G#": 8, "A": 9, "A#": 10, "B": 11}
    pitch, octave = name[:-1], int(name[-1])
    return 440.0 * 2 ** ((names[pitch] + 12 * (octave + 1) - 69) / 12)


def reverb(x, dur=1.2, mix=0.25, damp=3000):
    """Cheap room: exponentially decaying noise impulse response."""
    ir = lp(noise(dur), damp) * np.exp(-t_axis(dur) / (dur / 5))
    ir[0] = 0
    ir /= np.sqrt(np.sum(ir ** 2)) + 1e-9
    if x.ndim == 1:
        wet = signal.fftconvolve(x, ir)[:len(x)]
    else:
        ir2 = lp(noise(dur), damp) * np.exp(-t_axis(dur) / (dur / 5))
        ir2 /= np.sqrt(np.sum(ir2 ** 2)) + 1e-9
        wet = np.stack([signal.fftconvolve(x[:, 0], ir)[:len(x)], signal.fftconvolve(x[:, 1], ir2)[:len(x)]], axis=1)
    return x + mix * wet


# ------------------------------------------------------------------ sounds

def whoosh():
    """slip: air rushing past as Duff slides out of the swing; pans left to right."""
    dur = 0.75
    t = t_axis(dur)
    k = t / dur
    f = 250 + 2600 * np.sin(np.pi * np.clip(k * 1.15, 0, 1)) ** 2
    x = sweep_bp(noise(dur), f, q=1.6) + 0.4 * sweep_bp(noise(dur), f * 1.9, q=3.0)
    env = np.sin(np.pi * np.clip(k, 0, 1)) ** 1.6
    x = fade(x * env, 0.01, 0.08)
    return stereo(x, np.linspace(-0.7, 0.7, len(x)))


def drone():
    """xray freeze: time drops into slow motion. Pitch sinks, sub hum, heartbeat underneath."""
    dur = 6.0
    t = t_axis(dur)
    hum = (glide_sine(130, 55, dur, 7) + 0.6 * glide_sine(196, 82.4, dur, 7)
           + 0.35 * glide_sine(131.5, 55.6, dur, 7))          # detuned pair -> slow beating
    room = lp(noise(dur), 260) * 1.5
    pad = (hum * 0.5 + room * 0.4) * np.clip(t / 0.25, 0, 1)
    beat = np.zeros(len(t))
    for at in np.arange(0.35, dur - 0.6, 1.15):               # lub-dub, slow (50 bpm)
        lub = glide_sine(62, 38, 0.18, 3) * env_exp(0.18, 0.05, 0.004)
        dub = glide_sine(55, 34, 0.16, 3) * env_exp(0.16, 0.045, 0.004) * 0.7
        place(beat, lub, at)
        place(beat, dub, at + 0.24)
    beat = lp(beat, 180) * 2.2
    x = fade(pad + beat, 0.02, 1.4)
    return reverb(x, 1.5, 0.3, 1500)


def crack():
    """xray hit: bone crack (a cluster of dry splinter clicks) + a heavy body thud."""
    dur = 1.3
    buf = np.zeros(int(dur * SR))
    for i, at in enumerate([0.0, 0.006, 0.014, 0.019, 0.031, 0.047]):   # splinters
        c = hp(noise(0.012), 1800) * env_exp(0.012, 0.0025, 0.0003) * (1.0 - i * 0.12)
        place(buf, c, 0.012 + at)
    wood = np.sin(2 * np.pi * 1750 * t_axis(0.06)) * env_exp(0.06, 0.012, 0.0005)
    place(buf, wood * 0.7, 0.012)
    place(buf, np.sin(2 * np.pi * 2900 * t_axis(0.04)) * env_exp(0.04, 0.007, 0.0005) * 0.4, 0.02)
    thud = glide_sine(110, 38, 0.6, 5) * env_exp(0.6, 0.16, 0.002)
    body = lp(noise(0.25), 500) * env_exp(0.25, 0.05, 0.001) * 0.9
    place(buf, thud * 1.1, 0.0)
    place(buf, body, 0.0)
    buf = np.tanh(buf * 1.6)
    return fade(reverb(buf, 0.9, 0.18, 2500), 0.0, 0.3)


def snap(n):
    """finisher panels 1-3: quick punch snaps, each a bit heavier than the last."""
    dur = 0.4
    buf = np.zeros(int(dur * SR))
    k = 1.0 + 0.18 * n
    whip = sweep_bp(noise(0.06), np.linspace(1500, 5000, int(0.06 * SR)), q=2.5) * np.linspace(0, 1, int(0.06 * SR)) ** 2
    place(buf, whip * 0.5, 0.0)
    smack = hp(noise(0.03), 1200 + 300 * n) * env_exp(0.03, 0.006, 0.0004)
    place(buf, smack * 1.2, 0.055)
    thump = glide_sine(170 - 20 * n, 55, 0.25, 5) * env_exp(0.25, 0.05 * k, 0.001)
    place(buf, thump * k, 0.055)
    buf = np.tanh(buf * 1.4)
    return fade(buf, 0.0, 0.08)


def boom():
    """last hit: the full white flash. Sub drop, blast, bright crash ringing out."""
    dur = 3.0
    t = t_axis(dur)
    buf = np.zeros(len(t))
    sub = glide_sine(75, 26, dur, 4) * np.exp(-t / 0.7)
    place(buf, sub * 1.3, 0.0)
    blast = noise(dur)
    fc = 200 + 7000 * np.exp(-t / 0.12)
    blast = sweep_bp(blast, fc, q=0.8) * np.exp(-t / 0.35)
    place(buf, blast * 1.4, 0.0)
    crash = bp(noise(dur), 4500, 12000) * np.clip(t / 0.01, 0, 1) * np.exp(-t / 0.9)
    place(buf, crash * 0.45, 0.0)
    place(buf, crack()[:int(0.15 * SR)] * 0.25, 0.0)         # same bone splinter on top
    buf = np.tanh(buf * 2.6)
    x = reverb(buf, 2.2, 0.35, 4000)
    x = stereo(x, 0.0)
    x[:, 1] = np.roll(x[:, 1], int(0.011 * SR))               # a touch of width
    return np.stack([fade(x[:, 0], 0, 0.6), fade(x[:, 1], 0, 0.6)], axis=1)


def crowd():
    """crowd: spectators gasp together, then a murmur swells and dies away."""
    dur = 3.8
    t = t_axis(dur)
    out = np.zeros((len(t), 2))
    for v in range(22):                                       # the gasp: breathy inhales
        at = rng.uniform(0.0, 0.18)
        g = 0.35 + rng.uniform(0, 0.25)
        n_ = int(g * SR)
        e = np.clip(np.linspace(0, 1, n_) / 0.7, 0, 1) ** 1.5 * np.linspace(1, 0, n_) ** 0.4
        lo = rng.uniform(900, 1500)
        x = bp(noise(g), lo, lo * rng.uniform(2.0, 3.0)) * e * rng.uniform(0.5, 1.0)
        place(out, stereo(x, rng.uniform(-0.8, 0.8)), at)
    for v in range(28):                                       # murmur: talking-ish noise
        f1 = rng.uniform(350, 800)
        f2 = rng.uniform(1100, 2400)
        voice = bp(noise(dur), f1 * 0.7, f1 * 1.3) + 0.6 * bp(noise(dur), f2 * 0.8, f2 * 1.2)
        rate = rng.uniform(3.0, 6.0)
        syll = np.clip(np.sin(2 * np.pi * rate * t + rng.uniform(0, 6.28)) + rng.uniform(-0.2, 0.4), 0, None) ** 1.5
        syll = lp(syll, 25)
        swell = np.clip((t - 0.35) / 1.2, 0, 1) ** 1.2 * np.clip((dur - t) / 1.6, 0, 1)
        out += stereo(voice * syll * swell * rng.uniform(0.2, 0.45), rng.uniform(-0.9, 0.9))
    out = reverb(out, 1.4, 0.4, 3500)
    return np.stack([fade(out[:, 0], 0.01, 0.5), fade(out[:, 1], 0.01, 0.5)], axis=1)


def jazz():
    """closer: lazy walk-off. Swung upright bass + brushes + footsteps, lands on a Dm9 Rhodes chord."""
    bpm = 88.0
    b = 60.0 / bpm
    dur = 5.6
    L = np.zeros(int(dur * SR))
    R = np.zeros(int(dur * SR))
    walk = ["D2", "F2", "A2", "C3", "B2", "G2"]
    for i, nm in enumerate(walk):
        at = i * b
        pl = ks_pluck(note(nm), b * 1.1, 0.995, 0.35) * 0.9
        pl = fade(pl, 0.002, 0.08)
        place(L, pl, at)
        place(R, pl, at)
    for i in range(len(walk)):                                # brushes: swish on every beat, tap on 2 and 4
        at = i * b
        sw_n = int(b * 0.66 * SR)
        sw = bp(noise(b * 0.66), 2500, 9000) * np.sin(np.pi * np.linspace(0, 1, sw_n)) ** 2 * 0.12
        place(L, sw, at)
        place(R, sw * 0.8, at)
        if i % 2 == 1:
            tap = bp(noise(0.09), 1800, 7000) * env_exp(0.09, 0.02, 0.001) * 0.35
            place(L, tap * 0.7, at)
            place(R, tap, at)
        swing = at + b * 2 / 3                               # swung "and"
        tick = bp(noise(0.04), 4000, 10000) * env_exp(0.04, 0.008) * 0.12
        place(L, tick, swing)
    for i in range(len(walk)):                                # footsteps: heel + scuff, a little behind the beat
        at = i * b + 0.04
        heel = (glide_sine(140, 70, 0.12, 4) * env_exp(0.12, 0.025, 0.001) * 0.35
                + lp(noise(0.12), 900) * env_exp(0.12, 0.015, 0.001) * 0.25)
        scuff = bp(noise(0.14), 900, 3500) * np.sin(np.pi * np.linspace(0, 1, int(0.14 * SR))) * 0.06
        side = -0.35 if i % 2 == 0 else 0.35
        place(L, heel * (1 - side), at)
        place(R, heel * (1 + side), at)
        place(L, scuff, at + 0.05)
        place(R, scuff, at + 0.05)
    chord_at = len(walk) * b - 0.08
    for nm, g in [("D3", 0.5), ("F3", 0.42), ("A3", 0.42), ("C4", 0.38), ("E4", 0.34)]:
        tone = rhodes(note(nm), dur - chord_at) * g * 0.55
        place(L, tone, chord_at + 0.012 * ("DFACE".index(nm[0])))
        place(R, tone * 0.9, chord_at + 0.012 * ("DFACE".index(nm[0])) + 0.004)
    bass_end = fade(ks_pluck(note("D2"), dur - chord_at, 0.997, 0.3), 0.002, 0.8)
    place(L, bass_end, chord_at)
    place(R, bass_end, chord_at)
    x = reverb(np.stack([L, R], axis=1), 1.6, 0.3, 4000)
    return np.stack([fade(x[:, 0], 0.003, 1.2), fade(x[:, 1], 0.003, 1.2)], axis=1)


SOUNDS = {
    "whoosh": whoosh,
    "drone": drone,
    "crack": crack,
    "snap1": lambda: snap(0),
    "snap2": lambda: snap(1),
    "snap3": lambda: snap(2),
    "boom": boom,
    "crowd": crowd,
    "jazz": jazz,
}


# ------------------------------------------------------------------ output

def normalise(x):
    x = np.asarray(x, dtype=np.float64)
    if x.ndim == 1:
        x = np.stack([x, x], axis=1)
    x = x - x.mean(axis=0)                                     # no DC offset
    peak = np.max(np.abs(x)) + 1e-12
    return x * (10 ** (PEAK_DB / 20) / peak)


def write_wav(path, x):
    pcm = np.clip(np.round(x * 32767), -32768, 32767).astype("<i2")
    with wave.open(path, "wb") as w:
        w.setnchannels(2)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(pcm.tobytes())


def decoded_peak_db(path):
    raw = subprocess.run(["ffmpeg", "-v", "error", "-i", path, "-f", "f32le", "-"], capture_output=True, check=True).stdout
    a = np.frombuffer(raw, dtype="<f4")
    return 20 * np.log10(np.max(np.abs(a)) + 1e-12), len(a) / 2 / SR


def main():
    os.makedirs(OUT, exist_ok=True)
    bad = 0
    with tempfile.TemporaryDirectory() as tmp:
        for name, fn in SOUNDS.items():
            x = normalise(fn())
            x = signal.sosfiltfilt(signal.butter(4, 15500, fs=SR, output="sos"), x, axis=0)  # vorbis drops it anyway
            x = normalise(x)
            wav = os.path.join(tmp, name + ".wav")
            ogg = os.path.join(OUT, name + ".ogg")
            gain = 1.0
            for _ in range(4):        # sharp transients overshoot after encoding: trim until the .ogg peaks ~-3
                write_wav(wav, x * gain)
                subprocess.run(["ffmpeg", "-v", "error", "-y", "-i", wav, "-c:a", "libvorbis", "-q:a", "5", ogg], check=True)
                pk, secs = decoded_peak_db(ogg)
                if pk <= PEAK_DB + 0.3:
                    break
                gain *= 10 ** ((PEAK_DB - pk) / 20)
            ok = pk <= -1.0
            bad += 0 if ok else 1
            print("%-7s %5.2fs  peak %6.2f dBFS %s" % (name, secs, pk, "" if ok else "  <-- TOO HOT"))
    sys.exit(1 if bad else 0)


if __name__ == "__main__":
    main()
