SynthDef(\feverThreshold, {
    var sig, freq, pressure, shimmer, collapse, brightness, motion, hue;
    brightness = \brightness.kr(0.5);
    motion = \motion.kr(0.5);
    hue = \hue.kr(0.5);
    freq = \freq.kr(220) * (1.0 + (brightness * 0.3));
    pressure = LFNoise2.kr(0.3 + (motion * 0.5)).range(0.85, 1.15);
    shimmer = Mix.fill(8, { |i|
        var f = freq * (i + 1) * pressure * LFNoise1.kr(0.1 + (i * 0.07)).range(0.998, 1.002);
        SinOsc.ar(f) * (1.0 / (i + 1).sqrt) * 0.06
    });
    collapse = HPF.ar(BrownNoise.ar(0.015 + (hue * 0.01)), 800 + (pressure * 200));
    sig = shimmer + collapse;
    sig = sig * LFNoise2.kr(0.15 + (motion * 0.2)).range(0.7, 1.0);
    sig = Limiter.ar(sig, 0.85);
    SendReply.kr(Impulse.kr(30), '/audio/bass_energy', Amplitude.kr(sig));
    Out.ar(0, sig ! 2);
}).add;

SynthDef(\criticalTremor, {
    var sig, carrier, mod, tremble, heat, brightness, motion, hue;
    brightness = \brightness.kr(0.5);
    motion = \motion.kr(0.5);
    hue = \hue.kr(0.5);
    tremble = LFNoise2.kr(6 + (motion * 8)).range(0.3, 1.0);
    heat = LFNoise1.kr(0.08).range(0.92, 1.08);
    mod = SinOsc.ar(
        (3.5 + (tremble * 2.5)) * heat,
        0,
        18 + (brightness * 12)
    );
    carrier = SinOsc.ar(
        (340 + (hue * 80)) * heat + mod,
        0,
        0.12
    );
    sig = carrier * tremble;
    sig = sig + (HPF.ar(PinkNoise.ar(0.008), 1200) * (1.0 + (motion * 0.5)));
    sig = BPF.ar(sig, 600 + (brightness * 400), 0.6);
    sig = Limiter.ar(sig, 0.8);
    SendReply.kr(Impulse.kr(30), '/audio/mid_energy', Amplitude.kr(sig));
    Out.ar(0, sig ! 2);
}).add;

SynthDef(\ignitionEdge, {
    var sig, pulse, burst, grain, brightness, motion, hue;
    brightness = \brightness.kr(0.5);
    motion = \motion.kr(0.5);
    hue = \hue.kr(0.5);
    pulse = Impulse.kr(0.4 + (motion * 1.2));
    burst = Decay2.ar(
        Dust.ar(2 + (motion * 4)),
        0.002,
        0.18 + (brightness * 0.1)
    );
    grain = HPF.ar(WhiteNoise.ar(1.0), 2000 + (hue * 1500)) * burst;
    sig = grain * 0.18;
    sig = sig + (SinOsc.ar(
        TRand.kr(180, 420, pulse),
        0,
        Decay2.kr(pulse, 0.01, 0.4) * 0.07
    ));
    sig = Limiter.ar(sig, 0.75);
    SendReply.kr(Impulse.kr(30), '/audio/high_energy', Amplitude.kr(sig));
    Out.ar(0, sig ! 2);
}).add;

fork {
    inf.do {
        ~feverThreshold = Synth(\feverThreshold, [\freq, 180, \brightness, ~brightness ? 0.5, \motion, ~motion ? 0.5, \hue, ~hue ? 0.5]);
        8.0.wait;
        ~criticalTremor = Synth(\criticalTremor, [\brightness, ~brightness ? 0.5, \motion, ~motion ? 0.5, \hue, ~hue ? 0.5]);
        6.0.wait;
        ~feverThreshold.free;
        ~ignitionEdge = Synth(\ignitionEdge, [\brightness, ~brightness ? 0.5, \motion, ~motion ? 0.5, \hue, ~hue ? 0.5]);
        7.0.wait;
        ~criticalTremor.free;
        ~feverThreshold = Synth(\feverThreshold, [\freq, 220, \brightness, ~brightness ? 0.5, \motion, ~motion ? 0.5, \hue, ~hue ? 0.5]);
        5.0.wait;
        ~ignitionEdge.free;
        6.0.wait;
        ~feverThreshold.free;
        1.0.wait;
    };
};