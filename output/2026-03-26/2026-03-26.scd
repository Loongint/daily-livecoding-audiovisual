SynthDef(\thermalDrone, {
    var freq, sig, shimmer, heat, thermal, chaos, lfo1, lfo2, env;
    freq = \freq.kr(110) * (1.0 + ((\brightness.kr(0.5) - 0.5) * 0.3));
    lfo1 = SinOsc.kr(0.07 + (\motion.kr(0.5) * 0.15));
    lfo2 = LFNoise2.kr(0.4 + (\hue.kr(0.5) * 0.6));
    heat = [1, 1.5, 2.01, 3.0, 4.02, 5.97, 7.98].collect({ |ratio, i|
        var phase = SinOsc.kr(0.03 + (i * 0.011)) * 0.015;
        SinOsc.ar(freq * ratio * (1 + phase)) * (0.07 - (i * 0.007))
    }).sum;
    thermal = BPF.ar(
        WhiteNoise.ar(0.04),
        LFNoise1.kr(0.8).exprange(200, 900),
        0.12
    );
    chaos = LFNoise2.kr(2.3 + (lfo2 * 1.5)).range(0.85, 1.0);
    sig = (heat + thermal) * chaos;
    sig = Limiter.ar(sig * 0.9, 0.72);
    SendReply.kr(Impulse.kr(30), '/audio/bass_energy', Amplitude.kr(sig));
    Out.ar(0, sig ! 2);
}).add;

SynthDef(\regulationStutter, {
    var sig, carrier, mod, tremble, gate, rhythm, flutter, burst;
    var baseFreq = \freq.kr(220) * (1.0 + ((\brightness.kr(0.5) - 0.5) * 0.25));
    rhythm = LFNoise0.kr(3.5 + (\motion.kr(0.5) * 4.0));
    flutter = LFPulse.kr(
        LFNoise1.kr(0.6).range(1.5, 11.0),
        0,
        LFNoise1.kr(0.3).range(0.25, 0.75)
    );
    mod = SinOsc.ar(
        LFNoise1.kr(0.9).range(18, 55)
    ) * LFNoise1.kr(1.2).range(8, 35);
    carrier = SinOsc.ar(baseFreq + mod) * 0.18;
    tremble = (flutter * rhythm.range(0.3, 1.0)).max(0);
    burst = Dust.ar(12 + (\hue.kr(0.5) * 18)) * 0.12;
    burst = Resonz.ar(burst,
        LFNoise0.kr(4).exprange(300, 2200),
        0.08
    );
    sig = (carrier * tremble) + burst;
    sig = sig * LFNoise2.kr(0.15).range(0.6, 1.0);
    sig = Limiter.ar(sig * 0.88, 0.68);
    SendReply.kr(Impulse.kr(30), '/audio/mid_energy', Amplitude.kr(sig));
    Out.ar(0, Pan2.ar(sig, LFNoise1.kr(0.25).range(-0.5, 0.5)));
}).add;

SynthDef(\collapseSurface, {
    var sig, noise, filtered, crackle, sweep, melt, hpf_cut;
    hpf_cut = \freq.kr(1800) * (1.0 + ((\hue.kr(0.5) - 0.5) * 0.4));
    noise = WhiteNoise.ar(0.15);
    filtered = HPF.ar(noise, LFNoise1.kr(0.35).range(hpf_cut, hpf_cut * 1.8));
    filtered = BPF.ar(filtered,
        LFNoise2.kr(0.6 + (\motion.kr(0.5) * 1.2)).exprange(800, 3500),
        0.25
    );
    crackle = Dust.ar(30 + (\brightness.kr(0.5) * 50)) * 0.18;
    crackle = RLPF.ar(crackle,
        LFNoise0.kr(8).exprange(400, 4000),
        0.15
    );
    sweep = SinOsc.ar(
        LFNoise2.kr(0.12).exprange(55, 180)
    ) * LFNoise1.kr(0.4).range(0.0, 0.09);
    melt = LFNoise2.kr(0.08).range(0.5, 1.0);
    sig = (filtered * 0.55 + crackle + sweep) * melt;
    sig = Limiter.ar(sig * 0.85, 0.65);
    SendReply.kr(Impulse.kr(30), '/audio/high_energy', Amplitude.kr(sig));
    Out.ar(0, Pan2.ar(sig, LFNoise2.kr(0.18).range(-0.7, 0.7)));
}).add;

fork {
    inf.do {
        ~thermalDrone = Synth(\thermalDrone, [\freq, 98]);
        ~regulationStutter = Synth(\regulationStutter, [\freq, 210]);
        8.0.wait;
        ~collapseSurface = Synth(\collapseSurface, [\freq, 1600]);
        6.0.wait;
        ~regulationStutter.free;
        5.0.wait;
        ~regulationStutter = Synth(\regulationStutter, [\freq, 185]);
        4.0.wait;
        ~collapseSurface.free;
        3.0.wait;
        ~thermalDrone.free;
        ~regulationStutter.free;
        1.5.wait;
        ~thermalDrone = Synth(\thermalDrone, [\freq, 110]);
        4.0.wait;
        ~regulationStutter = Synth(\regulationStutter, [\freq, 230]);
        ~collapseSurface = Synth(\collapseSurface, [\freq, 1900]);
        7.0.wait;
        ~thermalDrone.free;
        2.0.wait;
        ~thermalDrone = Synth(\thermalDrone, [\freq, 92]);
        5.0.wait;
        ~collapseSurface.free;
        ~regulationStutter.free;
        2.0.wait;
        ~thermalDrone.free;
        1.0.wait;
    };
};