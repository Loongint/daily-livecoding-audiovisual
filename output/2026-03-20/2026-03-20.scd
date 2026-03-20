SynthDef(\permissionDrone, {
    var sig, freq, motion, brightness, compress, swell;
    freq = \freq.kr(55) * (1.0 + ((\brightness.kr(0.5) - 0.5) * 0.2));
    motion = \motion.kr(0.5);
    brightness = \brightness.kr(0.5);
    compress = LFNoise2.kr(0.03 * (1.0 + motion)).range(0.85, 1.0);
    swell = LFNoise1.kr(0.07).range(0.3, 0.8);
    sig = Mix([
        SinOsc.ar(freq * compress),
        SinOsc.ar(freq * 2.0 * compress * 0.997) * 0.4,
        SinOsc.ar(freq * 3.01 * compress * 0.994) * 0.2,
        SinOsc.ar(freq * 4.02 * compress * 0.991) * 0.1
    ]);
    sig = sig * swell * 0.18;
    sig = RLPF.ar(sig, 400 + (brightness * 600), 0.3);
    sig = Limiter.ar(sig, 0.6);
    SendReply.kr(Impulse.kr(20), '/audio/bass_energy', Amplitude.kr(sig));
    Out.ar(0, sig ! 2);
}).add;

SynthDef(\gridCompression, {
    var sig, noise, grid, threshold, motion, brightness, trig;
    motion = \motion.kr(0.5);
    brightness = \brightness.kr(0.5);
    threshold = \threshold.kr(0.5);
    grid = Impulse.ar(LFNoise1.kr(0.05).range(0.3, 2.5) * (1.0 + motion));
    noise = BPF.ar(WhiteNoise.ar(1.0), LFNoise1.kr(0.08).exprange(200, 1800), 0.02);
    noise = noise * EnvGen.ar(Env.perc(0.001, 0.3), grid);
    sig = Mix([
        noise,
        BPF.ar(PinkNoise.ar(0.5), LFNoise1.kr(0.04).exprange(400, 3200), 0.015) * 0.3
    ]);
    sig = sig * (0.1 + (threshold * 0.15)) * (1.0 - (brightness * 0.3));
    sig = CompanderD.ar(sig, 0.3, 1, 0.1, 0.05, 0.2);
    sig = Limiter.ar(sig, 0.5);
    SendReply.kr(Impulse.kr(20), '/audio/grid_density', Amplitude.kr(sig));
    Out.ar(0, sig ! 2);
}).add;

SynthDef(\ruptureEdge, {
    var sig, body, rupture, tension, motion, brightness, freq, envelope, lfo;
    motion = \motion.kr(0.5);
    brightness = \brightness.kr(0.5);
    freq = \freq.kr(180);
    tension = LFNoise1.kr(0.02).range(0.0, 1.0);
    lfo = SinOsc.kr(0.04 + (motion * 0.06)).range(0.0, 1.0);
    body = Mix([
        Saw.ar(freq * (1.0 + (tension * 0.01))) * 0.3,
        Saw.ar(freq * 1.501 * (1.0 + (tension * 0.008))) * 0.2,
        SinOsc.ar(freq * 0.5) * 0.4
    ]);
    body = RHPF.ar(body, 300 + (tension * 1200), 0.5);
    body = RLPF.ar(body, 800 + (brightness * 1000), 0.4);
    rupture = BPF.ar(WhiteNoise.ar(tension * lfo), 2000 + (tension * 3000), 0.05) * 0.15;
    envelope = (1.0 - (tension * 0.6)) * lfo;
    sig = (body + rupture) * envelope * 0.15;
    sig = Limiter.ar(sig, 0.55);
    SendReply.kr(Impulse.kr(20), '/audio/rupture_tension', tension);
    Out.ar(0, Pan2.ar(sig, LFNoise1.kr(0.05).range(-0.4, 0.4)));
}).add;

fork {
    var waitTime;
    inf.do { |i|
        var phase;
        phase = i % 6;
        if (phase == 0, {
            ~drone.isNil.not.if { ~drone.free };
            ~drone = Synth(\permissionDrone, [\freq, 55, \brightness, ~brightness ? 0.5, \motion, ~motion ? 0.5]);
            ~grid.isNil.not.if { ~grid.free };
            ~grid = Synth(\gridCompression, [\threshold, 0.3, \brightness, ~brightness ? 0.5, \motion, ~motion ? 0.5]);
            16.0.wait;
        });
        if (phase == 1, {
            ~rupture.isNil.not.if { ~rupture.free };
            ~rupture = Synth(\ruptureEdge, [\freq, 180, \brightness, ~brightness ? 0.5, \motion, ~motion ? 0.5]);
            12.0.wait;
        });
        if (phase == 2, {
            ~drone.isNil.not.if { ~drone.free };
            ~drone = Synth(\permissionDrone, [\freq, 41, \brightness, ~brightness ? 0.5, \motion, ~motion ? 0.5]);
            14.0.wait;
        });
        if (phase == 3, {
            ~grid.isNil.not.if { ~grid.free };
            ~rupture.isNil.not.if { ~rupture.free };
            ~grid = Synth(\gridCompression, [\threshold, 0.7, \brightness, ~brightness ? 0.5, \motion, ~motion ? 0.5]);
            ~rupture = Synth(\ruptureEdge, [\freq, 220, \brightness, ~brightness ? 0.5, \motion, ~motion ? 0.5]);
            18.0.wait;
        });
        if (phase == 4, {
            ~drone.isNil.not.if { ~drone.free };
            ~drone = Synth(\permissionDrone, [\freq, 73, \brightness, ~brightness ? 0.5, \motion, ~motion ? 0.5]);
            10.0.wait;
        });
        if (phase == 5, {
            ~grid.isNil.not.if { ~grid.free };
            ~rupture.isNil.not.if { ~rupture.free };
            ~drone.isNil.not.if { ~drone.free };
            ~drone = Synth(\permissionDrone, [\freq, 55, \brightness, ~brightness ? 0.5, \motion, ~motion ? 0.5]);
            ~grid = Synth(\gridCompression, [\threshold, 0.5, \brightness, ~brightness ? 0.5, \motion, ~motion ? 0.5]);
            ~rupture = Synth(\ruptureEdge, [\freq, 165, \brightness, ~brightness ? 0.5, \motion, ~motion ? 0.5]);
            20.0.wait;
        });
    };
};