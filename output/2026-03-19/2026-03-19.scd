SynthDef(\ledger_pulse, {
    arg freq = 48, amp = 0.18, gate = 1;
    var env, pulse, sub, noise, sig, brightness_mod, motion_mod;
    brightness_mod = 1.0 + ((~brightness ? 0.5) * 0.4);
    motion_mod = 0.5 + ((~motion ? 0.5) * 0.8);
    env = EnvGen.kr(Env.asr(4.0, 1.0, 6.0), gate, doneAction: 2);
    pulse = LFPulse.ar(freq * brightness_mod * 0.5, 0, 0.12) * 0.6;
    pulse = pulse + LFPulse.ar(freq * brightness_mod, 0, 0.08) * 0.3;
    sub = SinOsc.ar(freq * 0.5 * brightness_mod) * 0.5;
    noise = BPF.ar(
        WhiteNoise.ar(0.15),
        LFNoise1.kr(0.08).exprange(200, 900),
        0.04
    ) * motion_mod;
    sig = (pulse + sub + noise) * env * amp;
    sig = sig.clip2(0.7) * 0.85;
    sig = LPF.ar(sig, 2800);
    SendReply.kr(Impulse.kr(30), '/audio/bass_energy', Amplitude.kr(sig));
    Out.ar(0, sig ! 2);
}).add;

SynthDef(\static_compliance, {
    arg amp = 0.09, gate = 1;
    var env, static_noise, filtered, comb1, comb2, sig, hue_mod, brightness_mod;
    hue_mod = 0.3 + ((~hue ? 0.5) * 1.4);
    brightness_mod = 0.4 + ((~brightness ? 0.5) * 0.9);
    env = EnvGen.kr(Env.asr(8.0, 1.0, 10.0), gate, doneAction: 2);
    static_noise = WhiteNoise.ar(1.0);
    filtered = BPF.ar(static_noise, LFNoise2.kr(0.05).exprange(300, 3200), 0.15);
    filtered = filtered + BPF.ar(static_noise, LFNoise2.kr(0.03).exprange(80, 400), 0.08) * 0.6;
    comb1 = CombL.ar(filtered, 0.5, 0.23 * hue_mod, 4.2) * 0.4;
    comb2 = CombL.ar(filtered, 0.5, 0.37 * hue_mod, 6.8) * 0.3;
    sig = (filtered * 0.3 + comb1 + comb2) * env * amp * brightness_mod;
    sig = sig.clip2(0.6) * 0.88;
    sig = HPF.ar(sig, 60);
    sig = LPF.ar(sig, 5500);
    SendReply.kr(Impulse.kr(30), '/audio/mid_energy', Amplitude.kr(sig));
    Out.ar(0, [sig, sig * LFNoise1.kr(0.07).range(0.6, 1.0)]);
}).add;

SynthDef(\erased_signal, {
    arg freq = 220, amp = 0.07, gate = 1;
    var env, tone, ghost, shimmer, sig, motion_mod, hue_mod;
    motion_mod = 0.2 + ((~motion ? 0.5) * 1.6);
    hue_mod = 0.5 + ((~hue ? 0.5) * 1.0);
    env = EnvGen.kr(Env.asr(12.0, 1.0, 14.0), gate, doneAction: 2);
    tone = SinOsc.ar(
        freq * hue_mod * LFNoise2.kr(0.04).range(0.97, 1.03),
        0,
        0.5
    );
    tone = tone + SinOsc.ar(freq * hue_mod * 2.01, 0, 0.18);
    tone = tone + SinOsc.ar(freq * hue_mod * 3.0, 0, 0.07);
    ghost = tone * LFNoise2.kr(motion_mod * 0.15).range(0.0, 0.6);
    shimmer = Ringz.ar(
        Dust.ar(motion_mod * 1.2) * 0.3,
        LFNoise1.kr(0.06).exprange(800, 4000),
        0.8
    ) * 0.25;
    sig = (ghost + shimmer) * env * amp;
    sig = sig.clip2(0.55) * 0.9;
    sig = LPF.ar(sig, 6000);
    sig = HPF.ar(sig, 40);
    SendReply.kr(Impulse.kr(30), '/audio/high_energy', Amplitude.kr(sig));
    Out.ar(0, [sig, DelayL.ar(sig, 0.5, 0.018)]);
}).add;

fork {
    ~ledger = Synth(\ledger_pulse);
    ~static_comp = Synth(\static_compliance);
    12.0.wait;
    ~erased = Synth(\erased_signal);
    18.0.wait;
    inf.do {
        ~ledger.free;
        4.0.wait;
        ~ledger = Synth(\ledger_pulse);
        10.0.wait;
        ~static_comp.free;
        6.0.wait;
        ~static_comp = Synth(\static_compliance);
        8.0.wait;
        ~erased.free;
        5.0.wait;
        ~erased = Synth(\erased_signal);
        14.0.wait;
    };
};