~brightness = 0.5;
~motion = 0.5;
~hue = 0.5;

SynthDef(\mistDrone, {
    arg freq = 60, amp = 0.18, gate = 1;
    var brightness = ~brightness ? 0.5;
    var motion = ~motion ? 0.5;
    var hue = ~hue ? 0.5;
    var baseFreq = freq * (1.0 + (brightness * 0.15));
    var lfo1 = SinOsc.kr(0.03 + (motion * 0.04), 0, 0.008, 1.0);
    var lfo2 = SinOsc.kr(0.07 + (hue * 0.02), 1.2, 0.005, 1.0);
    var fund = SinOsc.ar(baseFreq * lfo1, 0, 0.28);
    var fifth = SinOsc.ar(baseFreq * 1.5 * lfo2, 0, 0.14);
    var octave = SinOsc.ar(baseFreq * 2.0 * lfo1, 0, 0.08);
    var sub = SinOsc.ar(baseFreq * 0.5, 0, 0.16);
    var warmth = LPF.ar(fund + fifth + octave + sub, 400 + (brightness * 300));
    var breathMod = SinOsc.kr(0.11, 0, 0.04, 1.0);
    var sig = warmth * breathMod * amp;
    var env = EnvGen.kr(Env.asr(8.0, 1.0, 6.0), gate, doneAction: 2);
    var out = sig * env;
    SendReply.kr(Impulse.kr(20), '/audio/bass_energy', Amplitude.kr(BPF.ar(out, 80, 0.4)));
    SendReply.kr(Impulse.kr(20), '/audio/breath', Amplitude.kr(out));
    Out.ar(0, out ! 2);
}).add;

SynthDef(\veilTexture, {
    arg amp = 0.09, gate = 1;
    var brightness = ~brightness ? 0.5;
    var motion = ~motion ? 0.5;
    var hue = ~hue ? 0.5;
    var noiseRate = 0.05 + (motion * 0.08);
    var filterFreq = 800 + (brightness * 1200) + (hue * 400);
    var noise = GrayNoise.ar(0.5);
    var filtered = BPF.ar(noise, filterFreq, 0.3 + (hue * 0.4));
    var filtered2 = BPF.ar(noise, filterFreq * 1.618, 0.2);
    var shimmerLfo = SinOsc.kr(noiseRate, 0, 0.5, 0.5);
    var shimmerLfo2 = SinOsc.kr(noiseRate * 1.3, 2.1, 0.3, 0.5);
    var sig = (filtered * shimmerLfo + filtered2 * shimmerLfo2) * amp;
    var slowSwell = SinOsc.kr(0.04, 0, 0.4, 0.6);
    var env = EnvGen.kr(Env.asr(12.0, 1.0, 8.0), gate, doneAction: 2);
    var out = sig * slowSwell * env;
    SendReply.kr(Impulse.kr(20), '/audio/shimmer', Amplitude.kr(BPF.ar(out, 1200, 0.5)));
    Out.ar(0, out ! 2);
}).add;

SynthDef(\moonGlint, {
    arg freq = 523.25, amp = 0.06, gate = 1;
    var brightness = ~brightness ? 0.5;
    var motion = ~motion ? 0.5;
    var hue = ~hue ? 0.5;
    var glintFreq = freq * (1.0 + (hue * 0.05));
    var glintLfo = SinOsc.kr(0.017 + (motion * 0.01), 0, 0.5, 0.5);
    var tone1 = SinOsc.ar(glintFreq, 0, 0.28);
    var tone2 = SinOsc.ar(glintFreq * 2.0, 0, 0.14);
    var tone3 = SinOsc.ar(glintFreq * 3.0, 0, 0.07);
    var chime = (tone1 + tone2 + tone3) * glintLfo;
    var reverbed = chime;
    var delayTime = 0.3 + (brightness * 0.2);
    var echo1 = DelayC.ar(chime, 1.0, delayTime, 0.25);
    var echo2 = DelayC.ar(chime, 1.0, delayTime * 1.7, 0.15);
    var sig = (reverbed + echo1 + echo2) * amp;
    var breathSwell = SinOsc.kr(0.06, 1.5, 0.35, 0.65);
    var env = EnvGen.kr(Env.asr(15.0, 1.0, 10.0), gate, doneAction: 2);
    var out = sig * breathSwell * env;
    SendReply.kr(Impulse.kr(20), '/audio/shimmer', Amplitude.kr(BPF.ar(out, 2000, 0.6)));
    Out.ar(0, out ! 2);
}).add;

s.sync;

fork {
    var cycleTime = 38.0;
    var droneHold = 30.0;
    var veilHold = 28.0;
    var glintHold = 32.0;
    var overlapFade = 8.0;

    ~mistDrone = Synth(\mistDrone, [\freq, 55, \amp, 0.18]);
    (cycleTime * 0.3).wait;
    ~veilTexture = Synth(\veilTexture, [\amp, 0.09]);
    (cycleTime * 0.2).wait;
    ~moonGlint = Synth(\moonGlint, [\freq, 261.63, \amp, 0.06]);

    inf.do {
        (droneHold - overlapFade).wait;
        ~mistDrone.set(\gate, 0);
        overlapFade.wait;
        ~mistDrone = Synth(\mistDrone, [\freq, [41.2, 55, 65.4].choose, \amp, 0.15 + ((~brightness ? 0.5) * 0.06)]);

        (veilHold - overlapFade).wait;
        ~veilTexture.set(\gate, 0);
        overlapFade.wait;
        ~veilTexture = Synth(\veilTexture, [\amp, 0.07 + ((~motion ? 0.5) * 0.05)]);

        (glintHold - overlapFade).wait;
        ~moonGlint.set(\gate, 0);
        overlapFade.wait;
        ~moonGlint = Synth(\moonGlint, [\freq, [261.63, 293.66, 349.23, 392.0].choose, \amp, 0.05 + ((~hue ? 0.5) * 0.04)]);
    };
};