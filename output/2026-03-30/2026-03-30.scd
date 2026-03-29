SynthDef(\thresholdDrone, {
    var sig, freq, motion, brightness, pulse, grid, compress;
    freq = \freq.kr(55) * (1.0 + ((~brightness ? 0.5) * 0.15));
    motion = (~motion ? 0.5);
    brightness = (~brightness ? 0.5);
    pulse = LFPulse.kr(0.23 + (motion * 0.12), 0, 0.08);
    grid = Mix.fill(7, { |i|
        var partial = freq * (i + 1);
        var amp = (1.0 / (i + 1)) * 0.055;
        var detune = LFNoise2.kr(0.07 + (i * 0.03)) * 0.4;
        SinOsc.ar(partial + detune) * amp
    });
    compress = Compander.ar(grid, grid, 0.3, 1, 0.25, 0.01, 0.4);
    sig = compress + (BrownNoise.ar(0.008) * (1.0 + (brightness * 0.4)));
    sig = sig * (0.72 + (pulse * 0.18));
    sig = LPF.ar(sig, 800 + (brightness * 600));
    sig = sig * EnvGen.kr(Env.asr(4.0, 1.0, 3.0), 1, doneAction: 0);
    SendReply.kr(Impulse.kr(30), '/audio/bass_energy', Amplitude.kr(sig));
    Out.ar(0, sig ! 2);
}).add;

SynthDef(\bureaucraticPulse, {
    var sig, rate, motion, brightness, tick, envelope, noise, filtered;
    rate = \rate.kr(1.7) * (1.0 + ((~motion ? 0.5) * 0.3));
    brightness = (~brightness ? 0.5);
    motion = (~motion ? 0.5);
    tick = Impulse.kr(rate);
    envelope = EnvGen.kr(Env.perc(0.002, 0.18, 1.0, -6), tick);
    noise = WhiteNoise.ar(1.0);
    filtered = BPF.ar(noise, 380 + (brightness * 220), 0.3) * 0.35;
    filtered = filtered + (BPF.ar(noise, 1100 + (brightness * 400), 0.2) * 0.12);
    sig = filtered * envelope;
    sig = sig + (SinOsc.ar(55 * (1.0 + (motion * 0.05))) * 0.04 * envelope);
    sig = HPF.ar(sig, 60);
    sig = Limiter.ar(sig, 0.6);
    SendReply.kr(Impulse.kr(30), '/audio/mid_energy', Amplitude.kr(sig));
    Out.ar(0, sig ! 2);
}).add;

SynthDef(\ruptureEdge, {
    var sig, tension, motion, brightness, grain, swarm, compress;
    tension = \tension.kr(0.5);
    brightness = (~brightness ? 0.5);
    motion = (~motion ? 0.5);
    swarm = Mix.fill(5, { |i|
        var rate = LFNoise1.kr(0.04 + (i * 0.02)).range(0.6, 1.4);
        var pfreq = LFNoise2.kr(0.08 + (i * 0.03)).range(200 + (i * 80), 600 + (i * 120));
        var osc = SinOsc.ar(pfreq * rate) * 0.04;
        var gated = osc * LFNoise0.kr(0.5 + (motion * 0.8)).range(0.0, 1.0).max(0.0);
        gated
    });
    grain = GrayNoise.ar(0.03 * (0.5 + (brightness * 0.5)));
    grain = BPF.ar(grain, 2200 + (brightness * 800), 0.4);
    sig = swarm + grain;
    compress = Compander.ar(sig, sig, 0.2, 1, 0.2, 0.005, 0.3);
    sig = compress * (0.55 + (tension * 0.3));
    sig = HPF.ar(sig, 180);
    sig = sig * EnvGen.kr(Env.asr(5.0, 1.0, 4.0), 1, doneAction: 0);
    SendReply.kr(Impulse.kr(30), '/audio/high_energy', Amplitude.kr(sig));
    Out.ar(0, sig ! 2);
}).add;

fork {
    ~thresholdDrone = Synth(\thresholdDrone, [\freq, 52]);
    ~bureaucraticPulse = Synth(\bureaucraticPulse, [\rate, 1.6]);
    4.0.wait;
    ~ruptureEdge = Synth(\ruptureEdge, [\tension, 0.4]);
    inf.do {
        16.0.wait;
        ~ruptureEdge.free;
        ~thresholdDrone.free;
        3.0.wait;
        ~thresholdDrone = Synth(\thresholdDrone, [\freq, 46]);
        2.0.wait;
        ~ruptureEdge = Synth(\ruptureEdge, [\tension, 0.65]);
        12.0.wait;
        ~bureaucraticPulse.free;
        2.5.wait;
        ~bureaucraticPulse = Synth(\bureaucraticPulse, [\rate, 2.1]);
        10.0.wait;
        ~ruptureEdge.free;
        ~ruptureEdge = Synth(\ruptureEdge, [\tension, 0.35]);
        8.0.wait;
        ~thresholdDrone.free;
        2.0.wait;
        ~thresholdDrone = Synth(\thresholdDrone, [\freq, 52]);
        6.0.wait;
        ~bureaucraticPulse.free;
        3.0.wait;
        ~bureaucraticPulse = Synth(\bureaucraticPulse, [\rate, 1.6]);
    };
};