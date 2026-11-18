"""Shared synth kit for the EDM soundtrack (Nov 18, Duff: "layout an EDM themed soundtrack", toggle in Settings).

Pure numpy, no samples. Everything renders mono at 22050 Hz like the other mus_* tracks; `Track` holds one loop
and wraps tails past the end back into the start so the loop seam keeps its reverb/decays.
"""
import subprocess
import wave
from pathlib import Path

import numpy as np

SR = 22050


def note(midi):
    return 440.0 * 2 ** ((np.asarray(midi, float) - 69) / 12.0)


def tt(n):
    return np.arange(n) / SR


def ns(sec):
    return int(round(sec * SR))


def svf(x, cutoff, q=0.7, mode="lp"):
    """Topology-preserving state-variable filter, stable at any cutoff; cutoff per sample (Hz) or constant."""
    cutoff = np.broadcast_to(np.asarray(cutoff, float), x.shape)
    g = np.tan(np.pi * np.clip(cutoff, 20, SR * 0.45) / SR)
    k = 1.0 / q
    a1 = 1.0 / (1.0 + g * (g + k))
    a2 = g * a1
    a3 = g * a2
    ic1 = ic2 = 0.0
    out = np.empty_like(x)
    m = 0 if mode == "lp" else (1 if mode == "bp" else 2)
    for i in range(len(x)):
        v3 = x[i] - ic2
        v1 = a1[i] * ic1 + a2[i] * v3
        v2 = ic2 + a2[i] * ic1 + a3[i] * v3
        ic1 = 2 * v1 - ic1
        ic2 = 2 * v2 - ic2
        out[i] = v2 if m == 0 else (v1 if m == 1 else x[i] - k * v1 - v2)
    return out


def phase(freq, n, ph0=0.0):
    return (np.cumsum(np.broadcast_to(np.asarray(freq, float), (n,)) / SR) + ph0) % 1.0


def saw(freq, n, ph0=0.0):
    return 2 * phase(freq, n, ph0) - 1


def square(freq, n, pw=0.5):
    return np.where(phase(freq, n) < pw, 1.0, -1.0)


def sine(freq, n):
    return np.sin(2 * np.pi * phase(freq, n))


def supersaw(freq, n, voices=5, detune=0.012, rng=None):
    rng = rng or np.random.default_rng(1)
    out = np.zeros(n)
    for v in range(voices):
        d = (v - (voices - 1) / 2) / max(1, (voices - 1) / 2) * detune
        out += saw(np.asarray(freq) * (1 + d), n, rng.random())
    return out / voices


def env(n, a=0.005, d=0.1, s=0.0, r=0.05, hold=None):
    """ADSR over n samples; hold = sustain length (default: until release)."""
    a_n, d_n, r_n = ns(a), ns(d), ns(r)
    hold_n = max(0, n - a_n - d_n - r_n) if hold is None else ns(hold)
    e = np.concatenate([np.linspace(0, 1, max(1, a_n)), np.linspace(1, s, max(1, d_n)),
                        np.full(hold_n, s), np.linspace(s, 0, max(1, r_n))])
    return np.pad(e, (0, max(0, n - len(e))))[:n]


# ---------------------------------------------------------------- drums
class Drums:
    def __init__(self, seed=7):
        self.rng = np.random.default_rng(seed)

    def noise(self, n):
        return self.rng.uniform(-1, 1, n)

    def kick(self, punch=1.0, decay=7.0, low=45.0):
        n = ns(0.42)
        t = tt(n)
        f = low + 120 * punch * np.exp(-t * 30)
        s = np.sin(2 * np.pi * np.cumsum(f) / SR) * np.exp(-t * decay)
        s[: ns(0.003)] += self.noise(ns(0.003)) * 0.5
        return np.tanh(s * 1.7)

    def snare(self, tone=190.0, bright=3200.0, decay=10.0, room=True):
        n = ns(0.45)
        t = tt(n)
        s = svf(self.noise(n), bright, 0.8, "bp") * np.exp(-t * decay) * 1.6 + np.sin(2 * np.pi * tone * t) * np.exp(-t * 24) * 0.7
        if room:
            o = s.copy()
            for d, g in ((0.029, 0.35), (0.053, 0.25), (0.081, 0.15)):
                o[ns(d):] += s[: n - ns(d)] * g
            s = o
        return s

    def gated_snare(self):
        """80s gated-reverb snare (synthwave): a big noisy tail chopped off hard."""
        n = ns(0.32)
        t = tt(n)
        tail = svf(self.noise(n), 2400, 0.6, "bp") * 1.4
        gate = np.where(t < 0.22, 1.0, np.exp(-(t - 0.22) * 90))
        body = np.sin(2 * np.pi * 180 * t) * np.exp(-t * 20)
        return (tail * gate * (0.55 + 0.45 * np.exp(-t * 6)) + body) * 0.8

    def clap(self):
        n = ns(0.3)
        t = tt(n)
        burst = np.zeros(n)
        for off in (0.0, 0.011, 0.022):
            burst[ns(off):] += np.exp(-(t[: n - ns(off)]) * 60)
        burst += np.exp(-t * 14) * 0.5
        return svf(self.noise(n), 1500, 0.9, "bp") * burst * 1.4

    def hat(self, open_=False, level=0.3):
        n = ns(0.2 if open_ else 0.05)
        t = tt(n)
        return svf(self.noise(n), 7800, 0.6, "hp") * np.exp(-t * (13 if open_ else 75)) * level

    def tick(self, level=0.18):
        """Receipt-printer tick (kitchen): a tiny high, dry click."""
        n = ns(0.018)
        return svf(self.noise(n), 6000, 2.0, "bp") * np.exp(-tt(n) * 220) * level


def riser(n, rng=None, top=7000.0, level=0.45):
    rng = rng or np.random.default_rng(3)
    k = tt(n) / max(1e-9, tt(n)[-1])
    return svf(rng.uniform(-1, 1, n), 300 + top * k ** 2, 2.0, "bp") * k ** 1.6 * level


# ---------------------------------------------------------------- the loop canvas
class Track:
    def __init__(self, bpm, bars, beats_per_bar=4):
        self.bpm = bpm
        self.beat = 60.0 / bpm
        self.bar = self.beat * beats_per_bar
        self.bars = bars
        self.n = ns(self.bar * bars)
        self.bus = {}

    def at(self, sec):
        return ns(sec) % self.n

    def add(self, sig, start, bus="main", gain=1.0):
        b = self.bus.setdefault(bus, np.zeros(self.n))
        s = self.at(start)
        sig = np.asarray(sig) * gain
        end = min(self.n, s + len(sig))
        b[s:end] += sig[: end - s]
        rest = sig[end - s:]
        while len(rest):                       # wrap into the loop's head
            k = min(self.n, len(rest))
            b[:k] += rest[:k]
            rest = rest[k:]

    def duck(self, times, depth=0.7, length=0.2):
        """Sidechain curve: 1 everywhere, dipping after each kick time."""
        d = np.ones(self.n)
        nl = ns(length)
        curve = 1 - depth + depth * np.linspace(0, 1, nl) ** 2
        for t0 in times:
            s = self.at(t0)
            seg = min(nl, self.n - s)
            d[s:s + seg] = np.minimum(d[s:s + seg], curve[:seg])
        return d

    def mix(self, gains=None, duck=None, ducked=()):
        gains = gains or {}
        out = np.zeros(self.n)
        for name, sig in self.bus.items():
            g = gains.get(name, 1.0)
            out += sig * g * (duck if (duck is not None and name in ducked) else 1.0)
        return out


def master(x, rms=0.17, drive=1.5):
    x = x - svf(x, 28, 0.7, "lp")                       # tidy sub rumble
    x = x / (np.max(np.abs(x)) + 1e-9)
    x = np.tanh(x * drive) / np.tanh(drive)
    return x * min(0.85, rms / (np.sqrt(np.mean(x ** 2)) + 1e-9))


def write(x, ogg: Path, wav: Path | None = None) -> int:
    pcm = (np.clip(x, -1, 1) * 32767).astype(np.int16)
    tmp = wav or ogg.with_suffix(".tmp.wav")
    with wave.open(str(tmp), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(pcm.tobytes())
    subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", str(tmp), "-c:a", "libvorbis", "-q:a", "2", str(ogg)], check=True)
    if wav is None:
        tmp.unlink()
    return ogg.stat().st_size
