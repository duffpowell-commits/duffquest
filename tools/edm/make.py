"""The EDM soundtrack (Settings > EDM soundtrack). Each track = one seamless loop, rendered to
assets/audio/mus_edm_<name>.ogg; audio.gd plays it instead of mus_<name>.ogg when the toggle is on.

    python3 tools/edm/make.py                  # every track
    python3 tools/edm/make.py neighborhood boss --preview DIR   # some, plus 2-loop mp3 previews in DIR

Plan (Nov 18, batches 1+2 built): town day = future bass, town night = synthwave, kitchen = electro house, bosses = big room,
home/title = lo-fi house, gala = deep house, Willnot = drum & bass, date = chillwave (Brahms), credits = progressive.
DJ Vape keeps his dubstep (tools/synth_dubstep.py) in both soundtracks.
"""
import subprocess
import sys
from pathlib import Path

import numpy as np

sys.path.insert(0, str(Path(__file__).resolve().parent))
from synth import (SR, Drums, Track, env, master, note, ns, riser, saw, sine, square, supersaw, svf, tt,  # noqa: E402
                   write)

ROOT = Path(__file__).resolve().parents[2]
OUT = ROOT / "assets" / "audio"


# ------------------------------------------------------------------------------------------------ town (day)
def neighborhood():
    """Future bass, 150 BPM half-time, D major. Swelling supersaw chords, plucky lead, chopped 'vocal' lead."""
    T = Track(150, 16)
    D = Drums(11)
    chords = [[62, 66, 69, 73], [59, 62, 66, 69], [55, 59, 62, 66], [57, 61, 64, 69]]   # Dmaj7 Bm7 Gmaj7 A
    for b in range(T.bars):
        ch = chords[b % 4]
        t0 = b * T.bar
        # chord swells: each quarter note fades in (the future-bass "wub" swell), filter opens in the second half
        for q in range(4):
            n = ns(T.beat)
            amp = np.linspace(0.15, 1, n) ** 1.6
            s = sum(supersaw(note(m), n, 5, 0.014, np.random.default_rng(b * 9 + q + m)) for m in ch)
            cut = 900 + (2600 if b >= 4 else 900) * (q + 1) / 4
            T.add(svf(s, cut, 0.9) * amp * 0.16, t0 + q * T.beat, "chords")
        T.add(sine(note(ch[0] - 24), ns(T.bar)) * env(ns(T.bar), 0.01, 0.3, 0.8, 0.1) * 0.5, t0, "bass")
        # drums: half-time from bar 4
        if b >= 4:
            T.add(D.kick(), t0, "drums")
            T.add(D.kick(0.8) * 0.7, t0 + 2.5 * T.beat, "drums")
            T.add(D.snare(220, 3600), t0 + 2 * T.beat, "drums")
        for i in range(8):
            T.add(D.hat(level=0.22 if i % 2 else 0.3), t0 + i * T.beat / 2, "drums")
    # lead: pentatonic pluck phrase every 2 bars, plus a vowel-ish "vocal chop" answer
    phrase = [(0, 74), (0.75, 76), (1.5, 78), (2, 81), (2.75, 78), (3.5, 76), (4.5, 74), (5, 76), (6, 69)]
    for rep in range(T.bars // 2):
        for off, m in phrase:
            n = ns(0.28)
            p = svf(saw(note(m), n) + 0.5 * square(note(m + 12), n), 3200, 1.0) * env(n, 0.002, 0.18, 0.0, 0.05)
            T.add(p * 0.22, rep * 2 * T.bar + off * T.beat, "lead")
        if rep % 2 == 1:   # chop: formant-filtered square with vibrato, two notes
            for off, m in ((6.5, 81), (7.25, 78)):
                n = ns(0.3)
                vib = note(m) * (1 + 0.012 * np.sin(2 * np.pi * 6 * tt(n)))
                v = svf(square(vib, n), 900, 4.0, "bp") + 0.6 * svf(square(vib, n), 2300, 5.0, "bp")
                T.add(v * env(n, 0.01, 0.1, 0.6, 0.08) * 0.35, rep * 2 * T.bar + off * T.beat, "lead")
    kicks = [b * T.bar for b in range(4, T.bars)] + [b * T.bar + 2.5 * T.beat for b in range(4, T.bars)]
    duck = T.duck(kicks, 0.55, 0.25)
    return T.mix({"chords": 1.0, "lead": 1.0, "bass": 0.9, "drums": 0.95}, duck, ("chords", "bass"))


# ------------------------------------------------------------------------------------------------ town (night)
def night():
    """Synthwave, 100 BPM, A minor. Saw arpeggio, pulsing octave bass, gated snare, warm pad."""
    T = Track(100, 12)
    D = Drums(21)
    prog = [[57, 60, 64], [53, 57, 60], [48, 52, 55], [55, 59, 62]]   # Am F C G
    for b in range(T.bars):
        ch = prog[b % 4]
        t0 = b * T.bar
        n = ns(T.bar)
        pad = sum(supersaw(note(m + 12), n, 4, 0.006, np.random.default_rng(b + m)) for m in ch)
        T.add(svf(pad, 1400, 0.7) * env(n, 0.25, 0.2, 0.8, 0.3) * 0.11, t0, "pad")
        for i in range(16):   # 16th arpeggio up/down through the chord + octave
            seq = ch + [ch[0] + 12]
            m = seq[[0, 1, 2, 3, 2, 1, 0, 1][i % 8]] + 12
            ln = ns(T.beat / 4 * 0.9)
            a = svf(saw(note(m), ln), 1500 + 1200 * np.sin(np.pi * (b % 4 * 16 + i) / 64), 1.4) * env(ln, 0.002, 0.09, 0.2, 0.02)
            T.add(a * 0.14, t0 + i * T.beat / 4, "arp")
        for i in range(8):    # octave-jumping 8th bass
            m = ch[0] - 24 + (12 if i % 2 else 0)
            ln = ns(T.beat / 2 * 0.85)
            T.add(svf(saw(note(m), ln), 700, 1.0) * env(ln, 0.003, 0.15, 0.5, 0.03) * 0.45, t0 + i * T.beat / 2, "bass")
        T.add(D.kick(0.7, 8, 50) * 0.9, t0, "drums")
        T.add(D.kick(0.7, 8, 50) * 0.9, t0 + 2 * T.beat, "drums")
        T.add(D.gated_snare(), t0 + T.beat, "drums")
        T.add(D.gated_snare(), t0 + 3 * T.beat, "drums")
        for i in range(8):
            T.add(D.hat(level=0.16), t0 + i * T.beat / 2 + T.beat / 4, "drums")
    # echoed lead hook every 4 bars (simple feedback delay)
    hook = [(0, 76), (1, 74), (1.5, 72), (2, 69), (3, 71), (3.5, 72)]
    lead = np.zeros(T.n)
    for rep in range(T.bars // 4):
        for off, m in hook:
            ln = ns(T.beat * 0.6)
            s = svf(square(note(m), ln, 0.35), 2200, 0.8) * env(ln, 0.01, 0.2, 0.5, 0.1) * 0.16
            st = ns(rep * 4 * T.bar + off * T.beat)
            lead[st:st + ln] += s[: max(0, min(ln, T.n - st))]
    dl = ns(T.beat * 0.75)
    echo = lead.copy()
    for k in (1, 2, 3):
        echo += np.roll(lead, dl * k) * 0.45 ** k
    T.bus["lead"] = echo
    return T.mix({"pad": 1.0, "arp": 1.0, "bass": 0.9, "drums": 0.9, "lead": 1.0})


# ------------------------------------------------------------------------------------------------ kitchen
def kitchen():
    """Electro house, 128 BPM, E minor. Four on the floor, clap, offbeat open hats, receipt-printer ticks,
    gritty offbeat bass, chord stabs. Shift rush energy."""
    T = Track(128, 16)
    D = Drums(31)
    stabs = [[64, 67, 71], [60, 64, 67], [62, 66, 69], [59, 63, 66]]   # Em C D B
    kicks = []
    for b in range(T.bars):
        t0 = b * T.bar
        ch = stabs[b % 4]
        for q in range(4):
            T.add(D.kick(1.0, 7.5), t0 + q * T.beat, "drums")
            kicks.append(t0 + q * T.beat)
            T.add(D.hat(True, 0.22), t0 + q * T.beat + T.beat / 2, "drums")
        T.add(D.clap(), t0 + T.beat, "drums")
        T.add(D.clap(), t0 + 3 * T.beat, "drums")
        for i in range(16):
            if (i * 7 + b) % 5 != 0:                         # the ticket printer, irregular on purpose
                T.add(D.tick(), t0 + i * T.beat / 4, "drums")
        for q in range(4):                                   # offbeat growl bass
            ln = ns(T.beat / 2 * 0.9)
            f = note(ch[0] - 24)
            raw = saw(f, ln) + saw(f * 1.01, ln) + 0.5 * square(f / 2, ln)
            s = np.tanh(svf(raw, 300 + 1700 * env(ln, 0.002, 0.12, 0.2, 0.02), 2.5) * 2.5)
            T.add(s * 0.32 * env(ln, 0.002, 0.2, 0.7, 0.03), t0 + q * T.beat + T.beat / 2, "bass")
        if b >= 4:                                           # stabs on the "and" of 2 and 4
            for off in (1.5, 3.5, 3.75):
                ln = ns(0.16)
                s = sum(saw(note(m), ln) + saw(note(m) * 1.012, ln) for m in ch)
                T.add(svf(s, 2400, 1.1) * env(ln, 0.002, 0.12, 0, 0.02) * 0.11, t0 + off * T.beat, "stab")
    T.add(riser(ns(2 * T.bar), level=0.25), 2 * T.bar, "fx")
    duck = T.duck(kicks, 0.5, 0.16)
    return T.mix({"drums": 0.9, "bass": 1.0, "stab": 1.0, "fx": 1.0}, duck, ("bass", "stab"))


# ------------------------------------------------------------------------------------------------ bosses
def boss():
    """Big room, 128 BPM, F# minor. 4 bars of build (snare roll, riser, filtered lead), 12-bar drop with a huge
    supersaw lead, four-on-the-floor and offbeat bass. For alley bounties and the story exes."""
    T = Track(128, 16)
    D = Drums(41)
    BUILD = 4
    roots = [54, 50, 45, 52]   # F#m D A E (bass roots)
    melody = [(0, 78), (0.5, 78), (1, 81), (1.5, 78), (2, 76), (2.5, 73), (3, 76), (3.5, 78),
              (4, 78), (4.5, 78), (5, 81), (5.5, 83), (6, 85), (6.75, 83), (7.5, 81)]
    kicks = []
    for b in range(T.bars):
        t0 = b * T.bar
        drop = b >= BUILD
        if drop:
            for q in range(4):
                T.add(D.kick(1.1, 6.5), t0 + q * T.beat, "drums")
                kicks.append(t0 + q * T.beat)
                T.add(D.hat(True, 0.25), t0 + q * T.beat + T.beat / 2, "drums")
            T.add(D.clap(), t0 + T.beat, "drums")
            T.add(D.clap(), t0 + 3 * T.beat, "drums")
            for q in range(4):
                ln = ns(T.beat / 2 * 0.9)
                f = note(roots[b % 4] - 12)
                s = np.tanh(svf(saw(f, ln) + saw(f * 1.008, ln), 900, 1.2) * 1.8)
                T.add(s * 0.33 * env(ln, 0.003, 0.18, 0.6, 0.03), t0 + q * T.beat + T.beat / 2, "bass")
        else:
            T.add(D.kick(0.9, 8) * 0.8, t0, "drums")
            T.add(D.kick(0.9, 8) * 0.8, t0 + 2 * T.beat, "drums")
    # lead: the melody over 2 bars, filtered during the build, wide open in the drop
    for rep in range(T.bars // 2):
        t0 = rep * 2 * T.bar
        open_ = rep * 2 >= BUILD
        for off, m in melody:
            ln = ns(T.beat * 0.48)
            s = supersaw(note(m), ln, 7, 0.02, np.random.default_rng(m + rep)) + 0.5 * supersaw(note(m - 12), ln, 5, 0.015)
            cut = 5200 if open_ else 900 + 700 * rep
            T.add(svf(s, cut, 0.9) * env(ln, 0.003, 0.25, 0.5, 0.05) * (0.3 if open_ else 0.16), t0 + off * T.beat, "lead")
    # build: snare roll speeding up + riser + a one-beat gap before the drop
    pos, step = 2 * T.bar, T.beat
    while pos < BUILD * T.bar - T.beat:
        T.add(D.snare(200, 3000, 12, False) * (0.3 + 0.5 * (pos - 2 * T.bar) / (2 * T.bar)), pos, "drums")
        step = max(T.beat / 8, step * 0.8)
        pos += step
    r = riser(ns(BUILD * T.bar - T.beat), top=8000, level=0.5)
    T.add(r, 0, "fx")
    duck = T.duck(kicks, 0.6, 0.18)
    return T.mix({"drums": 0.95, "bass": 1.0, "lead": 1.0, "fx": 1.0}, duck, ("lead", "bass"))


# ------------------------------------------------------------------------------------------------ home / title
def _keys(midis, n, bright=1.0):
    """Electric-piano-ish chord: sine + a little 2nd/3rd harmonic, bell attack, slow tremolo."""
    t = tt(n)
    out = np.zeros(n)
    for m in midis:
        f = note(m)
        out += np.sin(2 * np.pi * f * t) + 0.25 * bright * np.sin(4 * np.pi * f * t) * np.exp(-t * 6) \
            + 0.1 * bright * np.sin(6 * np.pi * f * t) * np.exp(-t * 9)
    return out * (1 + 0.12 * np.sin(2 * np.pi * 4.5 * t))


def home():
    """Lo-fi house, 112 BPM, Eb major. Dusty swung drums, warm keys, round bass, vinyl crackle, low-passed."""
    T = Track(112, 12)
    D = Drums(51)
    rng = np.random.default_rng(52)
    prog = [[63, 67, 70, 74], [60, 63, 67, 70], [56, 60, 63, 67], [58, 62, 65, 68]]   # Ebmaj7 Cm7 Abmaj7 Bb7
    kicks = []
    for b in range(T.bars):
        t0 = b * T.bar
        ch = prog[b % 4]
        for off in (0, 1.75):                                  # chord hits, the second one pushed
            n = ns(T.beat * (1.6 if off == 0 else 2.0))
            T.add(_keys(ch, n, 0.8) * env(n, 0.004, 0.6, 0.4, 0.2) * 0.12, t0 + off * T.beat, "keys")
        for q, m in ((0, ch[0] - 24), (1.5, ch[0] - 24), (2.5, ch[0] - 17), (3, ch[0] - 24)):
            n = ns(T.beat * 0.45)
            T.add(sine(note(m), n) * env(n, 0.005, 0.3, 0.6, 0.05) * 0.5, t0 + q * T.beat, "bass")
        for q in range(4):
            T.add(D.kick(0.7, 9, 48) * 0.85, t0 + q * T.beat, "drums")
            kicks.append(t0 + q * T.beat)
        T.add(D.snare(180, 2200, 13) * 0.55, t0 + T.beat, "drums")
        T.add(D.snare(180, 2200, 13) * 0.55, t0 + 3 * T.beat, "drums")
        for i in range(8):                                     # swung 8th hats
            sw = 0.09 if i % 2 else 0.0
            T.add(D.hat(i == 7 and b % 2 == 1, 0.14 if i % 2 else 0.2), t0 + (i / 2 + sw) * T.beat, "drums")
    # a lazy keys melody over bars 4-11
    mel = [(0, 75), (0.5, 74), (1, 70), (2.5, 72), (3, 70), (4, 67), (5.5, 70), (6, 72), (7, 75)]
    for rep in range(2, T.bars // 2):
        for off, m in mel:
            n = ns(T.beat * 0.7)
            T.add(_keys([m], n, 1.2) * env(n, 0.003, 0.35, 0.3, 0.1) * 0.13, rep * 2 * T.bar + off * T.beat, "lead")
    crackle = np.zeros(T.n)
    pops = rng.integers(0, T.n, 260)
    crackle[pops] = rng.uniform(-1, 1, 260)
    crackle = svf(crackle, 3000, 0.7) * 2.5 + svf(rng.uniform(-1, 1, T.n), 5000, 0.7, "hp") * 0.012
    T.bus["vinyl"] = crackle
    duck = T.duck(kicks, 0.35, 0.2)
    x = T.mix({"keys": 1.0, "bass": 0.9, "drums": 0.8, "lead": 1.0, "vinyl": 1.0}, duck, ("keys", "bass"))
    return svf(x, 3600, 0.7)                                   # the tape/lo-fi roll-off


# ------------------------------------------------------------------------------------------------ gala
def gala():
    """Deep house, 122 BPM, A minor. Organ-ish m7 stabs, rubbery sub bass, shaker and rim, a filter that
    breathes over 8 bars. Black tie, bad exes."""
    T = Track(122, 12)
    D = Drums(61)
    prog = [[57, 60, 64, 67], [55, 59, 62, 65], [53, 57, 60, 64], [52, 55, 59, 62]]   # Am7 G7 Fmaj7 Em7
    kicks = []
    for b in range(T.bars):
        t0 = b * T.bar
        ch = prog[b % 4]
        cut = 900 + 1400 * (0.5 - 0.5 * np.cos(2 * np.pi * b / 8))
        for off in (0.5, 1.75, 3.0):
            n = ns(0.22)
            s = sum(square(note(m), n, 0.3) + 0.6 * sine(note(m + 12), n) for m in ch)
            T.add(svf(s, cut, 1.2) * env(n, 0.003, 0.15, 0.3, 0.05) * 0.07, t0 + off * T.beat, "stab")
        for off, d in ((0, 0.6), (0.75, 0.2), (2, 0.5), (2.75, 0.2), (3.5, 0.4)):
            n = ns(T.beat * d)
            f = note(ch[0] - 24)
            s = sine(f, n) + 0.3 * np.tanh(sine(f * 2, n) * 2)
            T.add(s * env(n, 0.004, 0.2, 0.7, 0.03) * 0.42, t0 + off * T.beat, "bass")
        for q in range(4):
            T.add(D.kick(0.9, 8, 46), t0 + q * T.beat, "drums")
            kicks.append(t0 + q * T.beat)
            T.add(D.hat(True, 0.15), t0 + (q + 0.5) * T.beat, "drums")
        for i in range(16):                                    # shaker
            T.add(svf(D.noise(ns(0.04)), 6000, 0.8, "bp") * np.exp(-tt(ns(0.04)) * 90) * (0.07 if i % 2 else 0.04),
                  t0 + i * T.beat / 4, "drums")
        T.add(D.clap() * 0.6, t0 + T.beat, "drums")
        T.add(D.clap() * 0.6, t0 + 3 * T.beat, "drums")
        T.add(D.tick(0.25), t0 + 2.75 * T.beat, "drums")       # rim
    pad = np.zeros(T.n)
    for b in range(T.bars):
        n = ns(T.bar)
        p = sum(supersaw(note(m + 12), n, 3, 0.005, np.random.default_rng(b * 3 + m)) for m in prog[b % 4][1:])
        st = ns(b * T.bar)
        pad[st:st + n] += (svf(p, 1100, 0.6) * env(n, 0.4, 0.2, 0.8, 0.4) * 0.05)[: T.n - st]
    T.bus["pad"] = pad
    duck = T.duck(kicks, 0.45, 0.2)
    return T.mix({"stab": 1.0, "bass": 1.0, "drums": 0.85, "pad": 1.0}, duck, ("stab", "bass", "pad"))


# ------------------------------------------------------------------------------------------------ Willnot
def willnot():
    """Drum & bass, 174 BPM, D minor. Two-step breaks, rolling hats, a growling reese bass, stab hits.
    The big landlord fight."""
    T = Track(174, 16)
    D = Drums(71)
    roots = [38, 38, 34, 36]   # D D Bb C
    kicks = []
    for b in range(T.bars):
        t0 = b * T.bar
        intro = b < 2
        for off in ((0, 2.5) if not intro else (0,)):
            T.add(D.kick(1.0, 9), t0 + off * T.beat, "drums")
            kicks.append(t0 + off * T.beat)
        if not intro:
            T.add(D.snare(210, 3800, 11), t0 + T.beat, "drums")
            T.add(D.snare(210, 3800, 11), t0 + 3 * T.beat, "drums")
            if b % 4 == 3:
                T.add(D.snare(230, 4200, 18, False) * 0.45, t0 + 3.75 * T.beat, "drums")
        for i in range(8):
            T.add(D.hat(i % 4 == 2, 0.09 if i % 2 else 0.13), t0 + i * T.beat / 2, "drums")
        # reese: two detuned saws, slow filter sweep, saturated
        n = ns(T.bar)
        f = note(roots[b % 4])
        r = saw(f, n) + saw(f * 1.012, n) + saw(f * 0.994, n)
        lfo = 0.5 - 0.5 * np.cos(2 * np.pi * tt(n) / T.bar * 2)
        cut = 250 + 900 * lfo if not intro else 300
        T.add(np.tanh(svf(r, cut, 1.6) * 2.2) * env(n, 0.01, 0.1, 0.9, 0.05) * 0.3, t0, "bass")
        T.add(sine(f, n) * env(n, 0.01, 0.1, 0.9, 0.05) * 0.35, t0, "bass")
        if b >= 2 and b % 2 == 0:                              # minor stab hits
            for off in (0, 0.75):
                m = roots[b % 4] + 24
                ns_ = ns(0.18)
                s = sum(saw(note(x), ns_) for x in (m, m + 3, m + 7))
                T.add(svf(s, 3000, 1.0) * env(ns_, 0.002, 0.12, 0, 0.02) * 0.1, t0 + off * T.beat, "stab")
    T.add(riser(ns(2 * T.bar), top=5000, level=0.16), 0, "fx")
    duck = T.duck(kicks, 0.4, 0.12)
    return T.mix({"drums": 0.95, "bass": 1.0, "stab": 1.0, "fx": 1.0}, duck, ("bass",))


# ------------------------------------------------------------------------------------------------ date
LULLABY = [(0.0, 64, 0.5), (0.5, 64, 0.5), (1.0, 67, 2.0), (3.0, 64, 0.5), (3.5, 64, 0.5), (4.0, 67, 2.0),
           (6.0, 64, 0.5), (6.5, 67, 0.5), (7.0, 72, 1.0), (8.0, 71, 1.5), (9.5, 69, 0.5), (10.0, 69, 1.0),
           (11.0, 67, 1.0), (12.0, 62, 0.5), (12.5, 64, 0.5), (13.0, 65, 1.0), (14.0, 62, 1.0), (15.0, 62, 0.5),
           (15.5, 64, 0.5), (16.0, 65, 2.0), (18.0, 62, 0.5), (18.5, 65, 0.5), (19.0, 71, 0.5), (19.5, 69, 0.5),
           (20.0, 67, 1.0), (21.0, 71, 1.0), (22.0, 72, 2.0)]   # same notes as dates.gd LULLABY (beats)


def date():
    """Chillwave, 90 BPM, C major. Brahms' Lullaby (public domain) on a soft square lead through a long echo,
    warbly detuned pads, lazy half-time drums. 6 bars of the tune, 4 bars of drift."""
    T = Track(90, 10)
    D = Drums(81)
    chords = [[60, 64, 67], [60, 64, 67], [55, 59, 62], [55, 59, 65], [55, 59, 65], [60, 64, 67],
              [57, 60, 64], [53, 57, 60], [60, 64, 67], [55, 59, 62]]   # C C G G7 G7 C | Am F C G
    for b in range(T.bars):
        t0 = b * T.bar
        n = ns(T.bar)
        wob = 1 + 0.004 * np.sin(2 * np.pi * 0.7 * tt(n))      # tape warble
        p = sum(supersaw(note(m) * wob, n, 4, 0.008, np.random.default_rng(b * 5 + m)) for m in chords[b])
        T.add(svf(p, 1300, 0.6) * env(n, 0.5, 0.2, 0.85, 0.5) * 0.09, t0, "pad")
        T.add(sine(note(chords[b][0] - 24), n) * env(n, 0.05, 0.3, 0.7, 0.3) * 0.4, t0, "bass")
        T.add(D.kick(0.6, 7, 50) * 0.8, t0, "drums")
        T.add(D.kick(0.6, 7, 50) * 0.5, t0 + 2.5 * T.beat, "drums")
        T.add(D.snare(170, 2000, 8) * 0.5, t0 + 2 * T.beat, "drums")
        for i in range(8):
            T.add(D.hat(level=0.1 if i % 2 else 0.14), t0 + i * T.beat / 2, "drums")
    lead = np.zeros(T.n)
    for off, m, d in LULLABY:
        ln = ns(T.beat * d * 0.95)
        s = svf(square(note(m + 12), ln, 0.4) + 0.5 * sine(note(m + 12), ln), 2400, 0.7) * env(ln, 0.02, 0.2, 0.6, 0.15)
        st = ns(off * T.beat)
        lead[st:st + ln] += (s * 0.14)[: T.n - st]
    echo = lead.copy()
    dl = ns(T.beat * 0.75)
    for k in (1, 2, 3, 4):
        echo += np.roll(svf(lead, 2400 - 400 * k, 0.7), dl * k) * 0.5 ** k
    T.bus["lead"] = echo
    return T.mix({"pad": 1.0, "bass": 0.8, "drums": 0.75, "lead": 1.0})


# ------------------------------------------------------------------------------------------------ credits
def credits():
    """Progressive house, 124 BPM, B minor. A 16th pluck arp whose filter opens over the loop, long pads,
    rolling offbeat bass, a soaring lead in the back half. Roll credits."""
    T = Track(124, 12)
    D = Drums(91)
    prog = [[59, 62, 66], [55, 59, 62], [50, 54, 57], [57, 61, 64]]   # Bm G D A
    kicks = []
    for b in range(T.bars):
        t0 = b * T.bar
        ch = prog[b % 4]
        n = ns(T.bar)
        p = sum(supersaw(note(m + 12), n, 5, 0.01, np.random.default_rng(b * 7 + m)) for m in ch)
        T.add(svf(p, 1600, 0.6) * env(n, 0.3, 0.2, 0.8, 0.3) * 0.07, t0, "pad")
        arp = ch + [ch[0] + 12, ch[1] + 12]
        for i in range(16):
            m = arp[[0, 2, 1, 3, 2, 4, 3, 2][i % 8]] + 12
            ln = ns(T.beat / 4 * 0.9)
            cut = 900 + 3200 * (b * 16 + i) / (T.bars * 16)
            T.add(svf(saw(note(m), ln) + 0.4 * square(note(m), ln), cut, 1.5) * env(ln, 0.002, 0.08, 0.1, 0.02) * 0.13,
                  t0 + i * T.beat / 4, "arp")
        for q in range(4):
            T.add(D.kick(1.0, 7.5), t0 + q * T.beat, "drums")
            kicks.append(t0 + q * T.beat)
            T.add(D.hat(True, 0.18), t0 + (q + 0.5) * T.beat, "drums")
            for k in (0.25, 0.5, 0.75):                        # rolling bass between kicks
                ln = ns(T.beat / 4 * 0.9)
                T.add(svf(saw(note(ch[0] - 24), ln), 500, 1.0) * env(ln, 0.003, 0.1, 0.5, 0.02) * 0.4,
                      t0 + (q + k) * T.beat, "bass")
        T.add(D.clap() * 0.7, t0 + T.beat, "drums")
        T.add(D.clap() * 0.7, t0 + 3 * T.beat, "drums")
    lead = [(0, 78), (1.5, 76), (2, 74), (3, 73), (4, 74), (5.5, 76), (6, 78), (7, 81)]
    for rep in range(3, T.bars // 2):
        for off, m in lead:
            ln = ns(T.beat * 0.9)
            s = supersaw(note(m), ln, 5, 0.012, np.random.default_rng(m)) * env(ln, 0.02, 0.3, 0.6, 0.2)
            T.add(svf(s, 4200, 0.8) * 0.14, rep * 2 * T.bar + off * T.beat, "lead")
    duck = T.duck(kicks, 0.5, 0.2)
    return T.mix({"pad": 1.0, "arp": 1.0, "drums": 0.9, "bass": 1.0, "lead": 1.0}, duck, ("pad", "arp", "bass", "lead"))


TRACKS = {"neighborhood": neighborhood, "night": night, "kitchen": kitchen, "boss": boss,
          "home": home, "gala": gala, "willnot": willnot, "date": date, "credits": credits}


def main(argv):
    names = [a for a in argv if not a.startswith("--") and a in TRACKS] or list(TRACKS)
    prev = Path(argv[argv.index("--preview") + 1]) if "--preview" in argv else None
    for name in names:
        x = master(TRACKS[name]())
        out = OUT / f"mus_edm_{name}.ogg"
        size = write(x, out)
        print(f"{out.name}: {len(x) / SR:.2f} s, {size // 1024} KB, rms {np.sqrt(np.mean(x ** 2)):.3f}")
        if prev:
            prev.mkdir(parents=True, exist_ok=True)
            subprocess.run(["ffmpeg", "-y", "-loglevel", "error", "-stream_loop", "1", "-i", str(out), "-c:a", "libmp3lame",
                            "-q:a", "4", str(prev / f"edm_{name}_preview.mp3")], check=True)


if __name__ == "__main__":
    main(sys.argv[1:])
