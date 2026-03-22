SynthDef(\thresholdDrone, {
    var freq, sig, partials, shimmer, noise, env, bright, motion;
    bright = \bright.kr(0.5);
    motion = \motion.kr(0.5);
    freq = \freq.kr(110) * (1.0 + (bright * 0.15));
    partials = Array.fill(7, { |i|
        var harmFreq = freq * (i + 1);
        var amp = (1.0 / (i + 1)) * 0.08;
        var detune = LFNoise1.kr(0.08 + (i * 0.03)) * 0.4;
        SinOsc.ar(harmFreq + detune) * amp
    });
    shimmer = Mix(partials);
    noise = BPF.ar(PinkNoise.ar(0.04), freq * 3.1, 0.15) * (0.3 + (motion * 0.4));
    sig = (shimmer + noise) * 0.7;
    sig = Limiter.ar(sig, 0.75);
    SendReply.kr(Impulse.kr(25), '/audio/bass_energy', Amplitude.kr(shimmer));
    Out.ar(0, sig ! 2);
}).add;

SynthDef(\queuePulse, {
    var freq, trig, pulse, density, env, sig, bright, motion, rate;
    bright = \bright.kr(0.5);
    motion = \motion.kr(0.5);
    rate = \rate.kr(4.2) * (0.7 + (motion * 0.6));
    freq = \freq.kr(220) * (1.0 + (bright * 0.08));
    density = rate;
    trig = Impulse.kr(density);
    pulse = SinOsc.ar(freq) * Decay2.kr(trig, 0.005, 0.18);
    pulse = pulse + (SinOsc.ar(freq * 1.998) * Decay2.kr(trig, 0.003, 0.09) * 0.4);
    pulse = pulse + (SinOsc.ar(freq * 3.001) * Decay2.kr(trig, 0.002, 0.05) * 0.2);
    sig = pulse * 0.35;
    sig = HPF.ar(sig, 80);
    sig = Limiter.ar(sig, 0.72);
    SendReply.kr(Impulse.kr(25), '/audio/mid_energy', Amplitude.kr(sig));
    Out.ar(0, sig ! 2);
}).add;

SynthDef(\saturatedAir, {
    var noise, filtered, modFreq, mod, sig, bright, motion, hue;
    bright = \bright.kr(0.5);
    motion = \motion.kr(0.5);
    hue = \hue.kr(0.5);
    modFreq = \modFreq.kr(42.0) * (0.85 + (hue * 0.3));
    noise = WhiteNoise.ar(1.0);
    filtered = BPF.ar(noise, modFreq * (1.0 + (LFNoise2.kr(0.15) * 0.04)), 0.06);
    filtered = filtered + BPF.ar(noise, modFreq * 2.01 * (1.0 + (LFNoise2.kr(0.11) * 0.03)), 0.05);
    filtered = filtered + BPF.ar(noise, modFreq * 3.97 * (1.0 + (LFNoise2.kr(0.09) * 0.025)), 0.04);
    mod = SinOsc.kr(0.07 + (motion * 0.12)).range(0.3, 1.0);
    sig = filtered * mod * 0.45;
    sig = LPF.ar(sig, 6000);
    sig = Limiter.ar(sig, 0.68);
    SendReply.kr(Impulse.kr(25), '/audio/air_energy', Amplitude.kr(sig));
    Out.ar(0, sig ! 2);
}).add;

fork {
    var waitTime;
    ~thresholdDrone = Synth(\thresholdDrone, [\freq, 110, \bright, ~brightness ? 0.5, \motion, ~motion ? 0.5]);
    ~saturatedAir = Synth(\saturatedAir, [\modFreq, 42, \bright, ~brightness ? 0.5, \motion, ~motion ? 0.5, \hue, ~hue ? 0.5]);
    6.0.wait;
    ~queuePulse = Synth(\queuePulse, [\freq, 220, \rate, 3.8, \bright, ~brightness ? 0.5, \motion, ~motion ? 0.5]);
    inf.do {
        waitTime = 8.0 + (3.0.rand);
        waitTime.wait;
        ~thresholdDrone.free;
        0.3.wait;
        ~thresholdDrone = Synth(\thresholdDrone, [\freq, [110, 115, 108].choose, \bright, ~brightness ? 0.5, \motion, ~motion ? 0.5]);
        waitTime = 7.0 + (2.0.rand);
        waitTime.wait;
        ~queuePulse.free;
        0.4.wait;
        ~queuePulse = Synth(\queuePulse, [\freq, [220, 218, 222].choose, \rate, 3.5 + (1.5.rand), \bright, ~brightness ? 0.5, \motion, ~motion ? 0.5]);
        waitTime = 9.0 + (4.0.rand);
        waitTime.wait;
        ~saturatedAir.free;
        0.3.wait;
        ~saturatedAir = Synth(\saturatedAir, [\modFreq, [40, 42, 44, 38].choose, \bright, ~brightness ? 0.5, \motion, ~motion ? 0.5, \hue, ~hue ? 0.5]);
    };
};