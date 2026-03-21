SynthDef(\govMelt, {
    var sig, freqBase, harmonics, shimmer, noise, env, lfo1, lfo2;
    freqBase = \freq.kr(110) * (1.0 + ((\brightness.kr(0.5) - 0.5) * 0.3));
    lfo1 = SinOsc.kr(0.07 + (\motion.kr(0.5) * 0.15), 0, 1, 1);
    lfo2 = LFNoise2.kr(0.13, 0.4, 1.0);
    harmonics = Mix.fill(7, { |i|
        var detune = LFNoise1.kr(0.03 + (i * 0.017), 0.008, 1.0);
        var amp = (1.0 / (i + 1)) * 0.055 * lfo2;
        SinOsc.ar(freqBase * (i + 1) * detune) * amp
    });
    noise = BPF.ar(
        PinkNoise.ar(0.06),
        LFNoise2.kr(0.11, 400, 900),
        0.3
    ) * lfo1 * 0.4;
    shimmer = Ringz.ar(
        Dust.ar(8 + (\motion.kr(0.5) * 12)),
        LFNoise1.kr(0.05, 300, 700),
        0.8,
        0.04
    );
    sig = (harmonics + noise + shimmer) * 0.7;
    sig = Limiter.ar(sig, 0.75);
    SendReply.kr(Impulse.kr(30), '/audio/bass_energy', Amplitude.kr(sig));
    Out.ar(0, sig ! 2);
}).add;

SynthDef(\collapseGrid, {
    var sig, carrier, mod, tremble, crackle, wash, lfo;
    lfo = LFNoise2.kr(0.09, 0.5, 0.5);
    carrier = \carFreq.kr(220) * (1.0 + ((\hue.kr(0.5) - 0.5) * 0.25));
    mod = SinOsc.ar(
        carrier * (1.5 + (LFNoise1.kr(0.07) * 0.3)),
        0,
        carrier * (0.4 + (\brightness.kr(0.5) * 0.5))
    );
    tremble = SinOsc.ar(carrier + mod, 0, lfo * 0.5, 0.0);
    crackle = HPF.ar(
        Crackle.ar(1.75 + (\motion.kr(0.5) * 0.2), 0.12),
        1200
    ) * 0.35;
    wash = GVerb.ar(
        (tremble + crackle) * 0.5,
        roomsize: 60,
        revtime: 6.0,
        damping: 0.4,
        drylevel: 0.4,
        earlyreflevel: 0.2,
        taillevel: 0.3
    );
    sig = wash * 0.55;
    sig = Limiter.ar(sig, 0.72);
    SendReply.kr(Impulse.kr(30), '/audio/mid_energy', Amplitude.kr(sig));
    Out.ar(0, sig ! 2);
}).add;

SynthDef(\pulseOrigin, {
    var sig, trigger, tone, texture, swell, env, lfoRate;
    lfoRate = 0.5 + (\motion.kr(0.5) * 2.5);
    trigger = Impulse.kr(lfoRate + LFNoise1.kr(0.2, 0.3));
    env = EnvGen.kr(Env.perc(0.015, 0.6 + (\brightness.kr(0.5) * 1.2), 1, -3), trigger);
    tone = SinOsc.ar(
        \pulseFreq.kr(180) * (1.0 + (LFNoise2.kr(0.08) * 0.04)),
        0,
        env * 0.18
    );
    texture = RLPF.ar(
        WhiteNoise.ar(0.09),
        LFNoise2.kr(0.14, 1200, 1800),
        0.15
    ) * (env * 0.5 + 0.05);
    swell = SinOsc.ar(
        \pulseFreq.kr(180) * 2.01,
        LFNoise1.kr(0.06, 3.14),
        env * 0.07
    );
    sig = (tone + texture + swell) * 0.75;
    sig = Limiter.ar(sig, 0.70);
    SendReply.kr(Impulse.kr(30), '/audio/pulse_energy', Amplitude.kr(sig));
    Out.ar(0, sig ! 2);
}).add;

fork {
    var waitTime;
    inf.do {
        ~govMelt = Synth(\govMelt, [\freq, 110, \brightness, 0.5, \motion, 0.4]);
        ~collapseGrid = Synth(\collapseGrid, [\carFreq, 220, \hue, 0.5, \brightness, 0.5, \motion, 0.4]);
        12.0.wait;

        ~pulseOrigin = Synth(\pulseOrigin, [\pulseFreq, 165, \brightness, 0.6, \motion, 0.55]);
        8.0.wait;

        ~collapseGrid.free;
        6.0.wait;

        ~collapseGrid = Synth(\collapseGrid, [\carFreq, 176, \hue, 0.3, \brightness, 0.7, \motion, 0.65]);
        ~govMelt.set(\freq, 138, \motion, 0.65);
        9.0.wait;

        ~pulseOrigin.free;
        ~collapseGrid.free;
        4.0.wait;

        ~pulseOrigin = Synth(\pulseOrigin, [\pulseFreq, 196, \brightness, 0.4, \motion, 0.7]);
        5.0.wait;

        ~govMelt.free;
        3.0.wait;

        ~govMelt = Synth(\govMelt, [\freq, 92, \brightness, 0.45, \motion, 0.5]);
        ~pulseOrigin.free;
        7.0.wait;

        ~collapseGrid = Synth(\collapseGrid, [\carFreq, 247, \hue, 0.6, \brightness, 0.55, \motion, 0.5]);
        8.0.wait;

        ~govMelt.free;
        ~collapseGrid.free;
        2.0.wait;
    };
};