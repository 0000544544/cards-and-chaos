import os
import glob
import math
import struct
import random
import wave

SAMPLE_RATE = 44100

def make_crossfade_loop(samples, crossfade_samples=2205): # ~50ms crossfade
    n = len(samples)
    out = list(samples)
    for i in range(crossfade_samples):
        alpha = i / crossfade_samples
        # blend end into start
        end_idx = n - crossfade_samples + i
        val = (1.0 - alpha) * samples[end_idx] + alpha * samples[i]
        out[i] = val
        out[end_idx] = val
    return out

def write_wav(path, samples):
    # Normalize to -1.5 dB peak to prevent clipping
    max_val = max(abs(s) for s in samples) if samples else 1.0
    if max_val > 0.001:
        gain = 0.84 / max_val
    else:
        gain = 1.0

    raw = bytearray()
    for s in samples:
        v = int(max(-32767, min(32767, s * gain * 32767)))
        raw.extend(struct.pack("<h", v))

    os.makedirs(os.path.dirname(path), exist_ok=True)
    with wave.open(path, "wb") as wf:
        wf.setnchannels(1)
        wf.setsampwidth(2)
        wf.setframerate(SAMPLE_RATE)
        wf.writeframes(raw)

# 1. satf_engine_rally.wav (1.5s loopable)
# 4-cyl sport rally rumble: 90 Hz, 180 Hz, 270 Hz, gritty exhaust pulses
def gen_rally():
    dur = 1.5
    total = int(SAMPLE_RATE * dur)
    samples = []
    f0 = 90.0
    for i in range(total):
        t = i / SAMPLE_RATE
        # base harmonics
        h1 = math.sin(2 * math.pi * f0 * t)
        h2 = 0.65 * math.sin(2 * math.pi * f0 * 2 * t)
        h3 = 0.45 * math.sin(2 * math.pi * f0 * 3 * t)
        h4 = 0.25 * math.sin(2 * math.pi * f0 * 4 * t)
        raw = h1 + h2 + h3 + h4
        # soft clip / cylinder distortion
        gritty = math.tanh(raw * 1.6)
        # subtle engine firing flutter (30 Hz)
        mod = 1.0 + 0.15 * math.sin(2 * math.pi * 30.0 * t)
        samples.append(gritty * mod)
    return make_crossfade_loop(samples)

# 2. satf_engine_cyber.wav (1.5s loopable)
# Futuristic electric turbine: 110 Hz drone + 220 Hz hum + 880 Hz inverter whine
def gen_cyber():
    dur = 1.5
    total = int(SAMPLE_RATE * dur)
    samples = []
    for i in range(total):
        t = i / SAMPLE_RATE
        sub = 0.8 * math.sin(2 * math.pi * 110.0 * t)
        mid = 0.5 * math.sin(2 * math.pi * 220.0 * t)
        # inverter high whine with gentle FM shimmer
        fm = 880.0 + 15.0 * math.sin(2 * math.pi * 8.0 * t)
        whine = 0.3 * math.sin(2 * math.pi * fm * t)
        # high harmonic shimmer
        whine2 = 0.15 * math.sin(2 * math.pi * (fm * 2) * t)
        samples.append(sub + mid + whine + whine2)
    return make_crossfade_loop(samples)

# 3. satf_engine_supra.wav (1.5s loopable)
# Aggressive high-rev 6-cyl JDM: 130 Hz, 260 Hz, 390 Hz, 520 Hz raspy growl
def gen_supra():
    dur = 1.5
    total = int(SAMPLE_RATE * dur)
    samples = []
    f0 = 130.0
    for i in range(total):
        t = i / SAMPLE_RATE
        h1 = 0.8 * math.sin(2 * math.pi * f0 * t)
        h2 = 0.7 * math.sin(2 * math.pi * (f0 * 2) * t)
        h3 = 0.55 * math.sin(2 * math.pi * (f0 * 3) * t)
        h4 = 0.35 * math.sin(2 * math.pi * (f0 * 4) * t)
        h5 = 0.20 * math.sin(2 * math.pi * (f0 * 6) * t)
        raw = h1 + h2 + h3 + h4 + h5
        # asymmetric wave fold for metallic exhaust raspy roar
        raspy = math.tanh(raw * 2.2) if raw >= 0 else math.tanh(raw * 1.5) * 1.1
        samples.append(raspy)
    return make_crossfade_loop(samples)

# 4. satf_engine_police.wav (1.5s loopable)
# Deep V8 rumble (75 Hz + 150 Hz) + subtle background pursuit wail
def gen_police():
    dur = 1.5
    total = int(SAMPLE_RATE * dur)
    samples = []
    for i in range(total):
        t = i / SAMPLE_RATE
        # V8 rumble
        v1 = 0.9 * math.sin(2 * math.pi * 75.0 * t)
        v2 = 0.6 * math.sin(2 * math.pi * 150.0 * t)
        v3 = 0.35 * math.sin(2 * math.pi * 225.0 * t)
        v4 = 0.25 * math.sin(2 * math.pi * 300.0 * t)
        rumble = math.tanh((v1 + v2 + v3 + v4) * 1.5)
        # faint police wail siren in background (-18 dB)
        siren_freq = 750.0 + 150.0 * math.sin(2 * math.pi * 1.5 * t)
        siren = 0.12 * math.sin(2 * math.pi * siren_freq * t)
        samples.append(rumble + siren)
    return make_crossfade_loop(samples)

# 5. satf_engine_jet.wav (1.5s loopable)
# Powerful jet roar / afterburner: pink noise + 320 Hz turbine resonance
def gen_jet():
    dur = 1.5
    total = int(SAMPLE_RATE * dur)
    random.seed(42)
    # Generate pink/filtered noise
    b0 = b1 = b2 = b3 = b4 = b5 = b6 = 0.0
    samples = []
    for i in range(total):
        t = i / SAMPLE_RATE
        white = (random.random() * 2.0 - 1.0)
        b0 = 0.99886 * b0 + white * 0.0555179
        b1 = 0.99332 * b1 + white * 0.0750759
        b2 = 0.96900 * b2 + white * 0.1538520
        b3 = 0.86650 * b3 + white * 0.3104856
        b4 = 0.55000 * b4 + white * 0.5329522
        b5 = -0.7616 * b5 - white * 0.0168980
        pink = (b0 + b1 + b2 + b3 + b4 + b5 + b6 + white * 0.5362) * 0.18
        b6 = white * 0.115926
        # Turbine whine
        turbine = 0.25 * math.sin(2 * math.pi * 320.0 * t) + 0.12 * math.sin(2 * math.pi * 640.0 * t)
        samples.append(pink + turbine)
    return make_crossfade_loop(samples)

# 6. satf_fail_tzzz.wav (0.35s)
# Dry double buzzer "TZZZ - TZZZ": two 0.12s square/saw pulses at 115 Hz and 95 Hz with 0.05s gap
def gen_fail_tzzz():
    dur = 0.35
    total = int(SAMPLE_RATE * dur)
    samples = []
    for i in range(total):
        t = i / SAMPLE_RATE
        val = 0.0
        # Pulse 1: 0.0 to 0.12s at 115 Hz
        if 0.0 <= t < 0.12:
            p = t / 0.12
            env = math.sin(math.pi * p) ** 0.5
            phase = (t * 115.0) % 1.0
            wave_val = (phase * 2.0 - 1.0) # Sawtooth
            val = wave_val * env * 0.95
        # Gap: 0.12 to 0.17s (silence)
        elif 0.12 <= t < 0.17:
            val = 0.0
        # Pulse 2: 0.17 to 0.29s at 95 Hz
        elif 0.17 <= t < 0.29:
            p = (t - 0.17) / 0.12
            env = math.sin(math.pi * p) ** 0.5
            phase = ((t - 0.17) * 95.0) % 1.0
            wave_val = (phase * 2.0 - 1.0)
            val = wave_val * env * 0.95
        else:
            val = 0.0
        samples.append(val)
    return samples

# 7. satf_hit_clean.wav (0.18s)
# Short, warm and satisfying hit: soft quick chord (C5 + E5 + G5 + C6) with exponential decay
def gen_hit_clean():
    dur = 0.18
    total = int(SAMPLE_RATE * dur)
    samples = []
    # Warm bell chord: C5 (523.25), E5 (659.25), G5 (783.99), C6 (1046.5)
    chord = [
        (523.25, 0.40),
        (659.25, 0.35),
        (783.99, 0.30),
        (1046.50, 0.18)
    ]
    for i in range(total):
        t = i / SAMPLE_RATE
        # quick attack (2ms), exponential decay
        attack = min(1.0, t / 0.002)
        decay = math.exp(-t * 24.0) # fast decay ~0.15s
        env = attack * decay
        val = 0.0
        for freq, amp in chord:
            val += amp * math.sin(2 * math.pi * freq * t)
        samples.append(val * env)
    return samples

def main():
    generators = {
        "satf_engine_rally.wav": gen_rally,
        "satf_engine_cyber.wav": gen_cyber,
        "satf_engine_supra.wav": gen_supra,
        "satf_engine_police.wav": gen_police,
        "satf_engine_jet.wav": gen_jet,
        "satf_fail_tzzz.wav": gen_fail_tzzz,
        "satf_hit_clean.wav": gen_hit_clean,
    }

    local_app_data = os.environ.get("LOCALAPPDATA", "")
    target_dirs = []

    # Find all Roblox versions content/sounds
    roblox_versions_dir = os.path.join(local_app_data, "Roblox", "Versions")
    if os.path.isdir(roblox_versions_dir):
        for root, dirs, files in os.walk(roblox_versions_dir):
            if os.path.basename(root).lower() == "sounds" and "content" in root.lower():
                target_dirs.append(root)

    # Also target local project folder for persistence
    local_sounds = os.path.abspath("sounds")
    target_dirs.append(local_sounds)

    print(f"Target directories ({len(target_dirs)}):")
    for d in target_dirs:
        print(" -", d)

    for name, gen_fn in generators.items():
        print(f"Generating {name}...")
        samples = gen_fn()
        for d in target_dirs:
            file_path = os.path.join(d, name)
            write_wav(file_path, samples)
            print(f"  -> Wrote {file_path}")

    print("\nAll audio files successfully generated and deployed!")

if __name__ == "__main__":
    main()
