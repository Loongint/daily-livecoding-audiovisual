SynthDef(\moonDrone, {
    arg freq = 55, amp = 0.18, gate = 1;
    var sig, env, lfo, brightness, motion;
    brightness = \brightness.kr(0.5);
    motion = \motion.kr(0.5);
    lfo = SinOsc.kr(0.03 + (motion * 0.04), 0, 0.3, 1.0);
    env = EnvGen.kr(Env.asr(8, 1, 12), gate, doneAction: 2);
    sig = Mix([
        SinOsc.ar(freq * (1.0 + (brightness * 0.02)), 0, 0.5),
        SinOsc.ar(freq * 1.5 * (1.0 + (motion * 0.01)), 0, 0.2),
        SinOsc.ar(freq * 2.0, 0, 0.1),
        LFNoise2.ar(0.5).range(-0.003, 0.003) + SinOsc.ar(freq * 0.5, 0, 0.15)
    ]);
    sig = sig * lfo * env * amp;
    sig = LPF.ar(sig, 400 + (brightness * 200));
    sig = sig * 0.7;
    SendReply.kr(Impulse.kr(30), '/audio/bass_energy', Amplitude.kr(sig));
    Out.ar(0, sig ! 2);
}).add;

SynthDef(\veilWash, {
    arg amp = 0.09, gate = 1;
    var sig, env, noise, lfo, brightness, hue;
    brightness = \brightness.kr(0.5);
    hue = \hue.kr(0.5);
    env = EnvGen.kr(Env.asr(14, 1, 18), gate, doneAction: 2);
    lfo = SinOsc.kr(0.02 + (hue * 0.03), 0, 0.4, 0.6);
    noise = LPF.ar(GrayNoise.ar(1), 600 + (brightness * 400));
    noise = HPF.ar(noise, 80);
    sig = noise * lfo * env * amp;
    sig = FreeVerb.ar(sig, 0.92, 0.98, 0.4);
    sig = sig * 0.6;
    SendReply.kr(Impulse.kr(30), '/audio/mid_energy', Amplitude.kr(sig));
    Out.ar(0, sig ! 2);
}).add;

SynthDef(\lunarGlint, {
    arg freq = 880, amp = 0.06, gate = 1;
    var sig, env, lfo, brightness, motion;
    brightness = \brightness.kr(0.5);
    motion = \motion.kr(0.5);
    env = EnvGen.kr(Env.asr(6, 1, 20), gate, doneAction: 2);
    lfo = SinOsc.kr(0.015 + (motion * 0.02), 0, 0.35, 0.65);
    sig = Mix([
        SinOsc.ar(freq * (1.0 + (brightness * 0.015)), 0, 0.4),
        SinOsc.ar(freq * 1.001, 0, 0.3),
        SinOsc.ar(freq * 2.0 * (1.0 + (motion * 0.008)), 0, 0.15),
        SinOsc.ar(freq * 3.0, 0, 0.06)
    ]);
    sig = sig * lfo * env * amp;
    sig = LPF.ar(sig, 2000 + (brightness * 500));
    sig = FreeVerb.ar(sig, 0.88, 0.99, 0.5);
    sig = sig * 0.55;
    SendReply.kr(Impulse.kr(30), '/audio/high_energy', Amplitude.kr(sig));
    Out.ar(0, sig ! 2);
}).add;

fork {
    inf.do { |i|
        var phase = i % 6;

        if (phase == 0) {
            ~moonDrone.free;
            ~moonDrone = Synth(\moonDrone, [\freq, 46, \amp, 0.15]);
            18.0.wait;
        };

        if (phase == 1) {
            ~veilWash.free;
            ~veilWash = Synth(\veilWash, [\amp, 0.08]);
            22.0.wait;
        };

        if (phase == 2) {
            ~lunarGlint.free;
            ~lunarGlint = Synth(\lunarGlint, [\freq, 660, \amp, 0.055]);
            16.0.wait;
        };

        if (phase == 3) {
            ~moonDrone.free;
            ~moonDrone = Synth(\moonDrone, [\freq, 55, \amp, 0.13]);
            20.0.wait;
        };

        if (phase == 4) {
            ~veilWash.free;
            ~veilWash = Synth(\veilWash, [\amp, 0.07]);
            ~lunarGlint.free;
            ~lunarGlint = Synth(\lunarGlint, [\freq, 880, \amp, 0.05]);
            24.0.wait;
        };

        if (phase == 5) {
            ~moonDrone.free;
            ~veilWash.free;
            ~lunarGlint.free;
            6.0.wait;
        };
    };
};