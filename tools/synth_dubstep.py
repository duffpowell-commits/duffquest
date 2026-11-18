"""DJ Vape Lord's fight music (Club Cloud 9): a dubstep loop synthesized from scratch in numpy, no samples.

    python3 tools/synth_dubstep.py assets/audio/mus_club.ogg [--wav out.wav]

140 BPM, F minor, 16 bars (27.4 s, loops seamlessly like the other mus_* tracks): 4 bars of build (filtered
stabs, hats speeding up, snare roll, noise riser, "wait for it" gap) into a 12-bar half-time drop (kick on 1,
snare on 3, wobble bass whose LFO rate changes every half bar, sub, ducked under the kick). Rendered mono at
22050 Hz and encoded to Ogg Vorbis with ffmpeg, matching the other music files.
"""
import subprocess
import sys
import wave
from pathlib import Path

import numpy as np

SR = 22050
BPM = 140.0
BEAT = 60.0 / BPM
BAR = BEAT * 4
BARS = 16
BUILD = 4
N = int(round(BAR * BARS * SR))
rng = np.random.default_rng(7)


def t_of(n):
    return np.arange(n) / SR


def note(midi):
    return 440.0 * 2 ** ((midi - 69) / 12.0)


def at(sec):
    return int(round(sec * SR))


def add(buf, sig, start):
    s = at(start) % N
    end = min(N, s + len(sig))
    buf[s:end] += sig[: end - s]
    if s + len(sig) > N:   # wrap into the loop's head so the seam keeps tails
        rest = sig[end - s:]
        buf[: len(rest)] += rest[:N]


def svf(x, cutoff, q=0.7, mode="lp"):
    """Topology-preserving state-variable filter (stable at any cutoff), per-sample cutoff in Hz."""
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


def saw(freq, n, phase=0.0):
    ph = (np.cumsum(np.broadcast_to(freq, (n,)) / SR) + phase) % 1.0
    return 2 * ph - 1


# ---------------------------------------------------------------- drums
def kick(big=True):
    n = at(0.45)
    tt = t_of(n)
    f = 45 + 110 * np.exp(-tt * 28)
    s = np.sin(2 * np.pi * np.cumsum(f) / SR) * np.exp(-tt * (6 if big else 9))
    s[: at(0.004)] += rng.uniform(-1, 1, at(0.004)) * 0.6   # click
    return np.tanh(s * 1.6)


def snare(level=1.0):
    n = at(0.5)
    tt = t_of(n)
    noise = svf(rng.uniform(-1, 1, n), 3200, 0.8, "bp") * np.exp(-tt * 9)
    body = np.sin(2 * np.pi * 190 * tt) * np.exp(-tt * 22)
    s = noise * 1.6 + body * 0.8
    # small room: two short echoes
    out = s.copy()
    for d, g in ((0.031, 0.35), (0.057, 0.25)):
        out[at(d):] += s[: n - at(d)] * g
    return out * level


def hat(open_=False):
    n = at(0.18 if open_ else 0.05)
    tt = t_of(n)
    s = svf(rng.uniform(-1, 1, n), 7500, 0.6, "hp") * np.exp(-tt * (14 if open_ else 70))
    return s * 0.35


# ---------------------------------------------------------------- tonal parts
ROOT = 29   # F1 (43.65 Hz) -> bass; chords an octave+ up
DROP_NOTES = [0, 0, 3, 0, 8, 7, 5, 3]          # semitones over F, one per half bar (F F Ab F Db C Bb Ab)
LFO_DIV = [2, 4, 3, 8, 2, 6, 4, 16]            # wobbles per half bar: 1/8, 1/16, triplets, a 1/32 screech
CHORDS = [[0, 3, 7], [-4, 0, 3], [-7, -4, 0], [-2, 2, 5]]   # Fm, Db, Bbm, Eb (relative to F3)


def wobble(start_bar, bars):
    n = at(bars * BAR)
    tt = t_of(n)
    half = BAR / 2
    seg = np.minimum((tt // half).astype(int), 10_000)
    semis = np.array(DROP_NOTES)[seg % len(DROP_NOTES)]
    freq = note(ROOT + 12) * 2 ** (semis / 12.0)
    div = np.array(LFO_DIV)[seg % len(LFO_DIV)]
    lfo_ph = (tt % half) / half * div
    lfo = 0.5 - 0.5 * np.cos(2 * np.pi * lfo_ph)            # 0..1 per wobble
    raw = saw(freq, n) * 0.6 + saw(freq * 1.007, n) * 0.5 + np.sign(np.sin(2 * np.pi * np.cumsum(freq * 0.5) / SR)) * 0.4
    cut = 90 + 2600 * lfo ** 2
    s = svf(raw, cut, 3.2, "lp")
    s = np.tanh(s * 3.0) * 0.55                               # grit
    sub = np.sin(2 * np.pi * np.cumsum(freq * 0.5) / SR) * 0.55
    return s + sub


def stabs(bars):
    """Build section: filtered minor chord stabs on the off-beats, filter opening up."""
    out = np.zeros(at(bars * BAR))
    for b in range(bars):
        ch = CHORDS[b % len(CHORDS)]
        for k in range(4):
            st = b * BAR + k * BEAT + BEAT / 2
            n = at(BEAT * 0.45)
            tt = t_of(n)
            s = sum(saw(note(ROOT + 24 + c), n) + saw(note(ROOT + 24 + c) * 1.01, n) for c in ch)
            s = svf(s, 600 + 2600 * (b * 4 + k) / (bars * 4), 1.2) * np.exp(-tt * 7) * 0.16
            add(out, s, st)
    return out


def riser(bars):
    n = at(bars * BAR)
    tt = t_of(n)
    k = tt / tt[-1]
    s = svf(rng.uniform(-1, 1, n), 300 + 6000 * k ** 2, 2.0, "bp") * k ** 1.5 * 0.5
    s += saw(note(ROOT + 24) * (1 + 3 * k ** 2), n) * k ** 2 * 0.08
    return s


def main(out_path: Path, wav_path: Path | None) -> None:
    drums = np.zeros(N)
    music = np.zeros(N)
    duck = np.ones(N)
    # ---- build: bars 0..3
    music[: at(BUILD * BAR)] += stabs(BUILD)
    add(music, riser(BUILD) * np.r_[np.ones(at(BUILD * BAR - BEAT)), np.zeros(at(BEAT))][: at(BUILD * BAR)], 0)
    for b in range(BUILD):
        add(drums, kick(False) * 0.8, b * BAR)
        add(drums, kick(False) * 0.8, b * BAR + 2 * BEAT)
        steps = 2 if b < 2 else 4
        for i in range(4 * steps):
            add(drums, hat(), b * BAR + i * BEAT / steps)
    # snare roll speeding up over the last two build bars, then one beat of silence ("wait for it")
    roll_start = (BUILD - 2) * BAR
    pos, step = roll_start, BEAT
    while pos < BUILD * BAR - BEAT:
        add(drums, snare(0.35 + 0.5 * (pos - roll_start) / (2 * BAR)), pos)
        step = max(BEAT / 8, step * 0.82)
        pos += step
    # ---- drop: bars 4..15
    d0 = BUILD * BAR
    drop_bars = BARS - BUILD
    add(music, wobble(BUILD, drop_bars), d0)
    for b in range(drop_bars):
        bt = d0 + b * BAR
        add(drums, kick() * 1.0, bt)
        if b % 2 == 1:
            add(drums, kick() * 0.8, bt + 2.5 * BEAT)
        add(drums, snare(1.0), bt + 2 * BEAT)
        for i in range(8):
            add(drums, hat(open_=(i % 4 == 3)), bt + i * BEAT / 2)
        for kb in [0.0] + ([2.5] if b % 2 == 1 else []):   # sidechain: duck the bass under each kick
            s = at(bt + kb * BEAT)
            n = at(0.22)
            duck[s:s + n] = np.minimum(duck[s:s + n], 0.25 + 0.75 * np.linspace(0, 1, n) ** 2)
    mix = music * duck + drums * 0.9
    # gentle high-pass to keep the sub tidy, then glue and limit
    mix = mix - svf(mix, 30, 0.7, "lp")
    # level-match the other mus_* tracks (RMS ~0.17, peaks under 0.85): soft-clip the transients, then scale
    mix /= np.max(np.abs(mix)) + 1e-9
    mix = np.tanh(mix * 1.5) / np.tanh(1.5)
    mix *= min(0.85, 0.18 / (np.sqrt(np.mean(mix ** 2)) + 1e-9))
    pcm = (mix * 32767).astype(np.int16)
    tmp = wav_path or out_path.with_suffix(".wav")
    with wave.open(str(tmp), "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(pcm.tobytes())
    subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-i", str(tmp), "-c:a", "libvorbis", "-q:a", "2", str(out_path)], check=True)
    if wav_path is None:
        tmp.unlink()
    print(f"{out_path}: {N / SR:.2f} s, {out_path.stat().st_size // 1024} KB")


if __name__ == "__main__":
    a = sys.argv[1:]
    wav = Path(a[a.index("--wav") + 1]) if "--wav" in a else None
    main(Path(a[0]), wav)
