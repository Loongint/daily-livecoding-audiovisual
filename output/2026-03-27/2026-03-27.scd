SynthDef(\sortingGrid, {
    var freq = \freq.kr(88) * (1.0 + (~brightness ? 0.5) * 0.15);
    var rate = \rate.kr(0.11) * (1.0 + (~motion ? 0.5) * 0.6);
    var amp = \amp.kr(0.32);
    var partials = Array.fill(6, { |i|
        var drift = LFNoise1.kr(0.07 + (i * 0.04)).range(-0.009, 0.009);
        var harmFreq = freq * (i + 1) * (1 + drift);
        var gateRate = rate * (i * 0.4 + 0.3);
        var gate = LFPulse.kr(gateRate, i * 0.17, 0.22).range(0, 1);
        SinOsc.ar(harmFreq) * gate * (0.7 / (i + 1)) * 0.055
    });
    var sig = Mix(partials);
    var hiss = BPF.ar(WhiteNoise.ar(1), freq * 3.5, 0.35) * 0.012;
    sig = sig + hiss;
    sig = RLPF.ar(sig, 900 + (~hue ? 0.5) * 700, 0.55);
    sig = sig * amp;
    sig = Limiter.ar(sig, 0.72);
    Out.ar(0, sig ! 2);
    SendReply.kr(Impulse.kr(30), '/audio/bass_energy', Amplitude.kr(sig));
}).add;

SynthDef(\thermalGate, {
    var rate = \rate.kr(0.7) * (1.0 + (~motion ? 0.5) * 0.9);
    var amp = \amp.kr(0.42);
    var freq = \freq.kr(190) * (1.0 + (~brightness ? 0.5) * 0.35);
    var trig = Dust.kr(rate);
    var env = EnvGen.kr(Env.perc(0.002, 1.8, 1, -5), trig);
    var tone = SinOsc.ar(freq * (1 + LFNoise0.kr(rate * 0.5).range(-0.08, 0.08))) * env * 0.28;
    var click = WhiteNoise.ar * EnvGen.kr(Env.perc(0.0001, 0.04), trig) * 0.18;
    var metallic = Ringz.ar(click, freq * 3.5 + (~hue ? 0.5) * 200, 0.25) * 0.35;
    var sig = tone + click + metallic;
    sig = HPF.ar(sig, 90);
    sig = sig * amp;
    sig = Limiter.ar(sig, 0.72);
    Out.ar(0, sig ! 2);
    SendReply.kr(Impulse.kr(30), '/audio/mid_energy', Amplitude.kr(sig));
}).add;

SynthDef(\decayField, {
    var amp = \amp.kr(0.28);
    var freq = \freq.kr(260) * (1.0 + (~brightness ? 0.5) * 0.4);
    var motionVal = ~motion ? 0.5;
    var cutoffMod = LFNoise1.kr(0.04 + (motionVal * 0.08)).range(0.5, 3.0);
    var noise = BPF.ar(WhiteNoise.ar(1), freq * cutoffMod, 0.18) * 0.25;
    var lowDrone = SinOsc.ar(freq * 0.22 + LFNoise1.kr(0.025).range(-1.5, 1.5)) * 0.14;
    var crackle = Dust.ar(2 + (motionVal * 4)) * 0.08;
    var sig = noise + lowDrone + crackle;
    sig = sig * amp;
    sig = Limiter.ar(sig, 0.72);
    Out.ar(0, sig ! 2);
    SendReply.kr(Impulse.kr(30), '/audio/high_energy', Amplitude.kr(sig));
}).add;

fork {
    inf.do {
        ~sortingGrid = Synth(\sortingGrid, [\freq, 88, \rate, 0.1, \amp, 0.32]);
        ~decayField = Synth(\decayField, [\freq, 260, \amp, 0.26]);
        10.0.wait;
        ~thermalGate = Synth(\thermalGate, [\freq, 185, \rate, 0.55, \amp, 0.4]);
        7.0.wait;
        ~sortingGrid.free;
        5.0.wait;
        ~sortingGrid = Synth(\sortingGrid, [\freq, 112, \rate, 0.16, \amp, 0.28]);
        ~thermalGate.free;
        6.0.wait;
        ~decayField.free;
        3.0.wait;
        ~decayField = Synth(\decayField, [\freq, 320, \amp, 0.25]);
        5.0.wait;
        ~sortingGrid.free;
        2.0.wait;
    };
};