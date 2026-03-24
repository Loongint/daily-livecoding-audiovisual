SynthDef(\slowPressure, {
    var sig, bass, mid, shimmer, env, motion, brightness;
    brightness = \brightness.kr(0.5);
    motion = \motion.kr(0.5);
    bass = LFNoise1.kr(0.03 + (motion * 0.02)).range(48, 56);
    bass = Splay.ar(Array.fill(4, { |i|
        var detune = LFNoise2.kr(0.04 + (i * 0.01)).range(-0.3, 0.3);
        SinOsc.ar(bass.midicps * (1 + detune)) * 0.12
    }));
    mid = Array.fill(5, { |i|
        var freq = LFNoise1.kr(0.02 + (i * 0.007)).range(200, 400) * (1 + (brightness * 0.15));
        var phase = LFNoise2.kr(0.05 + (i * 0.003)).range(-0.4, 0.4);
        SinOsc.ar(freq, phase) * 0.06
    });
    mid = Splay.ar(mid);
    shimmer = Array.fill(6, { |i|
        var freq = LFNoise1.kr(0.015 + (i * 0.004)).range(600, 1400) * (1 + (brightness * 0.2));
        SinOsc.ar(freq) * LFNoise2.kr(0.08 + (i * 0.01)).range(0.0, 0.04)
    });
    shimmer = Splay.ar(shimmer);
    sig = bass + mid + shimmer;
    sig = sig + (BPF.ar(PinkNoise.ar(1), LFNoise1.kr(0.04).range(180, 320), 0.08) * 0.03);
    sig = Limiter.ar(sig, 0.72);
    SendReply.kr(Impulse.kr(30), '/audio/bass_energy', Amplitude.kr(Mix(bass)));
    Out.ar(0, sig);
}).add;

SynthDef(\seamDeform, {
    var sig, carrier, modulator, env, tension, release, brightness, motion;
    brightness = \brightness.kr(0.5);
    motion = \motion.kr(0.5);
    tension = LFNoise1.kr(0.015).range(0.3, 0.9);
    release = LFNoise2.kr(0.025 + (motion * 0.01)).range(0.0, 1.0);
    modulator = SinOsc.ar(
        LFNoise1.kr(0.018).range(1.2, 3.8),
        0,
        LFNoise1.kr(0.03).range(4, 22)
    );
    carrier = Array.fill(3, { |i|
        var freq = LFNoise1.kr(0.01 + (i * 0.005)).range(60, 90) * (1 + (brightness * 0.1));
        SinOsc.ar(freq + modulator) * 0.1
    });
    carrier = Splay.ar(carrier) * tension;
    sig = carrier * (0.4 + (release * 0.6));
    sig = sig + (CombL.ar(sig, 0.5, LFNoise1.kr(0.012).range(0.18, 0.42), 3.5) * 0.18);
    sig = sig + (AllpassL.ar(sig, 1.0, LFNoise2.kr(0.008).range(0.3, 0.7), 4.0) * 0.12);
    sig = LeakDC.ar(sig);
    sig = Limiter.ar(sig, 0.68);
    SendReply.kr(Impulse.kr(30), '/audio/mid_energy', Amplitude.kr(sig));
    Out.ar(0, sig);
}).add;

SynthDef(\thresholdBreath, {
    var sig, noise, filtered, breath, pulse, brightness, motion, hue;
    brightness = \brightness.kr(0.5);
    motion = \motion.kr(0.5);
    hue = \hue.kr(0.5);
    pulse = LFNoise1.kr(0.05 + (motion * 0.03)).range(0.008, 0.025);
    breath = LFNoise2.kr(pulse).range(0.0, 1.0);
    breath = breath * LFNoise1.kr(0.04).range(0.5, 1.0);
    noise = PinkNoise.ar(1);
    filtered = BPF.ar(noise, LFNoise1.kr(0.02).range(120, 280) * (1 + (brightness * 0.12)), 0.15) * 0.08;
    filtered = filtered + (BPF.ar(noise, LFNoise1.kr(0.016).range(350, 700) * (1 + (hue * 0.1)), 0.1) * 0.05);
    filtered = filtered + (BPF.ar(noise, LFNoise1.kr(0.011).range(800, 1600) * (1 + (brightness * 0.18)), 0.06) * 0.025);
    sig = filtered * breath;
    sig = GVerb.ar(sig, 55, 8.0, 0.35, 0.15, 40, 0.5, 0.5, 0.3) * 0.55;
    sig = sig + filtered;
    sig = LeakDC.ar(sig);
    sig = Limiter.ar(sig, 0.65);
    SendReply.kr(Impulse.kr(30), '/audio/breath_energy', Amplitude.kr(sig));
    Out.ar(0, sig);
}).add;

fork {
    ~slowPressure = Synth(\slowPressure);
    ~thresholdBreath = Synth(\thresholdBreath);
    12.0.wait;
    ~seamDeform = Synth(\seamDeform);
    8.0.wait;
    ~thresholdBreath.free;
    10.0.wait;
    ~thresholdBreath = Synth(\thresholdBreath);
    6.0.wait;
    ~slowPressure.free;
    9.0.wait;
    ~slowPressure = Synth(\slowPressure);
    inf.do {
        var waitTime = rrand(14.0, 22.0);
        waitTime.wait;
        ~seamDeform.free;
        2.5.wait;
        ~seamDeform = Synth(\seamDeform);
        rrand(10.0, 16.0).wait;
        ~thresholdBreath.free;
        1.5.wait;
        ~thresholdBreath = Synth(\thresholdBreath);
        rrand(8.0, 14.0).wait;
        ~slowPressure.free;
        2.0.wait;
        ~slowPressure = Synth(\slowPressure);
    };
};