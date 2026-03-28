SynthDef(\bottleneck, {
    var sig, freq, pressure, compress, env, brightness, motion;
    brightness = \brightness.kr(0.5);
    motion = \motion.kr(0.5);
    freq = \freq.kr(80) * (1.0 + (brightness * 0.3));
    pressure = LFNoise1.kr(0.08 + (motion * 0.15)).range(0.3, 1.0);
    compress = Compander.ar(
        SinOsc.ar(freq) + SinOsc.ar(freq * 2.003, 0, 0.4) + SinOsc.ar(freq * 3.007, 0, 0.2),
        SinOsc.ar(freq),
        0.4, 1, 0.08, 0.003, 0.12
    );
    sig = compress * pressure * \amp.kr(0.35);
    sig = LPF.ar(sig, 800 + (brightness * 600));
    sig = sig + (DelayC.ar(sig, 0.2, 0.17 + (LFNoise2.kr(0.05).range(-0.005, 0.005))) * 0.3);
    sig = Limiter.ar(sig, 0.7);
    SendReply.kr(Impulse.kr(20), '/audio/bass_energy', Amplitude.kr(sig));
    Out.ar(0, sig ! 2);
}).add;

SynthDef(\threshold_pulse, {
    var sig, trig, gate, freq, brightness, motion, hue;
    brightness = \brightness.kr(0.5);
    motion = \motion.kr(0.5);
    hue = \hue.kr(0.5);
    freq = \freq.kr(220) * (1.0 + (hue * 0.15));
    trig = Dust.kr(0.3 + (motion * 0.8));
    gate = Decay2.kr(trig, 0.01, 1.8 + (brightness * 2.0));
    sig = SinOsc.ar(freq * gate.linlin(0, 1, 0.97, 1.03)) * gate;
    sig = sig + (SinOsc.ar(freq * 1.5) * gate * 0.3);
    sig = sig + (BPF.ar(WhiteNoise.ar(0.15), freq * 2, 0.1) * gate * 0.4);
    sig = HPF.ar(sig, 60);
    sig = sig * \amp.kr(0.3);
    sig = Limiter.ar(sig, 0.65);
    SendReply.kr(Impulse.kr(20), '/audio/mid_energy', Amplitude.kr(sig));
    Out.ar(0, [sig, DelayC.ar(sig, 0.3, 0.23)]);
}).add;

SynthDef(\stillness_arch, {
    var sig, noise, filtered, shimmer, brightness, motion, hue;
    brightness = \brightness.kr(0.5);
    motion = \motion.kr(0.5);
    hue = \hue.kr(0.5);
    noise = WhiteNoise.ar(1);
    filtered = (1..6).collect({ |i|
        var center = 120 * i * (1.0 + (hue * 0.1));
        var q = 0.02 + (brightness * 0.015);
        BPF.ar(noise, center, q) * (1.0 / i)
    }).sum;
    shimmer = LFNoise2.kr(0.04 + (motion * 0.08)).range(0.6, 1.0);
    sig = filtered * shimmer * \amp.kr(0.28);
    sig = HPF.ar(sig, 80);
    sig = sig + (CombL.ar(sig, 0.8, 0.73, 6.0) * 0.18);
    sig = Limiter.ar(sig, 0.6);
    SendReply.kr(Impulse.kr(20), '/audio/high_energy', Amplitude.kr(sig));
    Out.ar(0, sig ! 2);
}).add;

fork {
    var waitTime;
    ~bottleneck = Synth(\bottleneck, [\freq, 72, \amp, 0.32, \brightness, 0.5, \motion, 0.4]);
    ~stillness = Synth(\stillness_arch, [\amp, 0.22, \brightness, 0.45, \motion, 0.3, \hue, 0.5]);
    12.0.wait;
    ~threshold = Synth(\threshold_pulse, [\freq, 210, \amp, 0.28, \brightness, 0.55, \motion, 0.5, \hue, 0.4]);
    10.0.wait;
    inf.do {
        ~bottleneck.free;
        ~bottleneck = Synth(\bottleneck, [\freq, 68 + (rrand(0, 16)), \amp, 0.3 + rrand(0.0, 0.08), \brightness, rrand(0.3, 0.7), \motion, rrand(0.2, 0.6)]);
        8.0.wait;
        ~stillness.free;
        ~stillness = Synth(\stillness_arch, [\amp, 0.2 + rrand(0.0, 0.08), \brightness, rrand(0.35, 0.65), \motion, rrand(0.15, 0.45), \hue, rrand(0.3, 0.7)]);
        6.0.wait;
        ~threshold.free;
        ~threshold = Synth(\threshold_pulse, [\freq, 180 + (rrand(0, 60)), \amp, 0.25 + rrand(0.0, 0.07), \brightness, rrand(0.4, 0.7), \motion, rrand(0.3, 0.7), \hue, rrand(0.3, 0.65)]);
        10.0.wait;
    };
};