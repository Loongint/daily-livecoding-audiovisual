SynthDef(\thresh_drone, {
    var freq = \freq.kr(60) * (1.0 + ((\brightness.kr(0.5) - 0.5) * 0.3));
    var slow = LFNoise2.kr(0.07);
    var mod = LFNoise1.kr(0.13) * 0.5;
    var sig = Mix([
        SinOsc.ar(freq * (1.0 + (mod * 0.01))),
        SinOsc.ar(freq * 1.5 * (1.0 + (slow * 0.008))),
        SinOsc.ar(freq * 2.0 * (1.0 + (mod * 0.005))) * 0.4,
        SinOsc.ar(freq * 0.5) * 0.6
    ]);
    sig = sig * 0.18;
    sig = LPF.ar(sig, 800 + (LFNoise1.kr(0.05) * 300));
    sig = sig * (1.0 + (\motion.kr(0.5) * 0.2));
    sig = sig.clip(-0.7, 0.7) * 0.85;
    SendReply.kr(Impulse.kr(20), '/audio/bass_energy', Amplitude.kr(sig));
    Out.ar(0, sig ! 2);
}).add;

SynthDef(\thresh_static, {
    var density = \motion.kr(0.5) * 0.6 + 0.2;
    var noise = WhiteNoise.ar(1.0);
    var gated = noise * LFNoise0.kr(LFNoise1.kr(0.3).exprange(2, 40));
    var filtered = BPF.ar(gated, LFNoise2.kr(0.08).exprange(300, 4000), 0.3);
    var crackle = Dust.ar(density * 80) * WhiteNoise.ar(1.0);
    var sig;
    crackle = BPF.ar(crackle, LFNoise2.kr(0.15).exprange(1000, 8000), 0.5);
    sig = (filtered * 0.4) + (crackle * 0.3);
    sig = sig * 0.12;
    sig = sig * (0.7 + (\brightness.kr(0.5) * 0.4));
    sig = sig.clip(-0.6, 0.6) * 0.85;
    SendReply.kr(Impulse.kr(20), '/audio/mid_energy', Amplitude.kr(sig));
    Out.ar(0, sig ! 2);
}).add;

SynthDef(\thresh_ledger, {
    var rate = \hue.kr(0.5) * 0.4 + 0.05;
    var trig = Impulse.kr(rate);
    var pitch = TChoose.kr(trig, [55, 58, 62, 65, 67, 70, 74].midicps);
    var env = EnvGen.kr(Env.perc(0.02, 1.8, 1.0, -4), trig);
    var sig = SinOsc.ar(pitch) * env;
    var shimmer = SinOsc.ar(pitch * 2.0 + LFNoise2.kr(1.0).range(-2, 2)) * env * 0.3;
    sig = sig + shimmer;
    sig = FreeVerb.ar(sig, 0.85, 0.9, 0.4);
    sig = sig * 0.22;
    sig = sig * (0.6 + (\brightness.kr(0.5) * 0.5));
    sig = sig.clip(-0.65, 0.65) * 0.85;
    SendReply.kr(Impulse.kr(20), '/audio/high_energy', Amplitude.kr(sig));
    Out.ar(0, sig ! 2);
}).add;

fork {
    ~thresh_drone = Synth(\thresh_drone);
    ~thresh_static = Synth(\thresh_static);
    ~thresh_ledger = Synth(\thresh_ledger);

    inf.do {
        var wait_time = rrand(18.0, 32.0);
        var choice = [0, 1, 2].choose;

        wait_time.wait;

        if(choice == 0, {
            ~thresh_drone.free;
            (rrand(0.5, 1.5)).wait;
            ~thresh_drone = Synth(\thresh_drone, [\freq, [40, 50, 60, 80].choose]);
        });

        if(choice == 1, {
            ~thresh_static.free;
            (rrand(0.3, 1.0)).wait;
            ~thresh_static = Synth(\thresh_static);
        });

        if(choice == 2, {
            ~thresh_ledger.free;
            (rrand(0.5, 1.2)).wait;
            ~thresh_ledger = Synth(\thresh_ledger);
        });
    };
};