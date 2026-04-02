SynthDef(\arbitration_pulse, {
	arg freq=55, density=3, amp=0.3, pan=0, brightness=0.5, motion=0.5;
	var trig, sig, env, dust, resonances, filt, analysis;
	var gates, judged, held;

	trig = Dust.kr(density * LFNoise1.kr(0.2).range(0.4, 2.5));
	gates = Array.fill(7, {
		var d = Dust.kr(density * LFNoise2.kr(0.1).range(0.3, 1.8));
		var tone = SinOsc.ar(
			freq * Rand(0.98, 1.02) + LFNoise2.kr(Rand(0.05, 0.3)).range(-2, 2),
			0,
			EnvGen.kr(Env.perc(Rand(0.001, 0.05), Rand(0.08, 0.6), Rand(0.1, 0.4)), d)
		);
		var noise = BPF.ar(
			WhiteNoise.ar(EnvGen.kr(Env.perc(0.001, Rand(0.02, 0.15), 0.3), d)),
			freq * Rand(2, 8),
			Rand(0.01, 0.08)
		);
		tone + noise;
	});
	judged = Mix.ar(gates);
	held = CombL.ar(judged, 0.3, LFNoise1.kr(0.07).range(0.05, 0.25), LFNoise2.kr(0.04).range(1, 6));
	sig = judged + (held * 0.35);
	sig = HPF.ar(sig, 35);
	sig = LPF.ar(sig, 1800 + (brightness * 3000));
	sig = sig * EnvGen.kr(Env.asr(6, 1, 8), gate: 1);
	sig = Limiter.ar(sig * amp, 0.85);
	sig = Pan2.ar(sig, LFNoise2.kr(0.15).range(-0.6, 0.6));
	SendReply.kr(Impulse.kr(30), '/audio/onset', Amplitude.kr(Mix.ar(gates), 0.01, 0.05));
	SendReply.kr(Impulse.kr(30), '/audio/bass', Amplitude.kr(LPF.ar(sig, 200)));
	SendReply.kr(Impulse.kr(30), '/audio/mid', Amplitude.kr(BPF.ar(sig, 1200, 0.5)));
	Out.ar(0, sig);
}).add;

SynthDef(\suspension_field, {
	arg freq=41, amp=0.25, brightness=0.5, motion=0.3;
	var sig, mod, pressures, filt, env;
	var bands;

	bands = Array.fill(5, {
		var f = freq * Rand(0.5, 2.0);
		var bw = Rand(0.005, 0.04);
		var src = Crackle.ar(LFNoise2.kr(0.03).range(1.2, 1.8), 0.15);
		BPF.ar(src, f.clip(30, 4000), bw) * Rand(0.5, 1.0);
	});
	pressures = Mix.ar(bands);
	mod = LFNoise1.kr(0.06).range(0.2, 1.0);
	sig = pressures * mod;
	sig = sig + AllpassC.ar(sig, 0.5, LFNoise2.kr(0.09).range(0.1, 0.45), 4, 0.3);
	sig = HPF.ar(sig, 28);
	sig = LPF.ar(sig, 2200 + (brightness * 2500));
	env = EnvGen.kr(Env.asr(10, 1, 10), gate: 1);
	sig = sig * env * amp;
	sig = Limiter.ar(sig, 0.8);
	sig = Pan2.ar(sig, LFNoise2.kr(0.08).range(-0.4, 0.4));
	SendReply.kr(Impulse.kr(30), '/audio/loudness', Amplitude.kr(sig));
	SendReply.kr(Impulse.kr(30), '/audio/high', Amplitude.kr(HPF.ar(sig, 3000)));
	Out.ar(0, sig);
}).add;

SynthDef(\jurisdiction_grid, {
	arg freq=62, amp=0.2, rate=0.5, brightness=0.5;
	var trig, sig, clicks, resonated, env;
	var stepRate, stepSeq;

	stepRate = LFNoise1.kr(0.1).range(rate * 0.3, rate * 3);
	trig = Impulse.kr(stepRate);
	clicks = Mix.fill(4, {
		var clickFreq = TExpRand.kr(800, 6000, trig);
		var clickDur = TRand.kr(0.0005, 0.008, trig);
		var clickSig = SinOsc.ar(clickFreq, 0, EnvGen.kr(Env.perc(0.0001, clickDur, 0.5), trig));
		BPF.ar(clickSig, clickFreq.clip(100, 8000), 0.02);
	});
	resonated = DynKlank.ar(
		`[
			[freq, freq*1.5, freq*2.3, freq*3.7],
			[0.2, 0.15, 0.1, 0.05],
			[1.2, 0.8, 0.5, 0.3]
		],
		clicks
	);
	sig = (clicks * 0.5) + (resonated * 0.4);
	sig = sig + CombL.ar(sig, 0.2, LFNoise2.kr(0.05).range(0.03, 0.18), LFNoise1.kr(0.03).range(0.5, 3));
	sig = HPF.ar(sig, 40);
	sig = LPF.ar(sig, 3500 + (brightness * 2000));
	env = EnvGen.kr(Env.asr(5, 1, 6), gate: 1);
	sig = sig * env * amp;
	sig = Limiter.ar(sig, 0.75);
	sig = Pan2.ar(sig, LFNoise2.kr(0.12).range(-0.7, 0.7));
	SendReply.kr(Impulse.kr(30), '/audio/bass', Amplitude.kr(LPF.ar(sig, 150)));
	Out.ar(0, sig);
}).add;

fork {
	var baseNotes = [29, 34, 36, 41, 43, 46];
	inf.do { |i|
		var note1 = baseNotes.choose;
		var note2 = baseNotes.choose;
		var note3 = baseNotes.choose;
		var dur = rrand(18, 35);
		var dens = rrand(1.5, 6.0);
		var bright = ~brightness ? rrand(0.2, 0.7);
		var mot = ~motion ? rrand(0.1, 0.6);

		if(~arb.notNil, { ~arb.free });
		if(~susp.notNil, { ~susp.free });
		if(~grid.notNil, { ~grid.free });

		0.1.wait;

		~arb = Synth(\arbitration_pulse, [
			\freq, note1.midicps,
			\density, dens,
			\amp, 0.28,
			\brightness, bright,
			\motion, mot
		]);

		rrand(0.5, 2.0).wait;

		~susp = Synth(\suspension_field, [
			\freq, note2.midicps,
			\amp, 0.22,
			\brightness, bright,
			\motion, mot
		]);

		rrand(1.0, 3.0).wait;

		~grid = Synth(\jurisdiction_grid, [
			\freq, note3.midicps,
			\amp, 0.18,
			\rate, rrand(0.3, 2.0),
			\brightness, bright
		]);

		dur.wait;
	};
};