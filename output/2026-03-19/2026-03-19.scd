SynthDef(\moonDrone, {
    arg freq = 55, amp = 0.18, atk = 8.0, rel = 12.0, gate = 1;
    var brightness = \brightness.kr(0.5);
    var motion = \motion.kr(0.5);
    var hue = \hue.kr(0.5);
    var env = EnvGen.kr(Env.asr(atk, 1.0, rel), gate, doneAction: 2);
    var baseFreq = freq * (1.0 + (brightness * 0.08));
    var swell = SinOsc.kr(0.04 + (motion * 0.02)).range(0.85, 1.0);
    var f1 = SinOsc.ar(baseFreq) * 0.5;
    var f2 = SinOsc.ar(baseFreq * 1.5005 + LFNoise2.kr(0.05).range(-0.3, 0.3)) * 0.25;
    var f3 = SinOsc.ar(baseFreq * 2.002 + LFNoise2.kr(0.07).range(-0.2, 0.2)) * 0.12;
    var f4 = SinOsc.ar(baseFreq * 3.003) * 0.06;
    var sig = (f1 + f2 + f3 + f4) * swell * env * amp;
    var sigL = sig + (DelayC.ar(sig, 0.05, LFNoise2.kr(0.03).range(0.01, 0.04)) * 0.3);
    var sigR = sig + (DelayC.ar(sig, 0.05, LFNoise2.kr(0.025).range(0.01, 0.04)) * 0.3);
    var stereo = [sigL, sigR] * 0.7;
    SendReply.kr(Impulse.kr(30), '/audio/bass_energy', Amplitude.kr(sigL));
    Out.ar(0, stereo);
}).add;

SynthDef(\gauzeTexture, {
    arg amp = 0.07, atk = 10.0, rel = 14.0, gate = 1;
    var brightness = \brightness.kr(0.5);
    var motion = \motion.kr(0.5);
    var hue = \hue.kr(0.5);
    var env = EnvGen.kr(Env.asr(atk, 1.0, rel), gate, doneAction: 2);
    var breathRate = 0.05 + (motion * 0.03);
    var breath = SinOsc.kr(breathRate).range(0.3, 1.0);
    var noise = LPF.ar(GrayNoise.ar(1.0), 800 + (brightness * 400));
    var noiseHP = HPF.ar(noise, 180);
    var shimmer = SinOsc.ar(
        [220.5, 221.3, 329.8, 330.4, 440.2, 440.9],
        LFNoise2.kr(Array.fill(6, { rrand(0.02, 0.08) })).range(0, 2pi)
    ).mean;
    var sig = (noiseHP * 0.4 + shimmer * 0.6) * breath * env * amp;
    var wet = FreeVerb.ar(sig, 0.85, 0.92, 0.4);
    var out = [
        wet + (DelayC.ar(wet, 0.3, 0.17) * 0.2),
        wet + (DelayC.ar(wet, 0.3, 0.23) * 0.2)
    ] * 0.65;
    SendReply.kr(Impulse.kr(30), '/audio/mid_energy', Amplitude.kr(sig));
    Out.ar(0, out);
}).add;

SynthDef(\moonBreath, {
    arg freq = 220, amp = 0.09, atk = 6.0, rel = 10.0, gate = 1;
    var brightness = \brightness.kr(0.5);
    var motion = \motion.kr(0.5);
    var hue = \hue.kr(0.5);
    var env = EnvGen.kr(Env.asr(atk, 1.0, rel), gate, doneAction: 2);
    var targetFreq = freq * (1.0 + (hue * 0.15));
    var vibrato = SinOsc.kr(0.12 + (motion * 0.05)).range(-0.008, 0.008);
    var osc1 = SinOsc.ar(targetFreq * (1 + vibrato));
    var osc2 = SinOsc.ar(targetFreq * 1.0008 * (1 + vibrato * 0.7)) * 0.6;
    var osc3 = SinOsc.ar(targetFreq * 2.001) * 0.2;
    var sig = (osc1 + osc2 + osc3) * 0.33;
    var filtered = RLPF.ar(sig, 600 + (brightness * 300), 0.5);
    var swellEnv = SinOsc.kr(0.035 + (motion * 0.015)).range(0.5, 1.0);
    var filteredSwell = filtered * swellEnv * env * amp;
    var wet = GVerb.ar(filteredSwell, 60, 8.0, 0.3, 0.5, 15, 0.5, 0.5, 0.3);
    var out = [
        wet[0] + (filteredSwell * 0.3),
        wet[1] + (filteredSwell * 0.3)
    ] * 0.6;
    SendReply.kr(Impulse.kr(30), '/audio/high_energy', Amplitude.kr(filteredSwell));
    Out.ar(0, out);
}).add;

fork {
    var droneFreqs = [55, 55, 41.2, 55, 61.7];
    var breathFreqs = [220, 165, 220, 246.9, 220];
    var droneIdx = 0;
    var breathIdx = 0;

    ~moonDrone = Synth(\moonDrone, [\freq, 55, \amp, 0.16]);
    ~gauzeTexture = Synth(\gauzeTexture, [\amp, 0.065]);
    3.0.wait;
    ~moonBreath = Synth(\moonBreath, [\freq, 220, \amp, 0.08]);

    inf.do {
        var waitTime = rrand(18.0, 28.0);
        waitTime.wait;

        droneIdx = (droneIdx + 1) % droneFreqs.size;
        breathIdx = (breathIdx + 1) % breathFreqs.size;

        ~moonDrone.set(\gate, 0);
        2.0.wait;
        ~moonDrone = Synth(\moonDrone, [
            \freq, droneFreqs[droneIdx],
            \amp, rrand(0.13, 0.19),
            \atk, rrand(7.0, 11.0)
        ]);

        rrand(4.0, 8.0).wait;

        ~moonBreath.set(\gate, 0);
        2.0.wait;
        ~moonBreath = Synth(\moonBreath, [
            \freq, breathFreqs[breathIdx],
            \amp, rrand(0.07, 0.11),
            \atk, rrand(5.0, 9.0)
        ]);

        rrand(6.0, 12.0).wait;

        ~gauzeTexture.set(\gate, 0);
        2.0.wait;
        ~gauzeTexture = Synth(\gauzeTexture, [
            \amp, rrand(0.055, 0.08),
            \atk, rrand(9.0, 13.0)
        ]);
    };
};