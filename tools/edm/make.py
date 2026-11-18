"""The EDM soundtrack (Settings > EDM soundtrack). Each track = one seamless loop, rendered to
assets/audio/mus_edm_<name>.ogg; audio.gd plays it instead of mus_<name>.ogg when the toggle is on.

    python3 tools/edm/make.py                  # every track
    python3 tools/edm/make.py neighborhood boss --preview DIR   # some, plus 2-loop mp3 previews in DIR

Plan (Nov 18): town day = future bass, town night = synthwave, kitchen = electro house, bosses = big room,
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


TRACKS = {"neighborhood": neighborhood, "night": night, "kitchen": kitchen, "boss": boss}


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
