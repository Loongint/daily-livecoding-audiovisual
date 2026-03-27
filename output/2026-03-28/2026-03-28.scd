SynthDef(\falseGround, {
    var freq, rot, heat, shimmer, sig, env, lfo1, lfo2, bass, mid, surface;
    freq = \freq.kr(55) * (1.0 + ((~brightness ? 0.5) * 0.12));
    rot = \rot.kr(0.3) * (1.0 + ((~motion ? 0.5) * 0.4));
    heat = \heat.kr(0.6) * (1.0 + ((~hue ? 0.5) * 0.2));
    lfo1 = SinOsc.kr(rot * 0.07, 0, 0.5, 0.5);
    lfo2 = SinOsc.kr(rot * 0.13, pi * 0.6, 0.3, 0.7);
    bass = SinOsc.ar(freq, 0, 0.28 * lfo1);
    bass = bass + SinOsc.ar(freq * 1.003, pi * 0.4, 0.18 * lfo2);
    mid = SinOsc.ar(freq * 2.0, 0, 0.12 * heat);
    mid = mid + SinOsc.ar(freq * 3.01, 0, 0.07 * lfo1 * heat);
    mid = mid + SinOsc.ar(freq * 4.97, 0, 0.04 * lfo2);
    surface = LPF.ar(BrownNoise.ar(0.035 * heat), 800 + (lfo1 * 400));
    sig = bass + mid + surface;
    sig = Limiter.ar(sig, 0.72);
    sig = sig ! 2;
    SendReply.kr(Impulse.kr(20), '/audio/bass_energy', Amplitude.kr(bass));
    Out.ar(0, sig);
}).add;

SynthDef(\tautSurface, {
    var freq, motion, bright, hum, ribbon, creak, mod, carrier, sig, pan1, pan2;
    freq = \freq.kr(220) * (1.0 + ((~brightness ? 0.5) * 0.08));
    motion = \motion.kr(0.5);
    bright = \bright.kr(0.5);
    mod = SinOsc.kr(0.11 + (motion * 0.05), 0, 18 + (motion * 8), freq);
    carrier = SinOsc.ar(mod, 0, 0.09 * (0.6 + (bright * 0.4)));
    hum = SinOsc.ar(freq * 0.5, 0, 0.07);
    hum = hum + SinOsc.ar(freq * 0.501, pi * 0.5, 0.05);
    ribbon = BPF.ar(
        PinkNoise.ar(0.9),
        freq * (1.8 + (SinOsc.kr(0.17, 0, 0.3, 1.0))),
        0.04 + (motion * 0.03),
        0.11 * bright
    );
    creak = BPF.ar(
        WhiteNoise.ar(0.4),
        1200 + (LFNoise1.kr(0.4) * 400),
        0.02,
        0.025 * motion
    );
    pan1 = SinOsc.kr(0.06, 0, 0.45);
    pan2 = SinOsc.kr(0.09, pi, 0.45);
    sig = Pan2.ar(carrier + hum, pan1) + Pan2.ar(ribbon + creak, pan2);
    sig = HPF.ar(sig, 40);
    sig = Limiter.ar(sig, 0.65);
    SendReply.kr(Impulse.kr(20), '/audio/mid_energy', Amplitude.kr(carrier + hum));
    Out.ar(0, sig);
}).add;

SynthDef(\giltSkin, {
    var freq, bright, hue, grain, sparkle, slow, fast, texture, crackle, sig;
    freq = \freq.kr(880) * (1.0 + ((~brightness ? 0.5) * 0.15));
    bright = \bright.kr(0.5) * (~brightness ? 0.5);
    hue = \hue.kr(0.5) * (~hue ? 0.5);
    slow = SinOsc.kr(0.08, 0, 0.4, 0.6);
    fast = SinOsc.kr(0.43, pi * 0.3, 0.2, 0.8);
    grain = GrainIn.ar(
        2,
        Impulse.kr(4 + (slow * 3)),
        0.08 + (fast * 0.06),
        SinOsc.ar(freq * (1.0 + (LFNoise2.kr(0.3) * 0.015)), 0, 0.06 * slow)
    );
    sparkle = SinOsc.ar(
        freq * [1.0, 1.414, 1.732, 2.236],
        0,
        [0.04, 0.025, 0.018, 0.012] * fast * bright
    ).sum;
    texture = HPF.ar(
        LPF.ar(WhiteNoise.ar(0.12 * hue), freq * 2.5),
        freq * 0.8
    ) * slow;
    crackle = Dust.ar(2.5 + (fast * 4), 0.03 * bright);
    sig = grain + sparkle + texture + crackle;
    sig = LPF.ar(sig, 6000);
    sig = Limiter.ar(sig, 0.55);
    sig = sig ! 2;
    SendReply.kr(Impulse.kr(20), '/audio/high_energy', Amplitude.kr(sparkle + crackle));
    Out.ar(0, sig);
}).add;

fork {
    var waitTime;
    ~falseGround = Synth(\falseGround, [\freq, 52, \rot, 0.28, \heat, 0.65]);
    3.0.wait;
    ~tautSurface = Synth(\tautSurface, [\freq, 218, \motion, 0.45, \bright, 0.55]);
    5.0.wait;
    ~giltSkin = Synth(\giltSkin, [\freq, 870, \bright, 0.5, \hue, 0.55]);
    inf.do { |i|
        waitTime = 14.0 + (i % 4 * 3.0);
        waitTime.wait;
        ~falseGround.free;
        1.2.wait;
        ~falseGround = Synth(\falseGround, [
            \freq, 52 + ((i % 3) * 4),
            \rot, 0.22 + ((i % 5) * 0.04),
            \heat, 0.55 + ((i % 4) * 0.08)
        ]);
        (waitTime * 0.6).wait;
        ~tautSurface.free;
        0.8.wait;
        ~tautSurface = Synth(\tautSurface, [
            \freq, 215 + ((i % 7) * 6),
            \motion, 0.38 + ((i % 5) * 0.06),
            \bright, 0.48 + ((i % 3) * 0.08)
        ]);
        (waitTime * 0.45).wait;
        ~giltSkin.free;
        1.0.wait;
        ~giltSkin = Synth(\giltSkin, [
            \freq, 860 + ((i % 6) * 22),
            \bright, 0.44 + ((i % 4) * 0.06),
            \hue, 0.46 + ((i % 5) * 0.07)
        ]);
        2.0.wait;
    };
};