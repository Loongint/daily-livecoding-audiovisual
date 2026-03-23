SynthDef(\groundPressure, {
    var sig, freq, layers, compress, residue, env, motion, brightness;
    motion = \motion.kr(0.5);
    brightness = \brightness.kr(0.5);
    freq = \freq.kr(55) * (1.0 + (brightness * 0.3));
    layers = Array.fill(8, { |i|
        var ratio = [1, 1.5, 2, 2.5, 3, 4, 5, 7].at(i);
        var phase = LFNoise2.kr(0.08 + (i * 0.03)) * 0.4;
        var amp = (1.0 / (i + 1)) * LFNoise1.kr(0.12 + (i * 0.02)).range(0.4, 1.0);
        SinOsc.ar(freq * ratio + (LFNoise2.kr(0.15) * freq * 0.02), phase) * amp
    });
    sig = layers.sum * 0.07;
    compress = Compander.ar(sig, sig,
        thresh: 0.2,
        slopeBelow: 1.0,
        slopeAbove: 0.15,
        clampTime: 0.005,
        relaxTime: 0.08
    );
    residue = BPF.ar(
        WhiteNoise.ar(0.04),
        freq * (6 + (LFNoise2.kr(0.3) * 2)),
        0.08
    ) * LFNoise1.kr(2.5 + (motion * 4)).range(0.0, 1.0);
    sig = (compress * 0.7) + (residue * 0.3);
    sig = Limiter.ar(sig, 0.75);
    SendReply.kr(Impulse.kr(30), '/audio/bass_energy', Amplitude.kr(sig));
    Out.ar(0, sig ! 2);
}).add;

SynthDef(\internalArg, {
    var sig, carrier, mod, feedback, tremble, crackle, motion, brightness;
    motion = \motion.kr(0.5);
    brightness = \brightness.kr(0.5);
    feedback = LocalIn.ar(1) * 0.35;
    carrier = LFSaw.ar(
        \freq.kr(120) * (1.0 + (brightness * 0.15)) + feedback,
        0,
        0.4
    );
    mod = SinOsc.ar(
        \freq.kr(120) * 3.7 + (LFNoise2.kr(0.4) * 15),
        0,
        40 + (motion * 25)
    );
    carrier = SinOsc.ar(
        \freq.kr(120) * (1.0 + (brightness * 0.15)) + mod + feedback
    );
    LocalOut.ar(carrier * 0.3);
    tremble = (1.0 - LFPulse.kr(
        (2.5 + (motion * 6)) * LFNoise1.kr(0.2).range(0.7, 1.3),
        0,
        0.3
    )) * LFNoise1.kr(0.8).range(0.3, 1.0);
    sig = carrier * tremble * 0.25;
    crackle = Dust.ar(12 + (motion * 30)) * LFNoise0.ar(40).range(0.0, 1.0) * 0.15;
    crackle = HPF.ar(crackle, 800);
    sig = sig + crackle;
    sig = RLPF.ar(sig, 1200 + (brightness * 2000) + (LFNoise2.kr(1.5) * 600), 0.4);
    sig = Limiter.ar(sig, 0.72);
    SendReply.kr(Impulse.kr(30), '/audio/mid_energy', Amplitude.kr(sig));
    Out.ar(0, [sig, DelayC.ar(sig, 0.05, 0.017 + (LFNoise1.kr(0.6) * 0.008))]);
}).add;

SynthDef(\peripheralDecay, {
    var sig, noise, bright, flicker, scatter, tail, motion, brightness;
    motion = \motion.kr(0.5);
    brightness = \brightness.kr(0.5);
    noise = WhiteNoise.ar(1.0);
    bright = HPF.ar(noise, 2800 + (brightness * 3500));
    bright = BPF.ar(bright, 4500 + (brightness * 4000) + (LFNoise2.kr(0.7) * 1500), 0.35);
    flicker = LFNoise1.kr(8 + (motion * 18)).range(0.0, 1.0);
    flicker = flicker * LFNoise0.kr(22 + (motion * 30)).range(0.2, 1.0);
    sig = bright * flicker * 0.18;
    scatter = Array.fill(5, { |i|
        var dtime = 0.04 + (i * 0.028) + (LFNoise1.kr(0.1 + (i * 0.07)) * 0.015);
        var fb = 0.25 + (i * 0.08);
        CombC.ar(sig, 0.3, dtime, dtime * (4.0 - (i * 0.5))) * (0.3 / (i + 1))
    });
    tail = scatter.sum;
    sig = (sig * 0.5) + (tail * 0.5);
    sig = Limiter.ar(sig, 0.65);
    SendReply.kr(Impulse.kr(30), '/audio/high_energy', Amplitude.kr(sig));
    Out.ar(0, [sig, sig * LFNoise1.kr(0.3).range(0.6, 1.0)]);
}).add;

fork {
    var waitTime;
    ~groundPressure = Synth(\groundPressure, [\freq, 52, \motion, 0.5, \brightness, 0.5]);
    ~internalArg = Synth(\internalArg, [\freq, 118, \motion, 0.5, \brightness, 0.5]);
    3.0.wait;
    ~peripheralDecay = Synth(\peripheralDecay, [\motion, 0.5, \brightness, 0.5]);

    inf.do { |i|
        var phase = (i % 8);

        if (phase == 0) {
            ~groundPressure.free;
            ~groundPressure = Synth(\groundPressure, [
                \freq, [48, 52, 55, 58].choose,
                \motion, 0.3 + (~motion ? 0.5) * 0.5,
                \brightness, 0.2 + (~brightness ? 0.5) * 0.3
            ]);
        };

        if (phase == 2) {
            ~internalArg.free;
            ~internalArg = Synth(\internalArg, [
                \freq, [110, 118, 125, 134].choose,
                \motion, 0.5 + (~motion ? 0.5) * 0.4,
                \brightness, 0.4 + (~brightness ? 0.5) * 0.4
            ]);
        };

        if (phase == 4) {
            ~peripheralDecay.free;
            ~peripheralDecay = Synth(\peripheralDecay, [
                \motion, 0.6 + (~motion ? 0.5) * 0.35,
                \brightness, 0.5 + (~brightness ? 0.5) * 0.45
            ]);
        };

        if (phase == 6) {
            ~groundPressure.set(
                \motion, 0.7 + (~motion ? 0.5) * 0.25,
                \brightness, 0.6 + (~brightness ? 0.5) * 0.35
            );
            ~internalArg.set(
                \motion, 0.65 + (~motion ? 0.5) * 0.3,
                \brightness, 0.55 + (~brightness ? 0.5) * 0.4
            );
        };

        waitTime = [4.5, 5.5, 6.0, 4.0, 7.0, 5.0, 6.5, 4.5].at(phase);
        waitTime.wait;
    };
};