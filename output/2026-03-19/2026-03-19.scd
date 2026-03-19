SynthDef(\gripStatic, {
    arg freq = 80, amp = 0.18, gate = 1;
    var sig, feedback, env, noise, lfo;
    var brightness = \brightness.kr(0.5);
    var motion = \motion.kr(0.5);
    var hue = \hue.kr(0.5);
    env = EnvGen.kr(Env.asr(2.0, 1.0, 3.0), gate, doneAction: 2);
    lfo = LFNoise2.kr(0.3 + (motion * 0.8));
    noise = WhiteNoise.ar(0.4);
    feedback = LocalIn.ar(2, 0.0);
    sig = RLPF.ar(noise, (freq * (1.0 + (brightness * 0.6))) + (lfo * 30), 0.08 + (hue * 0.12));
    sig = sig + (feedback * (0.72 + (motion * 0.18)));
    sig = sig.tanh * 0.6;
    LocalOut.ar(sig * [1.0, 0.997]);
    sig = HPF.ar(sig, 60);
    sig = sig * amp * env;
    SendReply.kr(Impulse.kr(30), '/audio/bass_energy', Amplitude.kr(sig));
    Out.ar(0, sig ! 2);
}).add;

SynthDef(\latencyVibrate, {
    arg freq = 340, amp = 0.12, gate = 1;
    var sig, mod, env, chain, trig;
    var brightness = \brightness.kr(0.5);
    var motion = \motion.kr(0.5);
    var hue = \hue.kr(0.5);
    env = EnvGen.kr(Env.asr(1.5, 1.0, 2.5), gate, doneAction: 2);
    mod = LFNoise1.kr(12 + (motion * 20)) * (0.5 + (hue * 0.5));
    sig = Pulse.ar(
        (freq * (1.0 + (brightness * 0.4))) + (mod * freq * 0.08),
        0.5 + (mod * 0.3)
    );
    sig = BPF.ar(sig, 800 + (hue * 1200), 0.3);
    trig = Impulse.kr(8 + (motion * 16));
    chain = sig * TRand.kr(0.3, 1.0, trig);
    sig = (sig * 0.4) + (chain * 0.6);
    sig = sig.softclip * 0.55;
    sig = sig * amp * env;
    SendReply.kr(Impulse.kr(30), '/audio/mid_energy', Amplitude.kr(sig));
    Out.ar(0, [sig, DelayN.ar(sig, 0.05, 0.031 + (motion * 0.019))]);
}).add;

SynthDef(\collapseField, {
    arg amp = 0.14, gate = 1;
    var sig, grains, env, pos, rate;
    var brightness = \brightness.kr(0.5);
    var motion = \motion.kr(0.5);
    var hue = \hue.kr(0.5);
    env = EnvGen.kr(Env.asr(3.0, 1.0, 4.0), gate, doneAction: 2);
    pos = LFNoise2.kr(0.15 + (motion * 0.4));
    rate = LFNoise2.kr(0.08) * 0.5 + 1.0;
    grains = GrainIn.ar(
        2,
        Impulse.kr(18 + (motion * 24)),
        0.04 + (brightness * 0.06),
        HPF.ar(PinkNoise.ar(1.0), 200 + (hue * 800)),
        pos
    );
    sig = grains;
    sig = CombC.ar(sig, 0.5, 0.23 + (hue * 0.11), 1.8 + (brightness * 1.2));
    sig = LPF.ar(sig, 3000 + (brightness * 4000));
    sig = sig * amp * env;
    sig = sig.clip2(0.7) * 0.7;
    SendReply.kr(Impulse.kr(30), '/audio/high_energy', Amplitude.kr(sig));
    Out.ar(0, sig);
}).add;

fork {
    inf.do {
        ~gripStatic = Synth(\gripStatic, [\freq, 75, \amp, 0.16]);
        ~latencyVibrate = Synth(\latencyVibrate, [\freq, 320, \amp, 0.10]);
        (8.0 + 4.0.rand).wait;
        ~latencyVibrate.set(\gate, 0);
        ~collapseField = Synth(\collapseField, [\amp, 0.13]);
        (6.0 + 3.0.rand).wait;
        ~gripStatic.set(\gate, 0);
        (4.0 + 2.0.rand).wait;
        ~collapseField.set(\gate, 0);
        ~gripStatic = Synth(\gripStatic, [\freq, 60 + 30.rand, \amp, 0.15]);
        (5.0 + 3.0.rand).wait;
        ~latencyVibrate = Synth(\latencyVibrate, [\freq, 280 + 120.rand, \amp, 0.11]);
        (7.0 + 4.0.rand).wait;
        ~gripStatic.set(\gate, 0);
        ~latencyVibrate.set(\gate, 0);
        2.0.wait;
    };
};