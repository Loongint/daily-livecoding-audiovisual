// 云幕之后新月初醒无声 — The New Moon Stirs Behind a Veil of Clouds
// Layered grey washes, warm humidity, near-silence, low drone swells

// ─── SynthDef Definitions ───────────────────────────────────────────────────

// Deep lunar drone: slow-breathing low-frequency swell with subtle detuning
SynthDef(\moonDrone, {
    arg gate = 1;
    var brightness = \brightness.kr(0.5);
    var motion    = \motion.kr(0.5);
    var hue       = \hue.kr(0.5);

    var baseFreq  = 55 * (1.0 + (hue * 0.15));
    var detune    = LFNoise2.kr(0.08).range(-0.4, 0.4);
    var breathLFO = LFNoise1.kr(0.05).range(0.0, 1.0);
    var swellEnv  = EnvGen.kr(Env.asr(18, 1, 22), gate, doneAction: 2);

    var osc1 = SinOsc.ar(baseFreq + detune);
    var osc2 = SinOsc.ar(baseFreq * 1.5 + (detune * 0.7)) * 0.4;
    var osc3 = SinOsc.ar(baseFreq * 2.0 + (detune * 0.3)) * 0.15;

    var drone = (osc1 + osc2 + osc3) * breathLFO * swellEnv;

    // warm humidity: slight low-pass shimmer
    var filtered = RLPF.ar(drone, 300 + (brightness * 400), 0.6);
    var sig = filtered * 0.38 ! 2;

    // audio analysis
    var monoSig = sig.sum;
    SendReply.kr(Impulse.kr(30), '/audio/bass_energy',
        Amplitude.kr(BPF.ar(monoSig, 60, 0.5)));
    SendReply.kr(Impulse.kr(30), '/audio/breath',
        breathLFO);

    Out.ar(0, sig);
}).add;

// Veil texture: diffuse grey-wash noise clouds, slow spectral drift
SynthDef(\cloudVeil, {
    arg gate = 1;
    var brightness = \brightness.kr(0.5);
    var motion    = \motion.kr(0.5);
    var hue       = \hue.kr(0.5);

    var swellEnv  = EnvGen.kr(Env.asr(25, 1, 30), gate, doneAction: 2);
    var driftLFO  = LFNoise2.kr(0.03).range(0.0, 1.0);
    var panLFO    = LFNoise1.kr(0.04).range(-0.6, 0.6);

    // layered bandpass noise — grey wash
    var noise     = GrayNoise.ar(1);
    var band1     = BPF.ar(noise, 180 + (motion * 80),  0.3) * 0.5;
    var band2     = BPF.ar(noise, 420 + (hue * 200),    0.2) * 0.35;
    var band3     = BPF.ar(noise, 900 + (brightness * 300), 0.15) * 0.2;

    var veil      = (band1 + band2 + band3) * driftLFO * swellEnv * 0.28;
    var sig       = Pan2.ar(veil, panLFO);

    // audio analysis
    var monoSig   = sig.sum;
    SendReply.kr(Impulse.kr(30), '/audio/shimmer',
        Amplitude.kr(BPF.ar(monoSig, 900, 0.4)));
    SendReply.kr(Impulse.kr(30), '/audio/veil_density',
        driftLFO);

    Out.ar(0, sig);
}).add;

// New moon glint: sparse, near-silent high partial tones — the moon stirring
SynthDef(\moonGlint, {
    arg gate = 1;
    var brightness = \brightness.kr(0.5);
    var hue       = \hue.kr(0.5);

    var env       = EnvGen.kr(Env.asr(8, 1, 14), gate, doneAction: 2);
    var shimmerLFO = LFNoise2.kr(0.12).range(0.0, 1.0);
    var panLFO    = LFNoise1.kr(0.07).range(-0.8, 0.8);

    var freq1     = 1320 * (1.0 + (brightness * 0.2));
    var freq2     = 1980 * (1.0 + (hue * 0.15));
    var freq3     = 2640 * (1.0 + (brightness * 0.1));

    var partial1  = SinOsc.ar(freq1) * LFNoise2.kr(0.09).range(0.0, 1.0);
    var partial2  = SinOsc.ar(freq2) * LFNoise2.kr(0.07).range(0.0, 0.6);
    var partial3  = SinOsc.ar(freq3) * LFNoise2.kr(0.05).range(0.0, 0.3);

    var glint     = (partial1 + partial2 + partial3) * shimmerLFO * env * 0.06;
    var sig       = Pan2.ar(glint, panLFO);

    // audio analysis
    var monoSig   = sig.sum;
    SendReply.kr(Impulse.kr(30), '/audio/glint',
        Amplitude.kr(monoSig));

    Out.ar(0, sig);
}).add;

// ─── Boot server and begin playback ─────────────────────────────────────────

s.waitForBoot {
    s.sync;

    // ─── Infinite Playback ───────────────────────────────────────────────────

    fork {
        // stagger initial launch so layers don't all peak simultaneously
        ~moonDrone = Synth(\moonDrone);
        8.0.wait;

        ~cloudVeil = Synth(\cloudVeil);
        12.0.wait;

        ~moonGlint = Synth(\moonGlint);

        inf.do {
            // full cycle: ~90s — drone swell, veil dissolve, glint flicker

            // let all three breathe together
            55.0.wait;

            // dissolve glint into silence, re-emerge
            ~moonGlint.set(\gate, 0);
            18.0.wait;
            ~moonGlint = Synth(\moonGlint);

            // veil thins — opacity to void; wait full 30s so old synth finishes
            // before new instance starts, avoiding double-layer overlap
            ~cloudVeil.set(\gate, 0);
            31.0.wait;
            ~cloudVeil = Synth(\cloudVeil);

            // drone swells back from near-silence
            ~moonDrone.set(\gate, 0);
            23.0.wait;
            ~moonDrone = Synth(\moonDrone);

            // brief overlap before next cycle
            10.0.wait;
        };
    };
};