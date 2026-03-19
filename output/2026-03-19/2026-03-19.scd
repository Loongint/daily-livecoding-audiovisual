SynthDef(\ledger_static, {
    var noise, filtered, pulse, env, sig, brightness, motion;
    brightness = \brightness.kr(0.5);
    motion = \motion.kr(0.5);
    noise = WhiteNoise.ar(0.15);
    noise = noise + PinkNoise.ar(0.08);
    filtered = BPF.ar(noise, LFNoise1.kr(0.3).exprange(200, 2000), 0.3);
    filtered = filtered + BPF.ar(noise, LFNoise1.kr(0.17).exprange(80, 600), 0.5);
    pulse = LFPulse.kr(0.25 + (motion * 0.15), 0, 0.05);
    env = Lag.kr(pulse, 0.8) * 0.4 + 0.6;
    sig = filtered * env * (0.3 + (brightness * 0.15));
    sig = sig.clip(-0.7, 0.7);
    SendReply.kr(Impulse.kr(30), '/audio/bass_energy', Amplitude.kr(sig));
    Out.ar(0, sig ! 2);
}).add;

SynthDef(\ledger_drone, {
    var freq, osc, sub, mod, sig, brightness, motion, hue;
    brightness = \brightness.kr(0.5);
    motion = \motion.kr(0.5);
    hue = \hue.kr(0.5);
    freq = 48 * (1.0 + (brightness * 0.04));
    mod = SinOsc.kr(0.07 + (motion * 0.05), 0, 0.8);
    osc = SinOsc.ar(freq * (1.0 + (mod * 0.003)), 0, 0.18);
    osc = osc + SinOsc.ar(freq * 1.5 * (1.0 + (hue * 0.02)), 0, 0.09);
    osc = osc + SinOsc.ar(freq * 2.0, 0, 0.05);
    sub = SinOsc.ar(freq * 0.5, 0, 0.12);
    sig = (osc + sub) * 0.5;
    sig = LPF.ar(sig, 900 + (brightness * 300));
    sig = sig.clip(-0.7, 0.7);
    SendReply.kr(Impulse.kr(30), '/audio/drone_energy', Amplitude.kr(sig));
    Out.ar(0, sig ! 2);
}).add;

SynthDef(\ledger_erasure, {
    var grain, trig, env, sig, brightness, motion, hue;
    brightness = \brightness.kr(0.5);
    motion = \motion.kr(0.5);
    hue = \hue.kr(0.5);
    trig = Impulse.kr(0.8 + (motion * 1.2));
    env = EnvGen.kr(Env.perc(0.01, 1.2, 1, -4), trig);
    grain = BPF.ar(
        WhiteNoise.ar(1.0),
        LFNoise0.kr(2).exprange(300, 3000) * (1.0 + (hue * 0.1)),
        0.15
    );
    sig = grain * env * (0.18 + (brightness * 0.08));
    sig = HPF.ar(sig, 200);
    sig = sig.clip(-0.7, 0.7);
    SendReply.kr(Impulse.kr(30), '/audio/erasure_energy', Amplitude.kr(sig));
    Out.ar(0, sig ! 2);
}).add;

fork {
    inf.do {
        ~ledger_drone = Synth(\ledger_drone);
        ~ledger_static = Synth(\ledger_static);
        12.0.wait;
        ~ledger_erasure = Synth(\ledger_erasure);
        8.0.wait;
        ~ledger_static.free;
        ~ledger_static = Synth(\ledger_static);
        10.0.wait;
        ~ledger_drone.free;
        ~ledger_drone = Synth(\ledger_drone);
        ~ledger_erasure.free;
        6.0.wait;
        ~ledger_erasure = Synth(\ledger_erasure);
        8.0.wait;
        ~ledger_static.free;
        ~ledger_drone.free;
        ~ledger_erasure.free;
        2.0.wait;
    };
};