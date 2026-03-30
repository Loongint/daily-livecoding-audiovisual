SynthDef(\thermal_wall, {
	arg freq=65, amp=0.3, brightness=0.5, motion=0.2;
	var sig, env, pressure, layers, bass, mid, high;
	env = EnvGen.kr(Env.asr(10, 1, 8), gate: \gate.kr(1), doneAction: 2);
	pressure = LFNoise2.kr(0.03).range(0.2, 1.0);
	layers = Mix.fill(6, {|i|
		var detune, f, osc, filt;
		detune = LFNoise1.kr(0.05 + (i * 0.01)).range(-1.5, 1.5);
		f = freq * (1 + (i * 0.5)) + detune;
		f = f.min(8000);
		osc = SinOsc.ar(f, LFNoise2.kr(0.1).range(0, 2pi));
		filt = RLPF.ar(osc, freq * (2 + (pressure * 4)), 0.3 + (pressure * 0.5));
		filt * (1 / (i + 1).sqrt)
	});
	sig = layers * pressure * env;
	sig = sig + (BPF.ar(BrownNoise.ar(0.1), freq * 1.5, 0.05) * pressure.squared);
	sig = sig + (SinOsc.ar(freq * 0.5, 0, 0.15 * pressure * pressure));
	sig = LeakDC.ar(sig);
	sig = sig * amp * env;
	sig = Pan2.ar(sig, LFNoise2.kr(0.08).range(-0.3, 0.3));
	sig = sig.tanh;
	bass = Amplitude.kr(LPF.ar(sig.sum, 200), 0.05, 0.2);
	mid = Amplitude.kr(BPF.ar(sig.sum, 1000, 1.0), 0.05, 0.2);
	high = Amplitude.kr(HPF.ar(sig.sum, 3000), 0.05, 0.2);
	SendReply.kr(Impulse.kr(30), '/audio/bass', bass);
	SendReply.kr(Impulse.kr(30), '/audio/mid', mid);
	SendReply.kr(Impulse.kr(30), '/audio/loudness', Amplitude.kr(sig.sum, 0.05, 0.2));
	Out.ar(0, sig);
}).add;

SynthDef(\gate_friction, {
	arg freq=130, amp=0.2, density=3, brightness=0.5;
	var sig, env, trig, grains, body;
	env = EnvGen.kr(Env.asr(6, 1, 6), gate: \gate.kr(1), doneAction: 2);
	trig = Dust.kr(density + LFNoise2.kr(0.1).range(0, 4));
	grains = Mix.fill(4, {|i|
		var gfreq, grain;
		gfreq = freq * Rand(0.98, 1.02) * [1, 1.5, 2.0, 3.01].at(i);
		gfreq = gfreq.min(6000);
		grain = SinOsc.ar(gfreq) * EnvGen.kr(Env.perc(0.01, Rand(0.08, 0.4)), trig);
		grain * (0.2 / (i + 1))
	});
	body = LPF.ar(Saw.ar(freq * 0.5, 0.05), freq * 2 + (brightness * 500));
	body = body + LPF.ar(PinkNoise.ar(0.02), freq * 1.5);
	sig = grains + body;
	sig = sig * env * amp;
	sig = sig + CombL.ar(sig, 0.3, LFNoise2.kr(0.05).range(0.1, 0.25), 3, 0.2);
	sig = LeakDC.ar(sig);
	sig = Pan2.ar(sig, LFNoise2.kr(0.12).range(-0.6, 0.6));
	sig = sig.tanh;
	SendReply.kr(Impulse.kr(30), '/audio/high', Amplitude.kr(HPF.ar(sig.sum, 3000), 0.05, 0.2));
	SendReply.kr(Impulse.kr(30), '/audio/onset', Trig1.kr(trig, 0.05));
	Out.ar(0, sig);
}).add;

SynthDef(\coldness_nostalgia, {
	arg freq=220, amp=0.12, hue=0.6, motion=0.3;
	var sig, env, shimmer, melody, cold;
	env = EnvGen.kr(Env.asr(12, 1, 10), gate: \gate.kr(1), doneAction: 2);
	shimmer = Mix.fill(5, {|i|
		var sf, s;
		sf = freq * Rand(3.0, 8.0);
		sf = sf.min(7000);
		s = SinOsc.ar(sf + LFNoise2.kr(0.2).range(-2, 2));
		s * LFNoise2.kr(Rand(0.02, 0.15)).range(0, 0.04)
	});
	melody = SinOsc.ar(
		freq * SinOsc.kr(0.02, 0, 0.003, 1),
		0,
		0.08 * LFNoise2.kr(0.05).range(0.3, 1.0)
	);
	cold = HPF.ar(WhiteNoise.ar(0.008), 4000) * LFNoise2.kr(0.08).range(0, 1);
	sig = shimmer + melody + cold;
	sig = sig * env * amp;
	sig = sig + (AllpassC.ar(sig, 0.5, LFNoise2.kr(0.03).range(0.15, 0.45), 6) * 0.3);
	sig = sig + (AllpassC.ar(sig, 0.3, LFNoise2.kr(0.04).range(0.08, 0.28), 4) * 0.2);
	sig = LeakDC.ar(sig);
	sig = Pan2.ar(sig, SinOsc.kr(0.03).range(-0.5, 0.5));
	sig = sig.tanh;
	SendReply.kr(Impulse.kr(30), '/audio/mid', Amplitude.kr(BPF.ar(sig.sum, 1000, 1.0), 0.05, 0.2));
	Out.ar(0, sig);
}).add;

fork {
	var notes = [31, 36, 40, 43];
	var coldNotes = [55, 60, 64, 67, 72];

	2.wait;

	inf.do {|i|
		var baseNote, baseFreq, coldFreq, density, dur;

		baseNote = notes.choose;
		baseFreq = baseNote.midicps;
		coldFreq = coldNotes.choose.midicps;
		density = [2, 3, 5, 7].choose;
		dur = rrand(25, 45);

		if(~thermal.notNil, { ~thermal.set(\gate, 0) });
		if(~friction.notNil, { ~friction.set(\gate, 0) });
		if(~cold.notNil, { ~cold.set(\gate, 0) });

		3.wait;

		~thermal = Synth(\thermal_wall, [
			\freq, baseFreq,
			\amp, 0.22,
			\brightness, ~brightness ? 0.5,
			\motion, ~motion ? 0.2
		]);

		rrand(2.0, 5.0).wait;

		~friction = Synth(\gate_friction, [
			\freq, baseFreq * 2,
			\amp, 0.13,
			\density, density,
			\brightness, ~brightness ? 0.5
		]);

		rrand(3.0, 6.0).wait;

		~cold = Synth(\coldness_nostalgia, [
			\freq, coldFreq,
			\amp, 0.09,
			\hue, ~hue ? 0.6,
			\motion, ~motion ? 0.3
		]);

		(dur - 10).wait;

		~thermal.set(\amp, 0.28);
		~friction.set(\density, density * 1.8);

		10.wait;
	};
};